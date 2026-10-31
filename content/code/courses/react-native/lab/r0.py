#!/usr/bin/env python3
"""r0.py LESSON_DIR_OR_EXAM: for each quiz, the key's length rank and the options' lengths, per language."""
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
en_p = p / "exercises.json" if p.is_dir() else p
en = json.load(open(en_p)); pt = json.load(open(str(en_p).replace(".json", ".pt.json")))
for e in en:
    if e["type"] != "quiz": continue
    k = [i for i, c in enumerate(e["choices"]) if c.get("correct")][0]
    out = []
    for texts in ([c["text"] for c in e["choices"]], [c["text"] for c in pt[e["id"]]["choices"]]):
        L = [len(x) for x in texts]
        r = "t" if L.count(L[k]) > 1 else str(sum(1 for x in L if x > L[k]))
        out.append(r + " " + str(L[k]) + "/" + ",".join(str(x) for i, x in enumerate(L) if i != k))
    print(e["id"], "en", out[0], "| pt", out[1])
