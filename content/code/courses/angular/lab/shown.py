"""shown.py MD NAME [N]: print the file NAME exactly as the lesson MD shows it.

A file the student saves is shown whole, in one of two ways: a fence whose
first line is a comment naming it ("// NAME", "# NAME", "<!-- NAME -->" or
"/* NAME */", the name alone or followed by a colon), or a schooling-example whose "file" is NAME, whose
parts are joined with a newline, as the copy button joins them. The capture
runs exactly that text, so the lesson and the run cannot drift. A name shown
zero times, or twice, is an error, unless N picks the N-th of them: a
section that saves a broken version first and the repaired one after.
"""
import json, re, sys

md, name = sys.argv[1], sys.argv[2]
nth = int(sys.argv[3]) if len(sys.argv) > 3 else 0
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
    for c, end in (("//", ""), ("#", ""), ("<!--", " -->"), ("/*", " */")):
        if first in (f"{c} {name}{end}", f"{c} {name}") or first.startswith(f"{c} {name}:"):
            found.append(body)
if nth:
    if nth > len(found):
        sys.exit(f"shown: {name} is shown {len(found)} times in {md}, not {nth}")
    sys.stdout.write(found[nth - 1])
elif len(found) != 1:
    sys.exit(f"shown: {name} is shown {len(found)} times in {md}, and must be shown once")
else:
    sys.stdout.write(found[0])
