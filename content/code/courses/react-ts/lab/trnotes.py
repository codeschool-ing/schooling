"""trnotes.py PT_MD N NOTES_JSON: translate the notes of the Nth fence of a .pt.md.

The fence must be a schooling-example copied from the English by same.py;
NOTES_JSON is a list with one translated note per part (null keeps no note).
The code, the language and the file stay as the English has them.
"""
import json
import re
import sys

path, n, notes = sys.argv[1], int(sys.argv[2]), json.load(open(sys.argv[3]))
text = open(path).read()
fences = [m for m in re.finditer(r"^```([a-z-]*)\n([\s\S]*?)^```$", text, re.M) if m.group(1) != "schooling-figure"]
m = fences[n - 1]
assert m.group(1) == "schooling-example", m.group(1)
ex = json.loads(m.group(2))
assert len(ex["parts"]) == len(notes), (len(ex["parts"]), len(notes))
for p, note in zip(ex["parts"], notes):
    if note:
        p["note"] = note
    else:
        p.pop("note", None)
new = "```schooling-example\n" + json.dumps(ex, ensure_ascii=False) + "\n```"
open(path, "w").write(text[:m.start()] + new + text[m.end():])
