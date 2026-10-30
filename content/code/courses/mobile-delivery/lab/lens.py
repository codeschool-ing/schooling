"""lens.py lNN: per quiz, the key's text and the options' lengths, in each language."""
import json, sys
d = "/home/user/schooling/content/code/courses/mobile-delivery/" + (sys.argv[1] if "/" in sys.argv[1] else "")
import glob
path = sys.argv[1]
en = json.load(open(path)); pt = json.load(open(path.replace(".json", ".pt.json")))
for e in en:
    if e["type"] != "quiz": continue
    k = [i for i, c in enumerate(e["choices"]) if c.get("correct")][0]
    for lang, texts in (("en", [c["text"] for c in e["choices"]]), ("pt", [c["text"] for c in pt[e["id"]]["choices"]])):
        L = [len(t) for t in texts]
        r = "T" if L.count(L[k]) > 1 else sum(1 for x in L if x > L[k])
        print(e["id"], lang, "r%s" % r, L, "|", texts[k][:50], "|", e["prompt"][:40] if lang == "en" else "")
