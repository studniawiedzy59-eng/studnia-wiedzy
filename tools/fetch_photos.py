#!/usr/bin/env python3
"""Downloads the topic photos listed in tools/photos.json from Unsplash into
assets/images/photo_<name>.jpg (800 px wide, about 80-150 KB each).

Photos are not stored in git: the build downloads them. The app falls back to
the drawn pictures when a photo file is missing, so a local build works too.
Exit code 1 if any download fails, so a broken CI build is never silent."""
import json
import pathlib
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images"
URL = "https://images.unsplash.com/{p}?ixlib=rb-4.1.0&q=80&fm=jpg&w=800&fit=max"


def main() -> int:
    items = json.loads((ROOT / "tools" / "photos.json").read_text(encoding="utf-8"))
    failed = []
    for it in items:
        target = OUT / f"photo_{it['name']}.jpg"
        try:
            req = urllib.request.Request(URL.format(p=it["photo"]), headers={"User-Agent": "movira-build"})
            data = urllib.request.urlopen(req, timeout=60).read()
            if len(data) < 10_000 or data[:2] != b"\xff\xd8":
                raise ValueError("not a JPEG or too small")
            target.write_bytes(data)
            print(f"ok   {target.name} {len(data) // 1024} KB")
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {it['name']}: {e}")
            failed.append(it["name"])
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
