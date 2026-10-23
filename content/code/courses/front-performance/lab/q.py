"""q.py: the course's questions, written once in both languages.

Each lesson's questions (and the exam's) are a Python file in lab/questions/,
named for the lesson id or "exam". It defines EX, a list built with the
functions below; every text is a pair, English first. Running

    python3 lab/q.py le-xxxxxxxx      (or: exam)

writes exercises.json and exercises.pt.json (or exam.json and exam.pt.json).
An id written as "ex-NEW" is replaced, in the source file itself, by a fresh
id that appears nowhere in the repository, so an id is assigned once and is
then written down like every other.
"""
import importlib.util, json, os, re, secrets, subprocess, sys
sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
A = "0123456789abcdefghjkmnpqrstvwxyz"


def _base(id, section, type, difficulty, prompt, hint, drill):
    e = {"id": id, "version": 1}
    if section:
        e["section"] = section
    e.update({"type": type, "difficulty": difficulty, "drillable": drill, "prompt": prompt[0]})
    t = {"prompt": prompt[1]}
    if hint:
        e["hint"] = hint[0]; t["hint"] = hint[1]
    return e, t


def quiz(id, section, difficulty, prompt, hint, choices, drill=True, type="quiz"):
    e, t = _base(id, section, type, difficulty, prompt, hint, drill)
    e["choices"] = [{"text": c[0][0], "correct": c[1], "why": c[2][0]} for c in choices]
    t["choices"] = [{"text": c[0][1], "why": c[2][1]} for c in choices]
    return e, t


def mc(*a, **k):
    return quiz(*a, type="multiple-choice", **k)


def cloze(id, section, difficulty, prompt, hint, accept_en, accept_pt, ignore_case=True, drill=True):
    e, t = _base(id, section, "cloze", difficulty, prompt, hint, drill)
    e["blanks"] = [{"accept": accept_en, "ignore_case": ignore_case, "ignore_accents": True}]
    t["blanks"] = [{"accept": accept_pt}]
    return e, t


def numeric(id, section, difficulty, prompt, hint, value, tolerance=0, unit=None, drill=True):
    e, t = _base(id, section, "numeric", difficulty, prompt, hint, drill)
    e["value"] = value; e["tolerance"] = tolerance
    if unit:
        e["unit"] = unit[0]; t["unit"] = unit[1]
    return e, t


def ordering(id, section, difficulty, prompt, hint, items, drill=True):
    e, t = _base(id, section, "ordering", difficulty, prompt, hint, drill)
    e["items"] = [i[0] for i in items]; t["items"] = [i[1] for i in items]
    return e, t


def matching(id, section, difficulty, prompt, hint, pairs, distractors=(), drill=True):
    e, t = _base(id, section, "matching", difficulty, prompt, hint, drill)
    e["pairs"] = [{"left": l[0], "right": r[0]} for l, r in pairs]
    t["pairs"] = [{"left": l[1], "right": r[1]} for l, r in pairs]
    if distractors:
        e["right_distractors"] = [d[0] for d in distractors]
        t["right_distractors"] = [d[1] for d in distractors]
    return e, t


def fresh(n, text):
    used = set(subprocess.run(["git", "-C", HERE, "grep", "-ohE", r"\bex-[0-9a-hjkmnp-tv-z]{8}\b"],
                              capture_output=True, text=True).stdout.split())
    used |= set(re.findall(r"\bex-[0-9a-z]{8}\b", text))
    for f in (x for x in os.listdir(os.path.join(HERE, "questions")) if x.endswith(".py")):
        used |= set(re.findall(r"\bex-[0-9a-z]{8}\b", open(os.path.join(HERE, "questions", f)).read()))
    out = []
    while len(out) < n:
        i = "ex-" + "".join(secrets.choice(A) for _ in range(8))
        if i not in used:
            used.add(i); out.append(i)
    return out


def run(name):
    src = os.path.join(HERE, "questions", name + ".py")
    text = open(src, encoding="utf-8").read()
    n = text.count('"ex-NEW"')
    if n:
        for i in fresh(n, text):
            text = text.replace('"ex-NEW"', f'"{i}"', 1)
        open(src, "w", encoding="utf-8").write(text)
    sys.modules["q"] = sys.modules[__name__]
    spec = importlib.util.spec_from_file_location("qs", src)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    ids = [e["id"] for e, _ in mod.EX]
    if len(ids) != len(set(ids)):
        sys.exit(f"{src}: an id is used twice")
    if name == "exam":
        out = os.path.join(HERE, ".."); base = "exam"
    else:
        out = os.path.join(HERE, "..", "lessons", name); base = "exercises"
    with open(os.path.join(out, base + ".json"), "w", encoding="utf-8") as f:
        f.write(json.dumps([e for e, _ in mod.EX], indent=2, ensure_ascii=False) + "\n")
    with open(os.path.join(out, base + ".pt.json"), "w", encoding="utf-8") as f:
        f.write(json.dumps({e["id"]: t for e, t in mod.EX}, indent=2, ensure_ascii=False) + "\n")
    report(name, mod.EX)


def report(name, ex):
    """Where the key sits by length, per language, so a habit shows before the checker does."""
    for lang in (0, 1):
        ranks, pos = {}, {}
        n = 0
        for e, t in ex:
            if e["type"] not in ("quiz", "multiple-choice") or e["type"] == "multiple-choice":
                continue
            texts = [c["text"] for c in (e["choices"] if lang == 0 else t["choices"])]
            key = [c["correct"] for c in e["choices"]].index(True)
            lens = sorted({len(x) for x in texts}, reverse=True)
            if len(set(len(x) for x in texts)) == len(texts):
                r = lens.index(len(texts[key]))
                ranks[r] = ranks.get(r, 0) + 1
            pos[key] = pos.get(key, 0) + 1
            n += 1
        print(f"{name} [{'en' if lang == 0 else 'pt'}] {n} quizzes; key by length rank {dict(sorted(ranks.items()))}; by position {dict(sorted(pos.items()))}")


if __name__ == "__main__":
    for a in sys.argv[1:]:
        run(a)
