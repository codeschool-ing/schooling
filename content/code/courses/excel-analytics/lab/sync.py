#!/usr/bin/env python3
"""Makes every Portuguese section carry the English section's code.

    python3 sync.py            # every lesson
    python3 sync.py le-xxxx    # one lesson

For each `.pt.md`, fence N is set from fence N of the `.md`:

- a `localised` fence is the English formula spelled as a Brazilian Excel
  spells it (ptformula.py);
- a `schooling-figure` is redrawn from lab/figs in each language, wherever the
  fence's SVG carries a `data-fig` that a figure module defines;
- a `schooling-example` keeps the Portuguese notes and takes the English code;
- every other fence is the English fence, byte for byte.

A different number of fences in the two files is a refusal: it means a fence
was added in one language, and pairing them by position would then put every
later block in the wrong place.
"""
import glob
import importlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fig import T  # noqa: E402
from ptformula import block_to_pt  # noqa: E402

LESSONS = os.path.join(os.path.dirname(HERE), "lessons")
FENCE = re.compile(r"^```([^\n`]*)\n(.*?)\n```$", re.S | re.M)


def number(lesson):
    """A lesson's position in the course, from the topics of course.json, so
    that lesson le-… draws its figures from figs/lNN.py."""
    topics = json.load(open(os.path.join(os.path.dirname(HERE), "course.json")))["topics"]
    return [t["id"] for t in topics].index(lesson) + 1


def figures(only=None):
    out = {}
    paths = sorted(glob.glob(os.path.join(HERE, "figs", "l*.py")))
    if only:
        want = {f"l{number(l):02d}.py" for l in only}
        paths = [p for p in paths if os.path.basename(p) in want]
    for path in paths:
        name = os.path.basename(path)[:-3]
        mod = importlib.import_module(f"figs.{name}")
        for k, fn in mod.FIGS.items():
            if k in out:
                raise SystemExit(f"figure {k} defined twice")
            out[k] = fn
    return out


def figure_json(fn, lang):
    s, caption = fn(T(lang))
    block = {"svg": s.svg(), "caption": caption}
    if lang == "pt":
        en, _ = fn(T("en"))
        same = sorted({p for e, p in zip(en.sans_labels, s.sans_labels) if e == p and re.search(r"[^\W\d_]", p)})
        if same:
            block["same"] = same
    return json.dumps(block, ensure_ascii=False)


def refresh_figures(text, figs, lang):
    def sub(m):
        label, body = m.group(1), m.group(2)
        if label != "schooling-figure":
            return m.group(0)
        name = re.search(r'data-fig=\\?"([^"\\]+)', body)
        if not name or name.group(1) not in figs:
            return m.group(0)
        return "```schooling-figure\n" + figure_json(figs[name.group(1)], lang) + "\n```"
    return FENCE.sub(sub, text)


def sync_pair(en_path, pt_path, figs):
    en = refresh_figures(open(en_path, encoding="utf-8").read(), figs, "en")
    open(en_path, "w", encoding="utf-8").write(en)
    if not os.path.exists(pt_path):
        return
    pt = open(pt_path, encoding="utf-8").read()
    ef, pf = list(FENCE.finditer(en)), list(FENCE.finditer(pt))
    if len(ef) != len(pf):
        raise SystemExit(f"{pt_path}: {len(pf)} fences against {len(ef)} in English")
    out, last = [], 0
    for e, p in zip(ef, pf):
        out.append(pt[last:p.start()])
        label, body = e.group(1), e.group(2)
        if label == "localised":
            out.append("```localised\n" + block_to_pt(body) + "\n```")
        elif label == "schooling-figure":
            out.append(p.group(0))
        elif label == "schooling-example":
            eb, pb = json.loads(body), json.loads(p.group(2))
            if len(eb["parts"]) != len(pb["parts"]):
                raise SystemExit(f"{pt_path}: an example with a different number of parts")
            for ep, pp in zip(eb["parts"], pb["parts"]):
                pp["code"] = ep["code"]
            for k in ("language", "file", "output"):
                if k in eb:
                    pb[k] = eb[k]
            out.append("```schooling-example\n" + json.dumps(pb, ensure_ascii=False) + "\n```")
        else:
            out.append(e.group(0))
        last = p.end()
    out.append(pt[last:])
    pt = refresh_figures("".join(out), figs, "pt")
    open(pt_path, "w", encoding="utf-8").write(pt)


def main(only):
    figs = figures(only)
    for d in sorted(glob.glob(os.path.join(LESSONS, "le-*"))):
        if only and os.path.basename(d) not in only:
            continue
        for en in sorted(glob.glob(os.path.join(d, "*.md"))):
            if en.endswith(".pt.md"):
                continue
            sync_pair(en, en[:-3] + ".pt.md", figs)


if __name__ == "__main__":
    main(sys.argv[1:])
