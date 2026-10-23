"""q.py SOURCE OUT_JSON OUT_PT_JSON: write a lesson's questions, or the exam, in both languages.

The questions are written once, English and Portuguese line by line, in a
text file under lab/questions/. Each question opens with a line

    @ SECTION TYPE DIFFICULTY [nodrill] [#ex-xxxxxxxx]

(an exam question has no section: write `-`). The id is written into the
source the first time this runs, and never changed after: a student's answer
records it. Then, per line, the English and, doubled, the Portuguese:

    ? prompt            ?? enunciado
    ! hint              !! dica
    + right option :: why          ++ opção certa :: por quê
    - wrong option :: why          -- opção errada :: por quê
    > the next item of an ordering, in the right order     >> o item
    < left :: right   (a matching pair)                    << esquerda :: direita
    x a right-hand distractor of a matching                xx o distrator
    = accepted | answers of a cloze blank, or a numeric value
    == respostas | aceitas  (a cloze blank in Portuguese)
    ~ tolerance of a numeric (0 when absent)

A cloze has one `=` line per blank, in order, and the prompt writes each
blank as ___ (case and accents are ignored). Anything malformed is an error
that names the line.
"""
import json, os, random, re, subprocess, sys

ALPHABET = "0123456789abcdefghjkmnpqrstvwxyz"


def new_id(taken):
    while True:
        c = "ex-" + "".join(random.choice(ALPHABET) for _ in range(8))
        if c not in taken:
            taken.add(c)
            return c


def parse(path):
    qs, cur = [], None
    for n, raw in enumerate(open(path, encoding="utf-8").read().split("\n"), 1):
        line = raw.rstrip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^(@|\?\?|\?|!!|!|\+\+|\+|--|-|>>|>|<<|<|xx|x|==|=|~) ?(.*)$", line)
        if not m:
            sys.exit(f"{path}:{n}: cannot read {line!r}")
        k, v = m.group(1), m.group(2).strip()
        if k == "@":
            parts = v.split()
            q = {"line": n, "section": parts[0], "type": parts[1], "difficulty": parts[2],
                 "drill": "nodrill" not in parts, "id": next((p[1:] for p in parts if p.startswith("#")), None),
                 "en": {"choices": [], "items": [], "pairs": [], "dis": [], "blanks": []},
                 "pt": {"choices": [], "items": [], "pairs": [], "dis": [], "blanks": []}}
            qs.append(q); cur = q; continue
        if cur is None:
            sys.exit(f"{path}:{n}: a line before the first @")
        lang = "pt" if len(k) == 2 and k[0] == k[1] else "en"
        base = k[0]
        d = cur[lang]
        if base == "?": d["prompt"] = v
        elif base == "!": d["hint"] = v
        elif base in "+-":
            if " :: " not in v: sys.exit(f"{path}:{n}: an option needs ' :: why'")
            t, w = v.split(" :: ", 1)
            d["choices"].append({"text": t, "correct": base == "+", "why": w})
        elif base == ">": d["items"].append(v)
        elif base == "<":
            if " :: " not in v: sys.exit(f"{path}:{n}: a pair needs ' :: '")
            l, r = v.split(" :: ", 1); d["pairs"].append({"left": l, "right": r})
        elif base == "x": d["dis"].append(v)
        elif base == "=": d["blanks"].append([a.strip() for a in v.split("|")])
        elif base == "~": cur["tolerance"] = float(v)
    return qs


def build(q, path):
    en, pt, t = q["en"], q["pt"], q["type"]
    where = f"{path}:{q['line']}"
    out = {"id": q["id"], "version": 1}
    if q["section"] != "-":
        out["section"] = q["section"]
    out.update({"type": t, "difficulty": q["difficulty"]})
    out["drillable"] = q["drill"] if q["section"] != "-" else False
    if "prompt" not in en or "prompt" not in pt:
        sys.exit(f"{where}: a prompt in both languages")
    out["prompt"] = en["prompt"]
    tr = {"prompt": pt["prompt"]}
    if "hint" in en:
        out["hint"] = en["hint"]
        if "hint" not in pt: sys.exit(f"{where}: the hint has no Portuguese")
        tr["hint"] = pt["hint"]
    if t in ("quiz", "multiple-choice"):
        if len(en["choices"]) != len(pt["choices"]) or len(en["choices"]) < 3:
            sys.exit(f"{where}: {len(en['choices'])} options against {len(pt['choices'])} in Portuguese")
        for a, b in zip(en["choices"], pt["choices"]):
            if a["correct"] != b["correct"]: sys.exit(f"{where}: the languages disagree on which option is right")
        right = sum(c["correct"] for c in en["choices"])
        if t == "quiz" and right != 1: sys.exit(f"{where}: a quiz has one right option, this has {right}")
        out["choices"] = en["choices"]
        tr["choices"] = [{"text": c["text"], "why": c["why"]} for c in pt["choices"]]
    elif t == "ordering":
        if len(en["items"]) != len(pt["items"]) or len(en["items"]) < 3:
            sys.exit(f"{where}: an ordering of {len(en['items'])} items against {len(pt['items'])}")
        out["items"] = en["items"]; tr["items"] = pt["items"]
    elif t == "matching":
        if len(en["pairs"]) != len(pt["pairs"]) or len(en["dis"]) != len(pt["dis"]) or len(en["pairs"]) < 3:
            sys.exit(f"{where}: the pairs or distractors differ in number between the languages")
        out["pairs"] = en["pairs"]; tr["pairs"] = pt["pairs"]
        if en["dis"]:
            out["right_distractors"] = en["dis"]; tr["right_distractors"] = pt["dis"]
    elif t == "cloze":
        n = en["prompt"].count("___")
        if n != len(en["blanks"]) or pt["prompt"].count("___") != len(pt["blanks"]) or n != len(pt["blanks"]):
            sys.exit(f"{where}: the blanks and the ___ in the prompts do not agree")
        out["blanks"] = [{"accept": a, "ignore_case": True, "ignore_accents": True} for a in en["blanks"]]
        tr["blanks"] = [{"accept": a} for a in pt["blanks"]]
    elif t == "numeric":
        if len(en["blanks"]) != 1: sys.exit(f"{where}: a numeric needs one = value")
        v = float(en["blanks"][0][0])
        out["value"] = int(v) if v == int(v) else v
        tol = q.get("tolerance", 0)
        out["tolerance"] = int(tol) if tol == int(tol) else tol
    else:
        sys.exit(f"{where}: unknown type {t}")
    return out, tr


def main(src, out_json, out_pt):
    qs = parse(src)
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..")
    if any(q["id"] is None for q in qs):
        taken = set(subprocess.run(["grep", "-rhoE", r"\bex-[0-9a-z]{8}\b", os.path.join(root, "content")],
                                   capture_output=True, text=True).stdout.split())
        lines = open(src, encoding="utf-8").read().split("\n")
        for q in qs:
            if q["id"] is None:
                q["id"] = new_id(taken)
                lines[q["line"] - 1] = lines[q["line"] - 1].rstrip() + f" #{q['id']}"
        open(src, "w", encoding="utf-8").write("\n".join(lines))
    ids = [q["id"] for q in qs]
    if len(set(ids)) != len(ids):
        sys.exit(f"{src}: an id twice")
    en, pt = [], {}
    for q in qs:
        e, t = build(q, src)
        en.append(e); pt[q["id"]] = t
    json.dump(en, open(out_json, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(out_json, "a").write("\n")
    json.dump(pt, open(out_pt, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(out_pt, "a").write("\n")
    print(f"{out_json}: {len(en)} questions")


if __name__ == "__main__":
    main(*sys.argv[1:4])
