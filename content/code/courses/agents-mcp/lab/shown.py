"""shown.py FILE: fail unless FILE's bytes are shown whole somewhere in this course's lessons.

A capture runs files that the lessons show the student. This is what keeps the
two the same file: every `put` in a captures.sh, and every file lab.sh
installs, is checked against the lessons' fences before it is run, and a
difference stops the capture. It looks for a plain fence whose body is the
file, or a schooling-example whose parts join to it.
"""
import json
import re
import sys
from pathlib import Path

LESSONS = Path(__file__).resolve().parent.parent / "lessons"
FENCE = re.compile(r"^(`{3,})([^\n`]*)\n(.*?)\n\1[ \t]*$", re.S | re.M)


def bodies():
    for md in sorted(LESSONS.glob("*/*.md")):
        if md.name.endswith(".pt.md"):
            continue
        for m in FENCE.finditer(md.read_text()):
            info, body = m.group(2).strip(), m.group(3)
            if info == "schooling-example":
                ex = json.loads(body)
                yield md, ex.get("file"), "".join(p["code"] for p in ex["parts"])
            else:
                yield md, None, body


want = Path(sys.argv[1]).read_text()
for md, name, body in bodies():
    if body.rstrip("\n") == want.rstrip("\n"):
        sys.exit(0)
sys.exit(f"shown.py: {sys.argv[1]} is not shown whole in any lesson of this course")
