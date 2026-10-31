#!/usr/bin/env python3
"""mklesson.py LESSON_ID TITLE SLUG:KIND ... : write lessons/LESSON_ID/lesson.json with
fresh section ids, keeping the ids of slugs already there. The intro's script
is read from lab/scripts/LESSON_ID.txt (one paragraph, {{marks}} kept)."""
import json, pathlib, subprocess, sys
here = pathlib.Path(__file__).parent
lid, title, specs = sys.argv[1], sys.argv[2], sys.argv[3:]
d = here.parent / "lessons" / lid
d.mkdir(parents=True, exist_ok=True)
p = d / "lesson.json"
old = {s["slug"]: s for s in json.loads(p.read_text())["sections"]} if p.exists() else {}
def new(prefix):
    return subprocess.run([sys.executable, str(here / "ids.py"), prefix, "1"], capture_output=True, text=True).stdout.strip()
secs = []
for spec in specs:
    slug, kind = spec.split(":")
    s = {"id": old[slug]["id"] if slug in old else new("se"), "slug": slug, "kind": kind}
    if kind == "video":
        script = (here / "scripts" / (lid + ".txt")).read_text().strip()
        words = len(script.split())
        vid = old.get(slug, {}).get("videos", [{}])[0].get("id") or new("vd")
        s["videos"] = [{"id": vid, "version": 1, "script": script, "seconds": round(words / 2.5 / 5) * 5, "locales": []}]
    secs.append(s)
p.write_text(json.dumps({"id": lid, "title": title, "sections": secs}, indent=2, ensure_ascii=False) + "\n")
print(p)
