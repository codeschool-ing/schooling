#!/usr/bin/env python3
"""blocks.py LESSON_DIR SPEC.py

Writes the figures and the annotated examples of one lesson into its .md and
.pt.md files, from SPEC.py (lab/figures/lNN.py):

  def figures(lang) -> {name: Fig-json}     lang is "en" or "pt"
  EXAMPLES = {"first-flaw": [ {"language": ..., "file": ..., "output": ...,
                               "parts": [(code, note_en, note_pt), ...]}, ...]}

A schooling-figure fence whose body is `@@fig NAME@@`, or whose svg carries
data-fig="NAME", becomes figure NAME in the file's language. The Kth
schooling-example fence of SECTION.md and of SECTION.pt.md becomes the Kth
example listed for SECTION: same code, notes in the file's language. So the
code of a translation is the English code by construction."""
import importlib.util, json, pathlib, re, sys

lesson, src = pathlib.Path(sys.argv[1]), sys.argv[2]
sys.path.insert(0, str(pathlib.Path(__file__).parent))
spec = importlib.util.spec_from_file_location("spec", src)
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
figs = {"en": mod.figures("en"), "pt": mod.figures("pt")} if hasattr(mod, "figures") else {"en": {}, "pt": {}}
examples = getattr(mod, "EXAMPLES", {})
FIG = re.compile(r"^```schooling-figure\n(.*?)\n^```[ \t]*$", re.S | re.M)
EXF = re.compile(r"^```schooling-example\n(.*?)\n^```[ \t]*$", re.S | re.M)
used, bad = set(), 0


def example(e, lang):
    d = {"language": e["language"]}
    if e.get("file"):
        d["file"] = e["file"]
    parts = []
    for p in e["parts"]:
        code, note = p[0], (p[1] if lang == "en" else p[2])
        parts.append({"code": code, "note": note} if note else {"code": code})
    d["parts"] = parts
    if e.get("output"):
        d["output"] = e["output"]
    return json.dumps(d, ensure_ascii=False)


for md in sorted(lesson.glob("*.md")):
    lang = "pt" if md.name.endswith(".pt.md") else "en"
    section = md.name[: -len(".pt.md")] if lang == "pt" else md.name[: -len(".md")]
    text = md.read_text(encoding="utf-8")

    def fig(m):
        global bad
        body = m.group(1)
        ph = re.fullmatch(r"@@fig (.+?)@@", body.strip())
        hit = re.search(r'data-fig=\\"([^"\\]+)\\"', body)
        name = ph.group(1) if ph else (hit.group(1) if hit else None)
        if name in figs[lang]:
            used.add(name)
            return "```schooling-figure\n" + figs[lang][name] + "\n```"
        if ph:
            print(f"{md.name}: no figure {name}"); bad += 1
        return m.group(0)

    k = [0]
    def exm(m):
        global bad
        mine = examples.get(section, [])
        i = k[0]; k[0] += 1
        if i < len(mine):
            return "```schooling-example\n" + example(mine[i], lang) + "\n```"
        print(f"{md.name}: example {i + 1} has no entry in the spec"); bad += 1
        return m.group(0)

    new = EXF.sub(exm, FIG.sub(fig, text))
    if k[0] != len(examples.get(section, [])) and section in examples:
        print(f"{md.name}: {k[0]} example fences, spec lists {len(examples[section])}"); bad += 1
    if new != text:
        md.write_text(new, encoding="utf-8")
for n in figs["en"]:
    if n not in used:
        print(f"figure {n} is placed in no file"); bad += 1
sys.exit(1 if bad else 0)
