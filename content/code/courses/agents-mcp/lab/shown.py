"""shown.py FILE: fail unless FILE's bytes are shown whole in this course's lessons.

A capture runs files that the lessons show the student. This is what keeps the
two the same file: every `put` in a captures.sh, and every file lab.sh
installs, is checked against the lessons' fences before it is run, and a
difference stops the capture. It looks for a plain fence whose body is the
file, or a schooling-example whose parts join to it, or a run of such
fences, one after another, that make up the file between blank lines.
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


want = Path(sys.argv[1]).read_text().rstrip("\n")
pieces = [body.rstrip("\n") for md, name, body in bodies()]
if want in pieces:
    sys.exit(0)
# A long program may be shown in parts, section after section: then it must be
# those parts in order, with nothing between them but blank lines.
pos = 0
while pos < len(want):
    while want.startswith("\n", pos):
        pos += 1
    best = max((p for p in pieces if p and want.startswith(p, pos)), key=len, default=None)
    if best is None:
        line = want[pos:].split("\n", 1)[0]
        sys.exit(f"shown.py: {sys.argv[1]} is not shown whole in this course; no lesson shows the part from {line!r}")
    pos += len(best)
sys.exit(0)
