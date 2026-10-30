"""new.py LESSON SLUG[:KIND] ...: start a lesson's lesson.json, with new ids.

Every section gets an se- id, a video section a vd- id, and the ids are drawn
by ids.py so none is already in the repository. A lesson.json that exists is
refused rather than replaced: its ids are written down and may not move.
The kind is reading unless it says otherwise; `intro` is a video and `drill`
is practice whatever is written.
"""
import json, os, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
lesson, specs = sys.argv[1], sys.argv[2:]
d = os.path.join(here, "..", "lessons", lesson)
path = os.path.join(d, "lesson.json")
if os.path.exists(path):
    sys.exit(f"{path} exists; its ids are written down")
ids = subprocess.run([sys.executable, os.path.join(here, "ids.py"), "se", str(len(specs))],
                     capture_output=True, text=True, check=True).stdout.split()
vid = subprocess.run([sys.executable, os.path.join(here, "ids.py"), "vd", "1"],
                     capture_output=True, text=True, check=True).stdout.split()[0]
course = json.load(open(os.path.join(here, "..", "course.json")))
title = next(t["title"] for t in course["topics"] if t["id"] == lesson)
sections = []
for sid, spec in zip(ids, specs):
    slug, _, kind = spec.partition(":")
    kind = "video" if slug == "intro" else "practice" if slug == "drill" else (kind or "reading")
    s = {"id": sid, "slug": slug, "kind": kind}
    if kind == "video":
        s["videos"] = [{"id": vid, "version": 1, "script": "", "seconds": 0, "locales": []}]
    sections.append(s)
os.makedirs(d, exist_ok=True)
json.dump({"id": lesson, "title": title, "sections": sections}, open(path, "w"), indent=2, ensure_ascii=False)
open(path, "a").write("\n")
print(path)
