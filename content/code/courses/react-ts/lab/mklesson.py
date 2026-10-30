"""mklesson.py LESSON_DIR VIDEO_ID SECONDS SCRIPT_FILE slug=se-id ...

Writes lesson.json: the title is the course's topic, the first section is the
video whose script is SCRIPT_FILE, the last is the practice, and every other
one is a reading. Also adds the lesson to course.json's `lessons`, in the order
of `topics`.
"""
import json
import sys
from pathlib import Path

lesson = Path(sys.argv[1]).resolve()
vd, secs, script = sys.argv[2], int(sys.argv[3]), Path(sys.argv[4]).read_text().strip()
pairs = [a.split("=") for a in sys.argv[5:]]
course = lesson.parent.parent / "course.json"
c = json.loads(course.read_text())
title = [t["title"] for t in c["topics"] if t["id"] == lesson.name][0]
out = []
for i, (slug, sid) in enumerate(pairs):
    kind = "video" if i == 0 else "practice" if i == len(pairs) - 1 else "reading"
    s = {"id": sid, "slug": slug, "kind": kind}
    if kind == "video":
        s["videos"] = [{"id": vd, "version": 1, "script": script, "seconds": secs, "locales": []}]
    out.append(s)
(lesson / "lesson.json").write_text(json.dumps({"id": lesson.name, "title": title, "sections": out},
                                               indent=2, ensure_ascii=False) + "\n")
order = [t["id"] for t in c["topics"]]
have = set(c["lessons"]) | {lesson.name}
c["lessons"] = [i for i in order if i in have]
course.write_text(json.dumps(c, indent=2, ensure_ascii=False) + "\n")
