#!/usr/bin/env python3
"""extract.py LESSON.md FILE [N]: print the Nth listing of FILE in a lesson.

A listing is a `schooling-example` whose "file" is FILE (its parts joined
exactly as the copy button joins them), or an ordinary fence whose first line
is a comment naming the file: `// FILE` for TypeScript and JavaScript,
`/* FILE */` for CSS, `<!-- FILE -->` for HTML, `# FILE` for the shell. JSON
has no comments, so a json fence is FILE's listing when the paragraph just
above it names FILE in backticks ("Save this as `public/courses.json`:").
It exists so a capture runs the very file the lesson prints, and the two
cannot drift."""
import json, re, sys

md, want = sys.argv[1], sys.argv[2]
n = int(sys.argv[3]) if len(sys.argv) > 3 else 1
text = open(md, encoding="utf-8").read()
text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
found = []
for m in re.finditer(r"^```([^\n]*)\n(.*?)^```[ \t]*$", text, flags=re.S | re.M):
    info, body = m.group(1).strip(), m.group(2)
    if info == "schooling-example":
        ex = json.loads(body)
        if ex.get("file") == want:
            found.append("\n".join(p["code"] for p in ex["parts"]) + "\n")
        continue
    if info == "json":
        before = text[: m.start()].rstrip("\n").split("\n\n")[-1]
        if "`" + want + "`" in before:
            found.append(body)
        continue
    first = body.split("\n", 1)[0].strip()
    if first in ("# " + want, "<!-- " + want + " -->", "// " + want, "/* " + want + " */"):
        found.append(body)
if len(found) < n:
    sys.exit(1)
sys.stdout.write(found[n - 1])
