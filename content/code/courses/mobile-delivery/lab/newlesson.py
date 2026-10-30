#!/usr/bin/env python3
"""newlesson.py lab/lessons/lNN.py: write the lesson's lesson.json from its spec.

The spec names LESSON (the topic id) and SECTIONS, a list of
  ("slug", "reading") | ("slug", "practice") | ("slug", "video", seconds, script)
Ids already written for a slug are kept, so the spec can be rerun; new ones
come from ids.py, which checks them against the whole repository. The lesson
is then put into course.json's `lessons`, in topic order."""
import importlib.util, json, pathlib, subprocess, sys
here = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location("s", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
d = here.parent / "lessons" / m.LESSON; d.mkdir(parents=True, exist_ok=True)
p = d / "lesson.json"
old = json.loads(p.read_text()) if p.exists() else {"sections": []}
bys = {s["slug"]: s for s in old["sections"]}
def fresh(prefix):
    return subprocess.check_output([sys.executable, str(here / "ids.py"), prefix, "1"], text=True).strip()
out = []
for s in m.SECTIONS:
    slug, kind = s[0], s[1]
    prev = bys.get(slug, {})
    e = {"id": prev.get("id") or fresh("se"), "slug": slug, "kind": kind}
    if kind == "video":
        v = (prev.get("videos") or [{}])[0]
        e["videos"] = [{"id": v.get("id") or fresh("vd"), "version": 1, "script": s[3].strip(), "seconds": s[2], "locales": []}]
    out.append(e)
p.write_text(json.dumps({"id": m.LESSON, "title": m.TITLE, "sections": out}, indent=2, ensure_ascii=False) + "\n")
subprocess.check_call([sys.executable, str(here / "add-lesson.py"), m.LESSON])
