#!/usr/bin/env python3
"""inline.py LESSON_DIR SRC_DIR: replace every fence whose body is `@@listing NAME@@`
with the file SRC_DIR/NAME (or SRC_DIR/NAME.* when NAME has no extension), so a
listing is pasted from the very file the lab tested rather than retyped."""
import pathlib, re, sys
lesson, src = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
FENCE = re.compile(r"^```([^\n]*)\n@@listing (.+?)@@\n```", re.M)
bad = 0
for md in sorted(lesson.glob("*.md")):
    t = md.read_text()
    def sub(m):
        global bad
        name = m.group(2)
        f = src / name
        if not f.exists():
            c = [p for p in src.glob(name + ".*")]
            f = c[0] if len(c) == 1 else None
        if not f:
            print(f"{md.name}: no file for {name}"); bad += 1; return m.group(0)
        body = f.read_text()
        return "```" + m.group(1) + "\n" + body + ("" if body.endswith("\n") else "\n") + "```"
    n = FENCE.sub(sub, t)
    if n != t:
        md.write_text(n)
sys.exit(1 if bad else 0)
