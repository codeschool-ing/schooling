#!/usr/bin/env python3
"""mdfile.py LESSON.md PATH -- print the file PATH exactly as the lesson shows it.

A whole file in a lesson is either a fenced block whose first line is a
comment naming it (`# events/views.py`, `{# templates/base.html #}`), or a
`schooling-example` whose "file" is it, in which case its parts are joined.
Exit 1 if the lesson does not show it, or shows it twice.
"""
import json, re, sys

md, path = sys.argv[1], sys.argv[2]
text = open(md, encoding="utf-8").read()
found = []
for m in re.finditer(r"^```([^\n]*)\n(.*?)^```$", text, re.S | re.M):
    info, body = m.group(1).strip(), m.group(2)
    if info == "schooling-example":
        ex = json.loads(body)
        if ex.get("file") == path:
            found.append("".join(p["code"] for p in ex["parts"]))
        continue
    first = body.split("\n", 1)[0].strip()
    names = re.findall(r"^(?:#|//|--|<!--|\{#)\s*(\S+)", first)
    if names and names[0] == path:
        found.append(body)
if len(found) != 1:
    sys.exit(1)
out = found[0]
sys.stdout.write(out if out.endswith("\n") else out + "\n")
