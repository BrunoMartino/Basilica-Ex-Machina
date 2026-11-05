#!/usr/bin/env python3
# amaterasu-sugoi · pre-delivery check of the staging site folder. Exit 1 on errors.
"""Usage: verify.py <site-dir>"""
import json
import re
import sys
from pathlib import Path

site = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
errors, warns = [], []

html_p, cfg_p, css_p = site / "index.html", site / "config.js", site / "styles.css"
for p in (html_p, cfg_p, css_p):
    if not p.exists():
        sys.exit(f"ERROR: {p.name} missing in {site}")
html_raw, cfg, css = html_p.read_text(), cfg_p.read_text(), css_p.read_text()
html = re.sub(r"<!--.*?-->", "", html_raw, flags=re.S)

# 1. Placeholders
for name, text in (("index.html", html), ("config.js", cfg), ("styles.css", css)):
    left = sorted(set(re.findall(r"\{\{[A-Z0-9_]+\}\}", text)))
    if left:
        errors.append(f"{name}: unfilled placeholders: {', '.join(left)}")


# 2. Config values
def cfg_str(key):
    m = re.search(rf'\b{key}:\s*"([^"]*)"', cfg)
    return m.group(1) if m else ""


num = re.sub(r"\D", "", cfg_str("number"))
if num and not 11 <= len(num) <= 15:
    errors.append(f"config.js: whatsapp.number '{num}' must be country code + number digits")
if not num:
    warns.append("whatsapp.number empty → floating button removed")

email, endpoint, w3 = cfg_str("email"), cfg_str("endpoint"), cfg_str("web3formsKey")
has_action = bool(re.search(r'<form\b[^>]*\baction=', html))
if email and not re.match(r"^[^\s@]+@[^\s@]+\.[^\s@]+$", email):
    errors.append("config.js: contact.email invalid")
if not (email or endpoint or w3 or has_action):
    warns.append("no contact target (endpoint/web3formsKey/email/form action) → form hidden")

# 3. Frames
totals = [int(t) for t in re.findall(r"total:\s*(\d+)", cfg)]
total = totals[0] if totals else 0
frames_root = site / "assets" / "frames"
if len(totals) <= 1:
    for kind in ("desktop", "mobile"):
        d = frames_root / kind
        n = len(list(d.glob("f_*.*"))) if d.exists() else 0
        if n == 0:
            errors.append(f"frames/{kind}: no frames")
        elif n != total:
            errors.append(f"frames/{kind}: {n} files but config.js total={total}")
    man = frames_root / "frames.json"
    if man.exists() and json.loads(man.read_text()).get("total") != total:
        warns.append("frames.json and config.js disagree on total")
else:
    warns.append(f"{len(totals)} scenes configured; frame counts not cross-checked")

# 4. Images: exist, fused via .art, no bare content <img>
for m in re.finditer(r"<img\b[^>]*>", html):
    tag = m.group(0)
    src = re.search(r'src="([^"]+)"', tag)
    if not src:
        continue
    path = src.group(1)
    if not path.startswith(("http", "/")) and not (site / path).exists():
        errors.append(f"missing image: {path}")
    if "/img/" in path and 'class="art' not in tag:
        errors.append(f"{path}: section image without class 'art' (will render as a rectangle)")

for path in sorted(set(re.findall(r'(?:href|content)="(assets/[^"]+)"', html))):
    if not (site / path).exists():
        errors.append(f"referenced file missing: {path}")

# 5. Structure
if len(re.findall(r"<h1\b", html)) != 1:
    errors.append("exactly one <h1> required")
if "prefers-reduced-motion" not in css:
    errors.append("styles.css: no prefers-reduced-motion block")
if 'class="sugoi"' not in html and "class=\"sugoi " not in html:
    warns.append("<body> lacks class 'sugoi' (styles are scoped to body.sugoi)")

# 6. Weight
total_mb = sum(f.stat().st_size for f in site.rglob("*") if f.is_file()) / 1e6
mob_dir = frames_root / "mobile"
mob_mb = sum(f.stat().st_size for f in mob_dir.glob("*")) / 1e6 if mob_dir.exists() else 0
if mob_mb > 12:
    warns.append(f"mobile frames {mob_mb:.1f} MB (target < 12 MB): fewer frames or lower quality")

for w in warns:
    print(f"WARN:  {w}")
for e in errors:
    print(f"ERROR: {e}")
print(f"\nTotal {total_mb:.1f} MB · mobile frames {mob_mb:.1f} MB")
if errors:
    sys.exit(1)
print("Ready to hand off.")
