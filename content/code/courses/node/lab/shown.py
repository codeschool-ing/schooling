"""shown.py MD NAME: print the file NAME exactly as the lesson MD shows it.

A program the student is given is shown whole, in one of two ways: a fence
whose first line is a comment naming it ("// NAME" or "# NAME", alone or
followed by a colon), or a schooling-example whose "file" is NAME, whose
parts are joined with a newline, as the copy button joins them. The capture
runs exactly that text, so the lesson and the run cannot drift. A name shown
zero times, or twice, is an error.
"""
import json, re, sys

md, name = sys.argv[1], sys.argv[2]
text = open(md, encoding="utf-8").read()
found = []
for m in re.finditer(r"^```([a-z-]*)\n(.*?)^```$", text, re.S | re.M):
    label, body = m.group(1), m.group(2)
    if label == "schooling-example":
        ex = json.loads(body)
        if ex.get("file") == name:
            found.append("\n".join(p["code"] for p in ex["parts"]).rstrip("\n") + "\n")
        continue
    first = body.split("\n", 1)[0]
    for c in ("//", "#"):
        if first == f"{c} {name}" or first.startswith(f"{c} {name}:"):
            found.append(body)
if len(found) != 1:
    sys.exit(f"shown: {name} is shown {len(found)} times in {md}, and must be shown once")
sys.stdout.write(found[0])
