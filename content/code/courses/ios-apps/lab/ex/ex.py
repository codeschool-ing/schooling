"""Write a lesson's exercises.json and exercises.pt.json from one list.
THE STUDENT NEVER SEES THIS (C-40). Each text is an (en, pt) pair, so the two
files cannot drift in shape: the same ids, the same number of choices, the
same order. Run from the course directory: python3 lab/ex/l01.py
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))


def _p(x):
    return x if isinstance(x, tuple) else (x, x)


def Q(id, section, diff, prompt, hint, choices, drill=True):
    """choices: [(correct, (text_en, text_pt), (why_en, why_pt)), ...]; more than one correct = multiple-choice"""
    n = sum(1 for c in choices if c[0])
    return dict(id=id, section=section, type="multiple-choice" if n > 1 else "quiz", diff=diff,
                drill=drill, prompt=_p(prompt), hint=_p(hint),
                choices=[(c[0], _p(c[1]), _p(c[2])) for c in choices])


def N(id, section, diff, prompt, hint, value, tolerance=0, unit=None, drill=True):
    return dict(id=id, section=section, type="numeric", diff=diff, drill=drill, prompt=_p(prompt),
                hint=_p(hint), value=value, tolerance=tolerance, unit=_p(unit) if unit else None)


def C(id, section, diff, prompt, hint, accept_en, accept_pt=None, drill=True):
    return dict(id=id, section=section, type="cloze", diff=diff, drill=drill, prompt=_p(prompt),
                hint=_p(hint), accept=(accept_en, accept_pt or accept_en))


def O(id, section, diff, prompt, hint, items, drill=True):
    return dict(id=id, section=section, type="ordering", diff=diff, drill=drill, prompt=_p(prompt),
                hint=_p(hint), items=[_p(i) for i in items])


def M(id, section, diff, prompt, hint, pairs, distractors=(), drill=True):
    return dict(id=id, section=section, type="matching", diff=diff, drill=drill, prompt=_p(prompt),
                hint=_p(hint), pairs=[(_p(l), _p(r)) for l, r in pairs],
                distractors=[_p(d) for d in distractors])


def build(qs, lang):
    out_en, out_pt = [], {}
    for q in qs:
        e = {"id": q["id"], "version": 1, "section": q["section"], "type": q["type"],
             "difficulty": q["diff"], "drillable": q["drill"],
             "prompt": q["prompt"][0], "hint": q["hint"][0]}
        p = {"prompt": q["prompt"][1], "hint": q["hint"][1]}
        t = q["type"]
        if t in ("quiz", "multiple-choice"):
            e["choices"] = [{"text": c[1][0], "correct": c[0], "why": c[2][0]} for c in q["choices"]]
            p["choices"] = [{"text": c[1][1], "why": c[2][1]} for c in q["choices"]]
        elif t == "numeric":
            e["value"] = q["value"]; e["tolerance"] = q["tolerance"]
            if q["unit"]:
                e["unit"] = q["unit"][0]; p["unit"] = q["unit"][1]
        elif t == "cloze":
            e["blanks"] = [{"accept": q["accept"][0], "ignore_case": True, "ignore_accents": True}]
            p["blanks"] = [{"accept": q["accept"][1]}]
        elif t == "ordering":
            e["items"] = [i[0] for i in q["items"]]; p["items"] = [i[1] for i in q["items"]]
        elif t == "matching":
            e["pairs"] = [{"left": l[0], "right": r[0]} for l, r in q["pairs"]]
            p["pairs"] = [{"left": l[1], "right": r[1]} for l, r in q["pairs"]]
            if q["distractors"]:
                e["right_distractors"] = [d[0] for d in q["distractors"]]
                p["right_distractors"] = [d[1] for d in q["distractors"]]
        out_en.append(e); out_pt[q["id"]] = p
    return out_en, out_pt


def write(target, qs):
    """target: a lesson id, or 'exam' for the course exam (drillable false)."""
    ids = [q["id"] for q in qs]
    assert len(ids) == len(set(ids)), "duplicate id"
    en, pt = build(qs, None)
    course = os.path.join(HERE, "..", "..")
    if target == "exam":
        for e in en: e["drillable"] = False
        a, b = os.path.join(course, "exam.json"), os.path.join(course, "exam.pt.json")
    else:
        d = os.path.join(course, "lessons", target)
        a, b = os.path.join(d, "exercises.json"), os.path.join(d, "exercises.pt.json")
    open(a, "w", encoding="utf-8").write(json.dumps(en, indent=2, ensure_ascii=False) + "\n")
    open(b, "w", encoding="utf-8").write(json.dumps(pt, indent=2, ensure_ascii=False) + "\n")
    print(a, len(en))
