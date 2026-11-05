# amaterasu-sugoi · shared OpenRouter client (Python stdlib only).
import base64
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://openrouter.ai/api/v1"


def api_key():
    k = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if k:
        return k
    env = Path.cwd() / ".env"  # read-only; never written
    if env.exists():
        for line in env.read_text().splitlines():
            if line.startswith("OPENROUTER_API_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    f = Path.home() / ".config" / "sugoi" / "openrouter.key"
    if f.exists():
        return f.read_text().strip()
    sys.exit("OpenRouter key not found. Set OPENROUTER_API_KEY, add it to the project .env, "
             "or save it to ~/.config/sugoi/openrouter.key (chmod 600).")


def _headers(auth=True):
    h = {"Content-Type": "application/json", "X-Title": "amaterasu-sugoi"}
    if auth:
        h["Authorization"] = f"Bearer {api_key()}"
    return h


def request(method, url, body=None, auth=True, raw=False, timeout=180):
    if not url.startswith("http"):
        url = API + url
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=_headers(auth))
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            content = r.read()
    except urllib.error.HTTPError as e:
        sys.exit(f"OpenRouter {e.code} at {url}:\n{e.read().decode(errors='replace')[:800]}")
    except urllib.error.URLError as e:
        sys.exit(f"Network error calling {url}: {e.reason}")
    return content if raw else json.loads(content)


def data_url(path):
    p = Path(path)
    if not p.exists():
        sys.exit(f"File not found: {p}")
    mime = mimetypes.guess_type(p.name)[0] or "image/png"
    return f"data:{mime};base64," + base64.b64encode(p.read_bytes()).decode()


def cost(usage):
    c = (usage or {}).get("cost")
    return f"cost: US$ {c:.4f}" if isinstance(c, (int, float)) else ""
