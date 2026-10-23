#!/usr/bin/env python3
"""extract.py LESSON.md FILE [N]: print the Nth listing of FILE in a lesson.

A listing is one of three things:
  - a `schooling-example` whose "file" is FILE (its parts joined, exactly as
    the copy button joins them);
  - an ordinary fence whose first line is a comment naming the file:
    `// FILE` or `// FILE: what it is` for TypeScript and JavaScript,
    `# FILE` for the shell, `<!-- FILE -->` for HTML;
  - for a format with no comments (JSON), the fence right after a paragraph
    whose last line ends with `FILE`: or `FILE`, then a colon.
It exists so a capture runs the very file the lesson prints."""
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
    first = body.split("\n", 1)[0].strip()
    if first in ("# " + want, "<!-- " + want + " -->", "// " + want) or \
       first.startswith("// " + want + ": ") or first.startswith("# " + want + ": "):
        found.append(body)
        continue
    before = text[: m.start()].rstrip("\n").rsplit("\n", 1)[-1]
    if before.endswith("`" + want + "`:"):
        found.append(body)
if len(found) < n:
    sys.exit(1)
sys.stdout.write(found[n - 1])
