"""Bilingual exercise authoring: each text is a pair (en, pt).
   write(dir, items) writes exercises.json and exercises.pt.json;
   write(dir, items, exam=True) writes exam.json / exam.pt.json."""
import json, pathlib

def _base(id, section, type, difficulty, prompt, hint):
    en = {"id": id, "version": 1}
    if section: en["section"] = section
    en.update({"type": type, "difficulty": difficulty})
    pt = {}
    return en, pt

def _fin(en, pt, prompt, hint, exam):
    if not exam: en["drillable"] = True
    en["prompt"] = prompt[0]; pt["prompt"] = prompt[1]
    if hint: en["hint"] = hint[0]; pt["hint"] = hint[1]

def quiz(id, section, diff, prompt, choices, hint=None, multi=False, exam=False):
    en, pt = _base(id, section, "multiple-choice" if multi else "quiz", diff, prompt, hint)
    _fin(en, pt, prompt, hint, exam)
    en["choices"] = [{"text": c[0], "correct": bool(c[2]), "why": c[3]} for c in choices]
    pt["choices"] = [{"text": c[1], "why": c[4]} for c in choices]
    return en, pt

def numeric(id, section, diff, prompt, value, unit, hint=None, tolerance=0, exam=False):
    en, pt = _base(id, section, "numeric", diff, prompt, hint)
    _fin(en, pt, prompt, hint, exam)
    en["value"] = value; en["tolerance"] = tolerance
    if unit: en["unit"] = unit[0]; pt["unit"] = unit[1]
    return en, pt

def ordering(id, section, diff, prompt, items, trap=None, hint=None, exam=False):
    en, pt = _base(id, section, "ordering", diff, prompt, hint)
    _fin(en, pt, prompt, hint, exam)
    en["items"] = [i[0] for i in items]; pt["items"] = [i[1] for i in items]
    if trap: en["trap"] = trap[0]; pt["trap"] = trap[1]
    return en, pt

def cloze(id, section, diff, prompt, accept, hint=None, exam=False):
    """accept: list of blanks, each (en_list, pt_list)."""
    en, pt = _base(id, section, "cloze", diff, prompt, hint)
    _fin(en, pt, prompt, hint, exam)
    en["blanks"] = [{"accept": a[0], "ignore_case": True, "ignore_accents": True} for a in accept]
    pt["blanks"] = [{"accept": a[1]} for a in accept]
    return en, pt

def matching(id, section, diff, prompt, pairs, hint=None, exam=False):
    en, pt = _base(id, section, "matching", diff, prompt, hint)
    _fin(en, pt, prompt, hint, exam)
    en["pairs"] = [{"left": p[0], "right": p[2]} for p in pairs]
    pt["pairs"] = [{"left": p[1], "right": p[3]} for p in pairs]
    return en, pt

def write(d, items, exam=False):
    d = pathlib.Path(d)
    ids = [e["id"] for e, _ in items]
    assert len(ids) == len(set(ids)), "duplicate id"
    name = "exam" if exam else "exercises"
    (d / f"{name}.json").write_text(json.dumps([e for e, _ in items], indent=1, ensure_ascii=False) + "\n")
    (d / f"{name}.pt.json").write_text(json.dumps({e["id"]: p for e, p in items}, indent=1, ensure_ascii=False) + "\n")
    print(f"{len(items)} written to {d}/{name}.json")
