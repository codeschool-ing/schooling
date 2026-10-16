#!/usr/bin/env python3
"""extract.py LESSON.md FILE [N]: the Nth (from 1) schooling-example whose `file` is FILE,
joined the way the page's copy button joins it, with a final newline. A file in a language
the highlighter does not know (Markdown) is a bare fence instead: the first one after the
line that names it as `FILE`:"""
import json, re, sys
md, name = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
n = int(sys.argv[3]) if len(sys.argv) > 3 else 1
for body in re.findall(r"^```schooling-example\n(.*?)\n```$", md, re.S | re.M):
    ex = json.loads(body)
    if ex.get("file") == name:
        n -= 1
        if n == 0:
            sys.stdout.write("\n".join(p["code"] for p in ex["parts"]) + "\n")
            sys.exit(0)
for m in re.finditer(r"^`" + re.escape(name) + r"`[^\n]*\n(?:(?!```)[^\n]*\n)*?```\n(.*?)\n```$", md, re.S | re.M):
    n -= 1
    if n == 0:
        sys.stdout.write(m.group(1) + "\n")
        sys.exit(0)
sys.exit(f"{sys.argv[1]}: no schooling-example number {sys.argv[3] if len(sys.argv) > 3 else 1} for {name}")
