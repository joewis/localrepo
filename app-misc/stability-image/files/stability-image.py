#!/usr/bin/env python3
"""stability-image — text-to-image via Stability AI (api.stability.ai).

Usage:
  stability-image "prompt" [--model core|ultra] [--size 1024x1024] [--out FILE] [--seed N] [--steps N]

STABILITY_API_KEY is read from the environment (the MCP gateway injects it for
the stability-image backend), with the shared ~/.hermes/.env as a fallback for
interactive use. Saves PNG locally.
"""
import os, pathlib, sys, argparse, json, uuid, urllib.request, urllib.error

sys.path.insert(0, "/opt/mcp/servers")
from secret_source import secret  # noqa: E402

API = "https://api.stability.ai/v2beta/stable-image/generate"

def get_key():
    """STABILITY_API_KEY: env first (gateway-injected), dotenv fallback."""
    return secret("STABILITY_API_KEY")
def main():
    ap = argparse.ArgumentParser(description="Generate an image with Stability AI")
    ap.add_argument("prompt", help="text prompt")
    ap.add_argument("--model", default="core", choices=["core", "ultra"],
                    help="model (core=fast/cheap, ultra=highest quality)")
    ap.add_argument("--size", default="1024x1024", help="WxH, e.g. 1024x1024, 1536x640")
    ap.add_argument("--out", default=None, help="output PNG path (default: ./stability_<ts>.png)")
    ap.add_argument("--seed", type=int, default=None, help="deterministic seed")
    ap.add_argument("--steps", type=int, default=None, help="inference steps")
    args = ap.parse_args()

    key = get_key()
    if not key:
        sys.exit("STABILITY_API_KEY not found in the environment or ~/.hermes/.env")

    try:
        w, h = (int(x) for x in args.size.lower().split("x"))
    except Exception:
        sys.exit(f"bad --size {args.size!r}; use WxH e.g. 1024x1024")

    boundary = "----HermesBoundary" + uuid.uuid4().hex
    def field(name, value):
        return (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n"
                f"{value}\r\n").encode()
    body = field("prompt", args.prompt) + field("output_format", "png")
    body += field("width", str(w)) + field("height", str(h))
    if args.seed is not None:
        body += field("seed", str(args.seed))
    if args.steps is not None:
        body += field("steps", str(args.steps))
    body += f"--{boundary}--\r\n".encode()

    url = f"{API}/{args.model}"
    req = urllib.request.Request(url, method="POST", data=body)
    req.add_header("Authorization", f"Bearer {key}")
    req.add_header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0")
    req.add_header("Accept", "application/json")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            data = json.loads(r.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()[:300]}")
    except Exception as e:
        sys.exit(f"error: {type(e).__name__}: {e}")

    b64 = data.get("image", "")
    if not b64:
        sys.exit("no image in response")
    import base64
    raw = base64.b64decode(b64)

    # Default output goes to the service account's own directory. Writing to the
    # current working directory is wrong for a supervised tool: cwd is the
    # gateway's WorkingDirectory, which the service account does not own.
    if args.out:
        out = pathlib.Path(args.out)
    else:
        out = pathlib.Path("/var/lib/mcp-gateway/output") / (
            f"stability_{args.model}_{int(__import__('time').time())}.png"
        )
    try:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(raw)
    except OSError as e:
        sys.exit(f"cannot write {out}: {e}")
    print(f"OK {out} ({len(raw)} bytes) model={args.model} size={args.size}")

if __name__ == "__main__":
    main()
