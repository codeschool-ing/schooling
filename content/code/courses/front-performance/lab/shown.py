"""shown.py MD NAME: print the file NAME exactly as the lesson MD shows it.

A program the student is given is shown whole, in one of two ways: a fence
whose first line is a comment naming it ("// NAME", "# NAME" or
"<!-- NAME", alone or followed by a colon), or a schooling-example whose "file" is NAME, whose
parts are joined with a newline, as the copy button joins them. The capture
runs exactly that text, so the lesson and the run cannot drift. A file that cannot
carry a comment in that form (JSON, a stylesheet, or an HTML page whose
first line must stay the doctype) is named instead by the line of prose just above its fence, which
ends with the name in backticks and a colon: "... `public/courses.json`:".
A name shown zero times, or twice, is an error.
"""
import json, re, sys

md, name = sys.argv[1], sys.argv[2]
text = open(md, encoding="utf-8").read()
found = []
for m in re.finditer(r"^```([a-z-]*)\n(.*?)^```$", text, re.S | re.M):
    label, body = m.group(1), m.group(2)
    before = [l for l in text[:m.start()].split("\n") if l.strip()]
    if label in ("json", "html", "css") and before and before[-1].rstrip().endswith(f"`{name}`:"):
        found.append(body)
        continue
    if label == "schooling-example":
        ex = json.loads(body)
        if ex.get("file") == name:
            found.append("\n".join(p["code"] for p in ex["parts"]).rstrip("\n") + "\n")
        continue
    first = body.split("\n", 1)[0]
    for c in ("//", "#", "<!--"):
        if first in (f"{c} {name}", f"{c} {name} -->") or first.startswith(f"{c} {name}:"):
            found.append(body)
if len(found) != 1:
    sys.exit(f"shown: {name} is shown {len(found)} times in {md}, and must be shown once")
sys.stdout.write(found[0])
