"""ranks.py lesson-dir: each quiz's key rank and whether it is the longest clean option, per language."""
import json, re, sys
d = sys.argv[1]
e = json.load(open(d + "/exercises.json")); p = json.load(open(d + "/exercises.pt.json"))
A = {"en": re.compile(r"(?i)(?:^|[^\w])(?:never|always|only|all|must|none|every|cannot|nothing|no one)(?:$|[^\w])"),
     "pt": re.compile(r"(?i)(?:^|[^\w])(?:nunca|jamais|sempre|somente|apenas|só|todo|toda|todos|todas|nenhum|nenhuma|nada|ninguém|deve|devem|não pode|não podem|impossível)(?:$|[^\w])")}
for q in e:
    if q["type"] != "quiz": continue
    k = [i for i, c in enumerate(q["choices"]) if c.get("correct")][0]
    for lang, t in (("en", [c["text"] for c in q["choices"]]), ("pt", [c["text"] for c in p[q["id"]]["choices"]])):
        L = [len(x) for x in t]
        clean = [i for i in range(len(t)) if not A[lang].search(t[i])] or list(range(len(t)))
        lc = max(clean, key=lambda i: L[i])
        r = "T" if L.count(L[k]) > 1 else sum(1 for x in L if x > L[k])
        print(q["id"], lang, "r" + str(r), "LC" if lc == k else "  ", t[k][:50], L)
