#!/usr/bin/env python3
"""exrank.py DIR [exam]: per question, the length rank of the correct option (1 = longest), en and pt."""
import json, sys, collections
d = sys.argv[1]; base = "exam" if len(sys.argv) > 2 else "exercises"
en = json.load(open(f"{d}/{base}.json")); pt = json.load(open(f"{d}/{base}.pt.json"))
cnt = {"en": collections.Counter(), "pt": collections.Counter()}
for e in en:
    if e["type"] not in ("quiz",) : continue
    row = []
    for lang, texts in (("en", [c["text"] for c in e["choices"]]), ("pt", [c["text"] for c in pt[e["id"]]["choices"]])):
        k = [i for i, c in enumerate(e["choices"]) if c["correct"]][0]
        L = [len(t) for t in texts]
        if len(set(L)) == 1: row.append(f"{lang}:tie"); continue
        rank = sorted(set(L), reverse=True).index(L[k]) + 1
        tie = L.count(L[k]) > 1
        r = "tie" if tie else str(rank); cnt[lang][r] += 1
        row.append(f"{lang}:{r}")
    print(e["id"], " ".join(row), "pos", [c["correct"] for c in e["choices"]].index(True), e["prompt"][:60])
for lang in cnt: print(lang, dict(cnt[lang]))
