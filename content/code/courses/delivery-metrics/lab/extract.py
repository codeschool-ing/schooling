#!/usr/bin/env python3
'''Print one program out of a lesson's prose, so a capture runs what the page shows.

    python3 lab/extract.py lessons/le-zz75x0ba billing.py

It reads every English section of the lesson (never a `.pt.md`, whose fences
are the English ones byte for byte anyway).

A program is found by its file name, written where a reader sees it:

  - an ordinary fence whose first line is a docstring opening with the name,
    `"""billing.py: ...`, or a comment `# billing.py: ...`;
  - a `schooling-example` whose "file" is the name, its parts joined in order,
    which is what the copy button hands the student;

Data is never pasted from a bare fence: a lesson that needs a small data set
shows a short program that writes it, found the same way.

Exactly one match, or this refuses: two programs with one name in a lesson is
a mistake somebody should hear about.
'''
import glob
import json
import os
import re
import sys

path, name = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(path, "*.md"))) if os.path.isdir(path) else [path]
text = "\n".join(open(f, encoding="utf-8").read() for f in files if not f.endswith(".pt.md"))
found = []
for lang, body in re.findall(r"^```([\w-]*)\n(.*?)^```$", text, re.S | re.M):
    first = body.split("\n", 1)[0]
    if lang == "schooling-example":
        block = json.loads(body)
        if block.get("file") == name:
            found.append("".join(p["code"] for p in block["parts"]))
    elif lang and re.match(rf'^(""")?{re.escape(name)}: |^# {re.escape(name)}: ', first):
        found.append(body)
if len(found) != 1:
    sys.exit(f"{path}: {len(found)} programs called {name}, and a capture needs exactly one")
sys.stdout.write(found[0])
