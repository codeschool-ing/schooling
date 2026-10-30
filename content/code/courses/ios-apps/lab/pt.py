"""Give a .pt.md the English fences. THE STUDENT NEVER SEES THIS (C-40).

    python3 lab/pt.py lessons/<id>/<slug>.pt.md [...]

A translation is written with a line `@@fence@@` wherever the English has a
fence, and `@@notes ["…", "…"]@@` where the English has a schooling-example:
the JSON list is the translated notes, one per part. This copies the English
fences in order, so every program, transcript and output in the translation
is the English one byte for byte (validate-content compares them). Figures
are not fences here: each language's figure is written by lab/figures.
"""
import json, re, sys

FENCE = re.compile(r"^```([\w-]*)\n(.*?)^```$", re.S | re.M)
for pt in sys.argv[1:]:
    en = open(pt.replace(".pt.md", ".md"), encoding="utf-8").read()
    fences = [m for m in FENCE.finditer(en) if m.group(1) != "schooling-figure"]
    t = open(pt, encoding="utf-8").read()
    out, i, pos = [], 0, 0
    for m in re.finditer(r"^@@(fence|notes (\[.*\]))@@$", t, re.M):
        out.append(t[pos:m.start()]); pos = m.end()
        if i >= len(fences): sys.exit(f"{pt}: more fences than the English has")
        f = fences[i]; i += 1
        if m.group(1) == "fence":
            if f.group(1) == "schooling-example": sys.exit(f"{pt}: fence {i} is an example; give @@notes@@")
            out.append(f.group(0))
        else:
            if f.group(1) != "schooling-example": sys.exit(f"{pt}: fence {i} is not an example")
            ex = json.loads(f.group(2)); notes = json.loads(m.group(2))
            if len(notes) != len(ex["parts"]): sys.exit(f"{pt}: {len(notes)} notes for {len(ex['parts'])} parts")
            for p, n in zip(ex["parts"], notes):
                if n is None: p.pop("note", None)
                else: p["note"] = n
            out.append("```schooling-example\n" + json.dumps(ex, ensure_ascii=False) + "\n```")
    out.append(t[pos:])
    t = "".join(out)
    if i and i != len(fences): sys.exit(f"{pt}: {i} fences given, the English has {len(fences)}")
    open(pt, "w", encoding="utf-8").write(t)
    print(pt, i, "fences")
