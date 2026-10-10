"""exb.py SPEC OUTDIR [--exam]: build exercises.json and exercises.pt.json (or exam*.json) from a spec.

The spec is Python calling Q(...), M(...), O(...), C(...), N(...), P(...).
An id written as "new" is replaced by a fresh one in the spec file itself.

Q(id, section, diff, prompt_en, prompt_pt, [(en, pt, correct, why_en, why_pt), ...], pos=None)
   quiz; the correct option is placed at position `pos` (0-3), or rotated if None
M(...)  multiple-choice, same shape, several correct, order kept as written
O(id, section, diff, prompt_en, prompt_pt, [(en, pt), ...])            ordering, in the right order
P(id, section, diff, prompt_en, prompt_pt, [(l, r_en, r_pt), ...] or [(l_en,l_pt,r_en,r_pt)], distractors [(en, pt)])  matching
C(id, section, diff, prompt_en, prompt_pt, accept_en, accept_pt)        cloze, one blank
N(id, section, diff, prompt_en, prompt_pt, value, tolerance, unit_en, unit_pt)  numeric
hint=(en, pt) is accepted by all.
"""
import json, os, re, secrets, subprocess, sys, collections

A = "0123456789abcdefghjkmnpqrstvwxyz"
SPEC, OUT = sys.argv[1], sys.argv[2]
EXAM = "--exam" in sys.argv
src = open(SPEC).read()


def fresh():
    while True:
        i = "ex-" + "".join(secrets.choice(A) for _ in range(8))
        r = subprocess.run(["grep", "-rqF", i, "/home/user/schooling/content", SPEC], capture_output=True)
        if r.returncode == 1:
            return i


changed = False
while '"new"' in src:
    src = src.replace('"new"', '"%s"' % fresh(), 1)
    changed = True
if changed:
    open(SPEC, "w").write(src)

EN, PT = [], {}
rot = [0]


def base(id, section, diff, typ, pen, ppt, hint):
    e = {"id": id, "version": 1, "section": section, "type": typ, "difficulty": diff,
         "drillable": not EXAM, "prompt": pen}
    p = {"prompt": ppt}
    if hint:
        e["hint"], p["hint"] = hint
    return e, p


def _choices(opts, pos, single):
    opts = list(opts)
    if single:
        k = [i for i, o in enumerate(opts) if o[2]]
        assert len(k) == 1, opts
        c = opts.pop(k[0])
        if pos is None:
            pos = rot[0] % len(opts + [c])
            rot[0] += 1
        opts.insert(pos, c)
    return opts


def Q(id, section, diff, pen, ppt, opts, pos=None, hint=None, typ="quiz"):
    e, p = base(id, section, diff, typ, pen, ppt, hint)
    opts = _choices(opts, pos, typ == "quiz")
    e["choices"] = [{"text": o[0], "correct": bool(o[2]), "why": o[3]} for o in opts]
    p["choices"] = [{"text": o[1], "why": o[4]} for o in opts]
    EN.append(e); PT[id] = p


def M(id, section, diff, pen, ppt, opts, hint=None):
    Q(id, section, diff, pen, ppt, opts, hint=hint, typ="multiple-choice")


def O(id, section, diff, pen, ppt, items, hint=None):
    e, p = base(id, section, diff, "ordering", pen, ppt, hint)
    e["items"] = [i[0] for i in items]; p["items"] = [i[1] for i in items]
    EN.append(e); PT[id] = p


def P(id, section, diff, pen, ppt, pairs, distractors=(), hint=None):
    e, p = base(id, section, diff, "matching", pen, ppt, hint)
    ep, pp = [], []
    for pr in pairs:
        if len(pr) == 3:
            l, ren, rpt = pr; len_, lpt = l, l
        else:
            len_, lpt, ren, rpt = pr
        ep.append({"left": len_, "right": ren}); pp.append({"left": lpt, "right": rpt})
    e["pairs"], p["pairs"] = ep, pp
    if distractors:
        e["right_distractors"] = [d[0] for d in distractors]
        p["right_distractors"] = [d[1] for d in distractors]
    EN.append(e); PT[id] = p


def C(id, section, diff, pen, ppt, acc_en, acc_pt, hint=None, case=True, accents=True):
    e, p = base(id, section, diff, "cloze", pen, ppt, hint)
    e["blanks"] = [{"accept": acc_en, "ignore_case": case, "ignore_accents": accents}]
    p["blanks"] = [{"accept": acc_pt}]
    EN.append(e); PT[id] = p


def N(id, section, diff, pen, ppt, value, tol, unit_en, unit_pt, hint=None):
    e, p = base(id, section, diff, "numeric", pen, ppt, hint)
    e["value"], e["tolerance"], e["unit"] = value, tol, unit_en
    p["unit"] = unit_pt
    EN.append(e); PT[id] = p


exec(compile(src, SPEC, "exec"))

# a report on the tells the checker measures, per language
for lang in ("en", "pt"):
    ranks = collections.Counter()
    n = 0
    for e in EN:
        if e["type"] != "quiz":
            continue
        texts = [c["text"] for c in e["choices"]] if lang == "en" else [c["text"] for c in PT[e["id"]]["choices"]]
        k = [i for i, c in enumerate(e["choices"]) if c["correct"]][0]
        lens = [len(t) for t in texts]
        if lens.count(lens[k]) > 1:
            continue
        rank = sorted(lens, reverse=True).index(lens[k])
        ranks[rank] += 1; n += 1
    print(lang, "quiz", n, "key length rank (0=longest):", dict(sorted(ranks.items())),
          "max share %.0f%%" % (100 * max(ranks.values()) / max(n, 1)) if n else "")
if "-v" in sys.argv:
    for e in EN:
        if e["type"] != "quiz":
            continue
        out = []
        for lang in ("en", "pt"):
            texts = [c["text"] for c in e["choices"]] if lang == "en" else [c["text"] for c in PT[e["id"]]["choices"]]
            k = [i for i, c in enumerate(e["choices"]) if c["correct"]][0]
            lens = [len(t) for t in texts]
            out.append("%s=%d/%s" % (lang, sorted(lens, reverse=True).index(lens[k]), lens))
        print(e["id"], e["section"], *out)
print("types", dict(collections.Counter(e["type"] for e in EN)), "total", len(EN))
print("positions", dict(collections.Counter([i for e in EN if e["type"] == "quiz" for i, c in enumerate(e["choices"]) if c["correct"]])))
name = "exam" if EXAM else "exercises"
with open(os.path.join(OUT, name + ".json"), "w") as f:
    f.write(json.dumps(EN, indent=2, ensure_ascii=False) + "\n")
with open(os.path.join(OUT, name + ".pt.json"), "w") as f:
    f.write(json.dumps(PT, indent=2, ensure_ascii=False) + "\n")
