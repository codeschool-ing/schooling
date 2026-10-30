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
# check-exercises measures the length rank over single-answer quizzes only
qshare = {"en": collections.Counter(), "pt": collections.Counter()}
qcounted = {"en": 0, "pt": 0}
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
        if q["type"] == "quiz":
            for r in ranks:
                qshare[lang][r] += 1
            qcounted[lang] += 1
        row.append(f"{lang} {','.join(ranks)} {lens}")
    print(f"{q['line']:4} {q['section'][:22]:22} " + "   ".join(row))
for lang in ("en", "pt"):
    n = counted[lang] or 1
    print(lang, {k: f"{v}/{n} {100*v//n}%" for k, v in sorted(share[lang].items())})

for lang in ("en", "pt"):
    n = qcounted[lang] or 1
    over = [k for k, v in qshare[lang].items() if k != "t" and v * 100 >= 45 * n]
    print(lang, "quiz only:", {k: f"{v}/{n}" for k, v in sorted(qshare[lang].items())}, "OVER " + ",".join(over) if over else "")

# The guessing strategies check-exercises tries, over single-answer quizzes:
# a student who read nothing and applies one rule to every question.
ABS = {
    "en": ["never", "always", "only", "all", "must", "none", "every", "cannot", "nothing", "no one"],
    "pt": ["nunca", "jamais", "sempre", "somente", "apenas", "só", "todo", "toda", "todos", "todas",
           "nenhum", "nenhuma", "nada", "ninguém", "deve", "devem", "não pode", "não podem", "impossível"],
}
def absolute(lang, text):
    return re.search(r"(?i)(?:^|[^\w])(?:" + "|".join(map(re.escape, ABS[lang])) + r")(?:$|[^\w])", text) is not None
def by_length(ch, k):
    order = sorted(range(len(ch)), key=lambda i: -len(ch[i]["text"]))
    return order[max(0, min(k, len(order) - 1))]
def clean(lang, ch, longest):
    cand = [i for i, c in enumerate(ch) if not absolute(lang, c["text"])]
    if not cand:
        return by_length(ch, 0 if longest else len(ch) - 1)
    best = cand[0]
    for i in cand:
        n, m = len(ch[i]["text"]), len(ch[best]["text"])
        if (longest and n > m) or (not longest and n < m):
            best = i
    return best
STRATS = [("longest clean", lambda l, ch: clean(l, ch, True)), ("shortest clean", lambda l, ch: clean(l, ch, False)),
          ("longest", lambda l, ch: by_length(ch, 0)), ("shortest", lambda l, ch: by_length(ch, len(ch) - 1)),
          ("second-longest", lambda l, ch: by_length(ch, 1))]
bad = False
for lang in ("en", "pt"):
    single = [q for q in qs if q["type"] == "quiz" and len(q[lang]["choices"]) >= 2]
    res = []
    for name, f in STRATS:
        hits = [q["line"] for q in single if q[lang]["choices"][f(lang, q[lang]["choices"])]["correct"]]
        flag = " OVER" if len(hits) * 100 > 45 * len(single) else ""
        bad |= bool(flag)
        res.append(f"{name} {len(hits)}/{len(single)}{flag}" + (f" {hits}" if flag else ""))
    print(lang, "guess:", "; ".join(res))

# Hedges only in the right option are the mirror of the absolutes tell.
HEDGES = {
    "en": ["usually", "often", "frequently", "can", "may", "tends to", "tend to", "generally", "sometimes", "typically"],
    "pt": ["geralmente", "normalmente", "em geral", "frequentemente", "muitas vezes", "pode", "podem",
           "tende a", "tendem a", "costuma", "costumam", "às vezes", "tipicamente"],
}
def hedged(lang, text):
    if lang == "pt":
        text = re.sub(r"(?i)não pode[m]?|não é possível", " ", text)
    return re.search(r"(?i)(?:^|[^\w])(?:" + "|".join(map(re.escape, HEDGES[lang])) + r")(?:$|[^\w])", text) is not None
for q in qs:
    if q["type"] not in ("quiz", "multiple-choice"):
        continue
    for lang in ("en", "pt"):
        ch = q[lang]["choices"]
        right = [c for c in ch if c["correct"]]
        wrong = [c for c in ch if not c["correct"]]
        if any(hedged(lang, c["text"]) for c in right) and not any(hedged(lang, c["text"]) for c in wrong):
            print(f"line {q['line']} {lang}: a hedge only in the right option")
