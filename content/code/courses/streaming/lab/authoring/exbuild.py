#!/usr/bin/env python3
"""exbuild.py SPEC.py OUTDIR [--exam]: exercises.json and exercises.pt.json (or exam.json/exam.pt.json).

Ids are kept per (spec, key) in /var/tmp/lab/exids.json; a question's key is its section plus
its English prompt's first 40 characters, so editing other questions never moves an id.
If the mapping is lost, ids are recovered from the existing JSON by prompt.
"""
import json, os, subprocess, sys
spec, outdir = sys.argv[1], sys.argv[2]
exam = "--exam" in sys.argv
os.makedirs("/var/tmp/lab/exids", exist_ok=True)
IDS = "/var/tmp/lab/exids/" + os.path.basename(spec) + (".exam" if exam else "") + ".json"
ids = json.load(open(IDS)) if os.path.exists(IDS) else {}
base = "exam" if exam else "exercises"
old = {}
try:
    for e in json.load(open(os.path.join(outdir, base + ".json"))):
        old[e["prompt"]] = e["id"]
except FileNotFoundError: pass
QS = []
def _ch(choices):
    en, pt = [], []
    for c in choices:
        t_en, t_pt, ok, w_en, w_pt = c
        en.append({"text": t_en, "correct": ok, "why": w_en}); pt.append({"text": t_pt, "why": w_pt})
    return en, pt
def _base(section, typ, diff, p, hint):
    e = {"section": section, "type": typ, "difficulty": diff, "drillable": not exam, "prompt": p[0]}
    t = {"prompt": p[1]}
    if hint: e["hint"], t["hint"] = hint
    return e, t
def Q(section, diff, p, choices, hint=None, typ="quiz"):
    e, t = _base(section, typ, diff, p, hint); e["choices"], t["choices"] = _ch(choices); QS.append((e, t))
def MC(section, diff, p, choices, hint=None): Q(section, diff, p, choices, hint, "multiple-choice")
def N(section, diff, p, value, tol, unit, hint=None):
    e, t = _base(section, "numeric", diff, p, hint); e["value"], e["tolerance"] = value, tol
    e["unit"], t["unit"] = unit; QS.append((e, t))
def C(section, diff, p, accept, hint=None, ignore_case=True, ignore_accents=True):
    e, t = _base(section, "cloze", diff, p, hint)
    e["blanks"] = [{"accept": a[0], "ignore_case": ignore_case, "ignore_accents": ignore_accents} for a in accept]
    t["blanks"] = [{"accept": a[1]} for a in accept]; QS.append((e, t))
def O(section, diff, p, items, hint=None):
    e, t = _base(section, "ordering", diff, p, hint)
    e["items"] = [i[0] for i in items]; t["items"] = [i[1] for i in items]; QS.append((e, t))
def M(section, diff, p, pairs, distractors=(), hint=None):
    e, t = _base(section, "matching", diff, p, hint)
    e["pairs"] = [{"left": a, "right": c} for a, b, c, d in pairs]
    t["pairs"] = [{"left": b, "right": d} for a, b, c, d in pairs]
    if distractors:
        e["right_distractors"] = [d[0] for d in distractors]; t["right_distractors"] = [d[1] for d in distractors]
    QS.append((e, t))
exec(open(spec).read())
def newid():
    return subprocess.run(["/var/tmp/lab/bin/newid", "ex"], capture_output=True, text=True).stdout.strip()
en_all, pt_all = [], {}
seen = set()
for e, t in QS:
    key = os.path.basename(spec) + "|" + e["section"] + "|" + e["prompt"][:40]
    if key in seen: sys.exit("duplicate key " + key)
    seen.add(key)
    i = ids.get(key) or old.get(e["prompt"]) or newid()
    ids[key] = i
    e = {"id": i, "version": 1, **e}
    en_all.append(e); pt_all[i] = t
json.dump(ids, open(IDS, "w"), indent=0)
json.dump(en_all, open(os.path.join(outdir, base + ".json"), "w"), ensure_ascii=False, indent=2)
json.dump(pt_all, open(os.path.join(outdir, base + ".pt.json"), "w"), ensure_ascii=False, indent=2)
for f in (base + ".json", base + ".pt.json"):
    with open(os.path.join(outdir, f), "a") as fh: fh.write("\n")
print(f"{len(en_all)} questions -> {outdir}/{base}.json")
