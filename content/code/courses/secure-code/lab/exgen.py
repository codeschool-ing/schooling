"""exgen.py: write exercises.json and exercises.pt.json from one Python list.

    from exgen import build, Q, C
    QS = [
      Q("ex-...", "section", "quiz", "medium",
        ("prompt en", "prompt pt"),
        choices=[C(True, "en", "pt", "why en", "why pt"), C(False, ...), ...]),
      Q(id, sec, "multiple-choice", diff, prompt, choices=[...]),      # several C(True,…)
      Q(id, sec, "ordering", diff, prompt, items=[("en","pt"), ...]),  # in the right order
      Q(id, sec, "matching", diff, prompt, pairs=[(("l en","l pt"),("r en","r pt")), ...],
        distractors=[("en","pt")]),
      Q(id, sec, "cloze", diff, ("text with ___", "texto com ___"),
        blanks=[(["en", ...], ["pt", ...])], ignore_case=True),
      Q(id, sec, "numeric", diff, prompt, value=10, tolerance=0),
    ]
    build("path/to/lesson", QS)            # or build(..., exam=True) for exam.json

hint=("en","pt") is optional on any question. drillable defaults to True for a
lesson and is always False in an exam."""
import json, pathlib, re


def C(correct, en, pt, why_en, why_pt):
    return dict(correct=correct, en=en, pt=pt, why_en=why_en, why_pt=why_pt)


def Q(id, section, type, difficulty, prompt, **kw):
    return dict(id=id, section=section, type=type, difficulty=difficulty, prompt=prompt, **kw)


def build(where, qs, exam=False, out_en=None, out_pt=None):
    where = pathlib.Path(where)
    en, pt = [], {}
    seen = set()
    for q in qs:
        assert q["id"] not in seen, q["id"]; seen.add(q["id"])
        e = {"id": q["id"], "version": 1}
        if not exam:
            e["section"] = q["section"]
        e.update(type=q["type"], difficulty=q["difficulty"], drillable=(False if exam else q.get("drillable", True)),
                 prompt=q["prompt"][0])
        t = {"prompt": q["prompt"][1]}
        if q.get("hint"):
            e["hint"] = q["hint"][0]; t["hint"] = q["hint"][1]
        typ = q["type"]
        if typ in ("quiz", "multiple-choice"):
            cs = q["choices"]
            n = sum(c["correct"] for c in cs)
            assert (n == 1) if typ == "quiz" else (n >= 1), q["id"]
            e["choices"] = []
            for c in cs:
                d = {"text": c["en"]}
                if typ == "quiz" or c["correct"]:
                    d["correct"] = c["correct"] if typ == "quiz" else True
                d["why"] = c["why_en"]
                e["choices"].append(d)
            t["choices"] = [{"text": c["pt"], "why": c["why_pt"]} for c in cs]
        elif typ == "ordering":
            e["items"] = [i[0] for i in q["items"]]; t["items"] = [i[1] for i in q["items"]]
        elif typ == "matching":
            e["pairs"] = [{"left": l[0], "right": r[0]} for l, r in q["pairs"]]
            t["pairs"] = [{"left": l[1], "right": r[1]} for l, r in q["pairs"]]
            if q.get("distractors"):
                e["right_distractors"] = [d[0] for d in q["distractors"]]
                t["right_distractors"] = [d[1] for d in q["distractors"]]
        elif typ == "cloze":
            assert q["prompt"][0].count("___") == len(q["blanks"]), q["id"]
            assert q["prompt"][1].count("___") == len(q["blanks"]), q["id"]
            ic = q.get("ignore_case", True)
            e["blanks"] = [{"accept": b[0], "ignore_case": ic, "ignore_accents": True} for b in q["blanks"]]
            t["blanks"] = [{"accept": b[1]} for b in q["blanks"]]
        elif typ == "numeric":
            e["value"] = q["value"]; e["tolerance"] = q.get("tolerance", 0)
            if q.get("unit"):
                e["unit"] = q["unit"][0]; t["unit"] = q["unit"][1]
        else:
            raise SystemExit("unknown type " + typ)
        en.append(e); pt[q["id"]] = t
    a = out_en or where / ("exam.json" if exam else "exercises.json")
    b = out_pt or where / ("exam.pt.json" if exam else "exercises.pt.json")
    pathlib.Path(a).write_text(json.dumps(en, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    pathlib.Path(b).write_text(json.dumps(pt, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    report(en, pt)


def report(en, pt):
    """Print the share of each length rank of the key, per language: a cheap
    preview of check-exercises' ruler (which is the judge)."""
    for lang in ("en", "pt"):
        ranks, pos = {}, {}
        n = 0
        for e in en:
            if e["type"] != "quiz":
                continue
            texts = [c["text"] for c in e["choices"]] if lang == "en" else [c["text"] for c in pt[e["id"]]["choices"]]
            k = [i for i, c in enumerate(e["choices"]) if c.get("correct")][0]
            L = [len(x) for x in texts]
            if len(set(L)) == 1:
                continue
            order = sorted(set(L), reverse=True)
            r = order.index(L[k]); n += 1
            ranks[r] = ranks.get(r, 0) + 1
            pos[k] = pos.get(k, 0) + 1
        print(lang, "quiz:", n, "rank shares:", {r: f"{v}/{n}" for r, v in sorted(ranks.items())}, "positions:", dict(sorted(pos.items())))


def ranks(path_en, path_pt=None):
    """Per quiz: the key's length rank in each language, and the lengths."""
    import json
    en = json.load(open(path_en))
    pt = json.load(open(path_pt or path_en.replace(".json", ".pt.json")))
    for e in en:
        if e["type"] != "quiz":
            continue
        k = [i for i, c in enumerate(e["choices"]) if c.get("correct")][0]
        out = []
        for texts in ([c["text"] for c in e["choices"]], [c["text"] for c in pt[e["id"]]["choices"]]):
            L = [len(x) for x in texts]
            order = sorted(set(L), reverse=True)
            out.append(f"r{order.index(L[k])} {L}")
        print(e["id"], "key", k, "| en", out[0], "| pt", out[1])


ABS = {"en": r"never|always|only|all|must|none|every|cannot|nothing|no one",
       "pt": r"nunca|jamais|sempre|somente|apenas|só|todo|toda|todos|todas|nenhum|nenhuma|nada|ninguém|deve|devem|não pode|não podem|impossível"}


def simulate(path_en):
    """Score the strategies check-exercises tries, per language, on quizzes."""
    import json, re
    en = json.load(open(path_en))
    pt = json.load(open(path_en.replace(".json", ".pt.json")))
    for lang in ("en", "pt"):
        A = re.compile(r"(?i)(?:^|[^\w])(?:" + ABS[lang] + r")(?:$|[^\w])")
        hits = {"longest": 0, "shortest": 0, "longest-clean": 0, "shortest-clean": 0, "second": 0}
        n = 0
        for e in en:
            if e["type"] != "quiz":
                continue
            texts = [c["text"] for c in e["choices"]] if lang == "en" else [c["text"] for c in pt[e["id"]]["choices"]]
            k = [i for i, c in enumerate(e["choices"]) if c.get("correct")][0]
            n += 1
            L = [len(t) for t in texts]
            idx = sorted(range(len(L)), key=lambda i: -L[i])
            if L[k] == max(L) and L.count(max(L)) == 1: hits["longest"] += 1
            if L[k] == min(L) and L.count(min(L)) == 1: hits["shortest"] += 1
            clean = [i for i in range(len(L)) if not A.search(texts[i])] or list(range(len(L)))
            lc = max(clean, key=lambda i: L[i]); sc = min(clean, key=lambda i: L[i])
            if lc == k: hits["longest-clean"] += 1
            if sc == k: hits["shortest-clean"] += 1
            if len(idx) > 1 and idx[1] == k and L[idx[0]] != L[idx[1]]: hits["second"] += 1
        print(lang, n, {s: f"{h}/{n}" for s, h in hits.items()}, "WARN" if max(hits.values()) > 0.45 * n else "")
