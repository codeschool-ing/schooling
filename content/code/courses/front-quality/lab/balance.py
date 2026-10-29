#!/usr/bin/env python3
"""balance.py EXERCISES.json [RANK]: list the quizzes whose key sits at RANK (0 = longest) in either
language, with the key and the lengths, to choose which to rewrite. The judge is check-exercises."""
import json, sys
p = sys.argv[1]; want = int(sys.argv[2]) if len(sys.argv) > 2 else 0
en = json.load(open(p)); pt = json.load(open(p.replace(".json", ".pt.json")))
for e in en:
    if e["type"] != "quiz":
        continue
    k = [i for i, c in enumerate(e["choices"]) if c.get("correct")][0]
    out = []
    for texts in ([c["text"] for c in e["choices"]], [c["text"] for c in pt[e["id"]]["choices"]]):
        L = [len(t) for t in texts]
        out.append(None if L.count(L[k]) > 1 else sum(1 for x in L if x > L[k]))
    if want in out:
        print(e["id"], "en r%s pt r%s" % tuple(out), "|", e["choices"][k]["text"], "|", pt[e["id"]]["choices"][k]["text"],
              "| min other:", min(len(c["text"]) for i, c in enumerate(e["choices"]) if i != k))
