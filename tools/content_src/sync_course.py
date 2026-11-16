import json, glob, pathlib
p = pathlib.Path("/home/claude/studnia-wiedzy/assets/content/en/course.json")
c = json.loads(p.read_text())
for u in c["units"]:
    fs = sorted(pathlib.Path(p.parent, "lessons").glob(u["id"] + "_l*.json"))
    if fs: u["lessons"] = [f.stem for f in fs]
p.write_text(json.dumps(c, ensure_ascii=False, indent=1) + "\n")
