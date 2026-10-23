"""rank.py SOURCE: where the right option sits by length, per question and per language.

check-exercises refuses a lesson where the right option lands on one length
rank (longest, second, ..., shortest) in more than 45% of its questions, in
either language. This prints, for every quiz and multiple-choice question,
the rank of its right option(s) in English and in Portuguese (1 = longest),
and the share of each rank, so the options can be rewritten before the check.
"""
import collections, re, sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from q import parse

qs = parse(sys.argv[1])
share = {"en": collections.Counter(), "pt": collections.Counter()}
counted = {"en": 0, "pt": 0}
for q in qs:
    if q["type"] not in ("quiz", "multiple-choice"):
        continue
    row = []
    for lang in ("en", "pt"):
        ch = q[lang]["choices"]
        lens = [len(c["text"]) for c in ch]
        if len(set(lens)) == 1:
            row.append(f"{lang} tie"); continue
        order = sorted(set(lens), reverse=True)
        ranks = []
        for c in ch:
            if c["correct"]:
                n = len(c["text"])
                if lens.count(n) > 1:
                    ranks.append("t")
                else:
                    r = order.index(n) + 1
                    ranks.append(str(r) if r < len(order) else "S")
        for r in ranks:
            share[lang][r] += 1
        counted[lang] += 1
        row.append(f"{lang} {','.join(ranks)} {lens}")
    print(f"{q['line']:4} {q['section'][:22]:22} " + "   ".join(row))
for lang in ("en", "pt"):
    n = counted[lang] or 1
    print(lang, {k: f"{v}/{n} {100*v//n}%" for k, v in sorted(share[lang].items())})
