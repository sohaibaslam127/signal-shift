#!/usr/bin/env python3
"""Development-time asset generation via Pollinations (https://gen.pollinations.ai/).

Standard library only. Never runs during gameplay and the game works without its output.

  generate_assets.py                    generate every missing/failed asset into staging/
  generate_assets.py --only ID [...]    only these asset ids (regenerates even if present)
  generate_assets.py --dry-run          print the requests without calling the API
  generate_assets.py --approve ID|all   copy reviewed staging files into assets/packs/...

Auth: POLLINATIONS_API_KEY from the environment or a gitignored .env.local at the repo root.
The key is sent only as an Authorization header; it is never written to disk or the manifest.
Endpoint (documented at https://gen.pollinations.ai/docs/llm.txt): GET /image/{prompt}?model=...
"""
import argparse, datetime, json, os, shutil, struct, sys, urllib.error, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SPEC = os.path.join(HERE, "assets_spec.json")
MANIFEST = os.path.join(HERE, "manifest.json")
STAGING = os.path.join(HERE, "staging")
BASE_URL = "https://gen.pollinations.ai/image/"


def load_key():
    key = os.environ.get("POLLINATIONS_API_KEY", "")
    env_file = os.path.join(ROOT, ".env.local")
    if not key and os.path.exists(env_file):
        for line in open(env_file):
            name, _, value = line.strip().partition("=")
            if name == "POLLINATIONS_API_KEY":
                key = value.strip().strip('"').strip("'")
    return key


def image_info(data):
    """Returns (extension, width, height) for PNG/JPEG bytes, or None if it is neither."""
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        width, height = struct.unpack(">II", data[16:24])
        return "png", width, height
    if data[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(data):
            if data[i] != 0xFF:
                i += 1
                continue
            marker = data[i + 1]
            if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
                height, width = struct.unpack(">HH", data[i + 5:i + 9])
                return "jpg", width, height
            i += 2 + struct.unpack(">H", data[i + 2:i + 4])[0]
    return None


def load_manifest():
    if os.path.exists(MANIFEST):
        return json.load(open(MANIFEST))
    return {"assets": {}}


def save_manifest(manifest):
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
        f.write("\n")


def final_path(asset, extension):
    name = os.path.splitext(asset["file"])[0] + "." + extension
    return os.path.join(ROOT, "assets", "packs", asset["pack"], asset["kind"], name)


def generate(asset, spec, key, dry_run):
    prompt = "%s, %s" % (asset["prompt"], spec["style_suffix"])
    query = {"model": spec["model"], "width": asset["width"], "height": asset["height"], "seed": 7}
    url = BASE_URL + urllib.parse.quote(prompt, safe="") + "?" + urllib.parse.urlencode(query)
    if dry_run:
        print("  DRY %s -> GET %s" % (asset["id"], url.split("?")[0][:60] + "...?" + urllib.parse.urlencode(query)))
        return None
    request = urllib.request.Request(url, headers={"User-Agent": "signal-shift-asset-pipeline"})
    if key:
        request.add_header("Authorization", "Bearer " + key)
    with urllib.request.urlopen(request, timeout=180) as response:
        return response.read()


def run_generate(args):
    spec = json.load(open(SPEC))
    manifest = load_manifest()
    key = load_key()
    if not key and not args.dry_run:
        print("note: POLLINATIONS_API_KEY not set; trying keyless access (may be rate limited).")
    failures = 0
    for asset in spec["assets"]:
        if args.only and asset["id"] not in args.only:
            continue
        entry = manifest["assets"].get(asset["id"], {})
        staged = entry.get("staging_path")
        if not args.only and entry.get("status") in ("generated", "approved") and staged and os.path.exists(os.path.join(ROOT, staged)):
            print("  skip %s (%s)" % (asset["id"], entry["status"]))
            continue
        try:
            data = generate(asset, spec, key, args.dry_run)
            if data is None:
                continue
            info = image_info(data)
            if info is None:
                raise ValueError("response is not a PNG or JPEG (%d bytes)" % len(data))
            extension, width, height = info
            if width < asset["width"] // 2 or height < asset["height"] // 2:
                raise ValueError("image is %dx%d, expected about %dx%d" % (width, height, asset["width"], asset["height"]))
            os.makedirs(STAGING, exist_ok=True)
            path = os.path.join(STAGING, "%s.%s" % (asset["id"], extension))
            with open(path, "wb") as f:
                f.write(data)
            manifest["assets"][asset["id"]] = {
                "pack": asset["pack"], "kind": asset["kind"], "prompt": asset["prompt"], "model": spec["model"],
                "requested_size": [asset["width"], asset["height"]], "actual_size": [width, height],
                "staging_path": os.path.relpath(path, ROOT), "status": "generated",
                "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
            }
            print("  ok   %s (%dx%d)" % (asset["id"], width, height))
        except (urllib.error.URLError, ValueError, OSError) as error:
            failures += 1
            manifest["assets"][asset["id"]] = {**entry, "pack": asset["pack"], "status": "failed", "error": str(error)}
            print("  FAIL %s: %s" % (asset["id"], error))
        save_manifest(manifest)
    return 1 if failures else 0


def run_approve(ids):
    spec = {a["id"]: a for a in json.load(open(SPEC))["assets"]}
    manifest = load_manifest()
    for asset_id, entry in manifest["assets"].items():
        if ids != ["all"] and asset_id not in ids:
            continue
        if entry.get("status") != "generated":
            continue
        source = os.path.join(ROOT, entry["staging_path"])
        destination = final_path(spec[asset_id], source.rsplit(".", 1)[1])
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        shutil.copyfile(source, destination)
        entry["status"] = "approved"
        entry["path"] = os.path.relpath(destination, ROOT)
        print("  approved %s -> %s" % (asset_id, entry["path"]))
    save_manifest(manifest)
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--only", nargs="+")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--approve", nargs="+", metavar="ID|all")
    arguments = parser.parse_args()
    sys.exit(run_approve(arguments.approve) if arguments.approve else run_generate(arguments))
