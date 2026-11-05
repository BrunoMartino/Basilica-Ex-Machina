#!/usr/bin/env python3
# amaterasu-sugoi · video generation via OpenRouter (POST /videos, poll, download MP4).
"""
  or_video.py --list
  or_video.py --prompt "..." --first-frame key-first.png --last-frame key-last.png --duration 8 --seed 7 --out source/hero.mp4
"""
import argparse
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from or_common import cost, data_url, request  # noqa: E402

DEFAULT = "google/veo-3.1"


def models():
    return request("GET", "/videos/models", auth=False).get("data", [])


def list_models():
    for m in models():
        print(f"{m.get('id'):<40} dur={m.get('supported_durations')} res={m.get('supported_resolutions')} "
              f"aspect={m.get('supported_aspect_ratios')}")
        if m.get("pricing"):
            print(f"{'':<40} price={m['pricing']}")


def validate(model, duration, resolution, aspect):
    info = next((m for m in models() if m.get("id") == model), None)
    if not info:
        sys.exit(f"{model} is not in the OpenRouter video list. Run --list.")
    bad = []
    for key, val, label in (("supported_durations", duration, "duration"),
                            ("supported_resolutions", resolution, "resolution"),
                            ("supported_aspect_ratios", aspect, "aspect")):
        if info.get(key) and val not in info[key]:
            bad.append(f"{label} {val} (accepts {info[key]})")
    if bad:
        sys.exit(f"{model} rejects: " + "; ".join(bad))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--prompt")
    ap.add_argument("--model", default=DEFAULT)
    ap.add_argument("--duration", type=int, default=8)
    ap.add_argument("--resolution", default="1080p")
    ap.add_argument("--aspect", default="16:9")
    ap.add_argument("--first-frame", help="image used as first frame (image-to-video)")
    ap.add_argument("--last-frame", help="image used as last frame")
    ap.add_argument("--reference", action="append", default=[], help="style reference (used only without frames)")
    ap.add_argument("--audio", action="store_true", help="default is silent")
    ap.add_argument("--seed", type=int)
    ap.add_argument("--out", default="hero.mp4")
    ap.add_argument("--poll", type=int, default=15, help="seconds between status checks")
    ap.add_argument("--timeout", type=int, default=1200)
    a = ap.parse_args()

    if a.list:
        return list_models()
    if not a.prompt:
        ap.error("--prompt is required")
    validate(a.model, a.duration, a.resolution, a.aspect)

    body = {"model": a.model, "prompt": a.prompt, "duration": a.duration, "resolution": a.resolution,
            "aspect_ratio": a.aspect, "generate_audio": bool(a.audio)}
    if a.seed is not None:
        body["seed"] = a.seed
    frames = []
    if a.first_frame:
        frames.append({"type": "image_url", "image_url": {"url": data_url(a.first_frame)}, "frame_type": "first_frame"})
    if a.last_frame:
        frames.append({"type": "image_url", "image_url": {"url": data_url(a.last_frame)}, "frame_type": "last_frame"})
    if frames:
        body["frame_images"] = frames
    elif a.reference:
        body["input_references"] = [{"type": "image_url", "image_url": {"url": data_url(r)}} for r in a.reference]

    job = request("POST", "/videos", body)
    jid = job.get("id")
    status_url = job.get("polling_url") or f"/videos/{jid}"
    print(f"Job {jid} ({a.model}) submitted. Waiting…", flush=True)

    t0 = time.time()
    while True:
        st = request("GET", status_url)
        state = st.get("status")
        if state == "completed":
            break
        if state == "failed":
            sys.exit(f"Generation failed: {st.get('error')}")
        if time.time() - t0 > a.timeout:
            sys.exit(f"Timed out. Check later: GET /api/v1/videos/{jid}")
        print(f"  {state}… {int(time.time() - t0)}s", flush=True)
        time.sleep(a.poll)

    urls = st.get("unsigned_urls") or [f"/videos/{jid}/content?index=0"]
    video = request("GET", urls[0], raw=True, timeout=600)
    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(video)
    print(f"OK: {out} ({len(video) / 1e6:.1f} MB) {cost(st.get('usage'))}")


if __name__ == "__main__":
    main()
