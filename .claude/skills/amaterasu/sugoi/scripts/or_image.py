#!/usr/bin/env python3
# amaterasu-sugoi · image generation via OpenRouter (POST /images).
"""
  or_image.py --list
  or_image.py --prompt "..." --aspect 16:9 --resolution 2K [--reference key-first.png] [--seed 7] --out source/about.png
"""
import argparse
import base64
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from or_common import cost, data_url, request  # noqa: E402

DEFAULT = "google/gemini-3-pro-image"


def list_models():
    for m in request("GET", "/images/models", auth=False).get("data", []):
        print(m.get("id"), f"price={m['pricing']}" if m.get("pricing") else "")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--prompt")
    ap.add_argument("--model", default=DEFAULT)
    ap.add_argument("--aspect", default="16:9")
    ap.add_argument("--resolution", default="2K")
    ap.add_argument("--reference", action="append", default=[], help="style reference image (repeatable)")
    ap.add_argument("--seed", type=int)
    ap.add_argument("--out", default="image.png")
    a = ap.parse_args()

    if a.list:
        return list_models()
    if not a.prompt:
        ap.error("--prompt is required")

    body = {"model": a.model, "prompt": a.prompt, "aspect_ratio": a.aspect, "resolution": a.resolution}
    if a.seed is not None:
        body["seed"] = a.seed
    if a.reference:
        body["input_references"] = [{"type": "image_url", "image_url": {"url": data_url(r)}} for r in a.reference]

    r = request("POST", "/images", body, timeout=300)
    items = r.get("data") or []
    if not items or not items[0].get("b64_json"):
        sys.exit(f"No image in response: {str(r)[:500]}")

    out = Path(a.out)
    ext = {"image/jpeg": ".jpg", "image/webp": ".webp"}.get(items[0].get("media_type", "image/png"), ".png")
    if out.suffix.lower() != ext:
        out = out.with_suffix(ext)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(base64.b64decode(items[0]["b64_json"]))
    print(f"OK: {out} {cost(r.get('usage'))}")


if __name__ == "__main__":
    main()
