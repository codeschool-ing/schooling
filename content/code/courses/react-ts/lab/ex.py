"""ex.py: a lesson's questions, written once with both languages side by side.

    python3 lab/ex.py lessons/<lesson id>      # writes exercises.json and exercises.pt.json
    python3 lab/ex.py exam                     # writes exam.json and exam.pt.json

The source is lab/exercises/<lesson id>.py (or exam.py), which defines QS, a
list built with the helpers below. Every text is a pair (english, portuguese).
The ids are written in the source and never worked out.
"""
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def C(en, pt, why_en, why_pt, ok=False):
    return dict(en=en, pt=pt, why_en=why_en, why_pt=why_pt, ok=ok)


def quiz(id, section, diff, prompt, hint, choices, drill=True, kind="quiz"):
    return dict(id=id, section=section, type=kind, difficulty=diff, drill=drill,
                prompt=prompt, hint=hint, choices=choices)


def multi(id, section, diff, prompt, hint, choices, drill=True):
    return quiz(id, section, diff, prompt, hint, choices, drill, kind="multiple-choice")


def numeric(id, section, diff, prompt, hint, value, tolerance=0, unit=None, drill=True):
    return dict(id=id, section=section, type="numeric", difficulty=diff, drill=drill,
                prompt=prompt, hint=hint, value=value, tolerance=tolerance, unit=unit)


def cloze(id, section, diff, prompt, hint, accept_en, accept_pt, ignore_case=False, ignore_accents=True, drill=True):
    return dict(id=id, section=section, type="cloze", difficulty=diff, drill=drill,
                prompt=prompt, hint=hint, accept_en=accept_en, accept_pt=accept_pt,
                ignore_case=ignore_case, ignore_accents=ignore_accents)


def ordering(id, section, diff, prompt, hint, items, drill=True):
    """items: list of (en, pt), in the right order."""
    return dict(id=id, section=section, type="ordering", difficulty=diff, drill=drill,
                prompt=prompt, hint=hint, items=items)


def matching(id, section, diff, prompt, hint, pairs, distractors=(), drill=True):
    """pairs: list of ((left_en, left_pt), (right_en, right_pt)); distractors: list of (en, pt)."""
    return dict(id=id, section=section, type="matching", difficulty=diff, drill=drill,
                prompt=prompt, hint=hint, pairs=pairs, distractors=list(distractors))


def place(id, choices):
    """Where the correct option sits is decided by the id, so that it is spread
    over every position and nobody chose it."""
    ok = [c for c in choices if c["ok"]]
    rest = [c for c in choices if not c["ok"]]
    at = sum(ord(ch) * (i + 1) for i, ch in enumerate(id)) % len(choices)
    return rest[:at] + ok + rest[at:]


def build(qs, exam=False):
    en, pt = [], {}
    for q in qs:
        e = {"id": q["id"], "version": 1}
        if not exam:
            e["section"] = q["section"]
        e.update({"type": q["type"], "difficulty": q["difficulty"]})
        if not exam:
            e["drillable"] = q["drill"]
        e.update({"prompt": q["prompt"][0], "hint": q["hint"][0]})
        p = {"prompt": q["prompt"][1], "hint": q["hint"][1]}
        t = q["type"]
        if t == "quiz":
            q["choices"] = place(q["id"], q["choices"])
        if t in ("quiz", "multiple-choice"):
            e["choices"] = [{"text": c["en"], "correct": c["ok"], "why": c["why_en"]} for c in q["choices"]]
            p["choices"] = [{"text": c["pt"], "why": c["why_pt"]} for c in q["choices"]]
        elif t == "numeric":
            e["value"], e["tolerance"] = q["value"], q["tolerance"]
            if q["unit"]:
                e["unit"] = q["unit"][0]
                p["unit"] = q["unit"][1]
        elif t == "cloze":
            e["blanks"] = [{"accept": q["accept_en"], "ignore_case": q["ignore_case"],
                            "ignore_accents": q["ignore_accents"]}]
            p["blanks"] = [{"accept": q["accept_pt"]}]
        elif t == "ordering":
            e["items"] = [i[0] for i in q["items"]]
            p["items"] = [i[1] for i in q["items"]]
        elif t == "matching":
            e["pairs"] = [{"left": l[0], "right": r[0]} for l, r in q["pairs"]]
            p["pairs"] = [{"left": l[1], "right": r[1]} for l, r in q["pairs"]]
            if q["distractors"]:
                e["right_distractors"] = [d[0] for d in q["distractors"]]
                p["right_distractors"] = [d[1] for d in q["distractors"]]
        en.append(e)
        pt[q["id"]] = p
    return en, pt


def main(target):
    if target == "exam":
        src, out, exam = HERE / "exercises" / "exam.py", HERE.parent, True
        names = ("exam.json", "exam.pt.json")
    else:
        lesson = Path(target).resolve()
        src, out, exam = HERE / "exercises" / f"{lesson.name}.py", lesson, False
        names = ("exercises.json", "exercises.pt.json")
    spec = importlib.util.spec_from_file_location("qs", src)
    mod = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(HERE))
    spec.loader.exec_module(mod)
    ids = [q["id"] for q in mod.QS]
    assert len(ids) == len(set(ids)), "an id is used twice"
    en, pt = build(mod.QS, exam)
    (out / names[0]).write_text(json.dumps(en, indent=2, ensure_ascii=False) + "\n")
    (out / names[1]).write_text(json.dumps(pt, indent=2, ensure_ascii=False) + "\n")
    print(f"{len(en)} questions")


if __name__ == "__main__" and len(sys.argv) == 2:
    main(sys.argv[1])


def ranks(target):
    """Print where each correct option ranks by length, longest = 1, in both languages."""
    lesson = Path(target).resolve()
    src = HERE / "exercises" / ("exam.py" if target == "exam" else f"{lesson.name}.py")
    spec = importlib.util.spec_from_file_location("qs", src)
    mod = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(HERE))
    spec.loader.exec_module(mod)
    from collections import Counter
    tally = {"en": Counter(), "pt": Counter()}
    for q in mod.QS:
        if q["type"] != "quiz":
            continue
        row = []
        for lang in ("en", "pt"):
            lens = [len(c[lang]) for c in q["choices"]]
            ok = [len(c[lang]) for c in q["choices"] if c["ok"]][0]
            if len(set(lens)) == 1:
                r = "-"
            else:
                r = sorted(set(lens), reverse=True).index(ok) + 1
            tally[lang][r] += 1
            row.append(f"{lang}:{r}")
        pos = [i for i, c in enumerate(q["choices"]) if c["ok"]][0] + 1
        print(q["id"], *row, f"pos:{pos}")
    for lang in tally:
        print(lang, dict(sorted(tally[lang].items(), key=str)))


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] == "ranks":
    ranks(sys.argv[1])
    sys.exit(0)
