#!/usr/bin/env python3
"""Every concept diagram in python-data, written into the lessons from the code that draws it.

THE STUDENT NEVER SEES THIS FILE.

    python3 figures.py          rewrite every figure, in both languages
    python3 figures.py --check  exit 1 if any lesson holds a figure other than what is drawn now

Each `figs/<lesson id>.py` defines `FIGURES`, a list of `draw.Fig`. A figure enters a section as a
line `@@figure:<name>@@`, and afterwards it is found again by the `data-fig="<name>"` its SVG
carries, in the .md and the .pt.md alike. A name drawn and placed nowhere is an error, and so is a
marker or a figure in a lesson that nothing draws.

Standard library only.
"""
import glob
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "figs"))
FENCE = re.compile(r"^```schooling-figure\n(.*?)\n```\n", re.S | re.M)
MARK = re.compile(r"^@@figure:(\S+?)@@\n", re.M)


def drawn(lesson_id):
    path = os.path.join(HERE, "figs", lesson_id + ".py")
    if not os.path.exists(path):
        return {}
    spec = importlib.util.spec_from_file_location("figs_" + lesson_id.replace("-", "_"), path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return {f.name: f for f in mod.FIGURES}


def main():
    check = "--check" in sys.argv
    problems = 0
    for lesson in sorted(glob.glob(os.path.join(HERE, "lessons", "*"))):
        figs = drawn(os.path.basename(lesson))
        placed = set()
        for md in sorted(glob.glob(os.path.join(lesson, "*.md"))):
            lang = "pt" if md.endswith(".pt.md") else "en"
            text = open(md, encoding="utf-8").read()

            def by_mark(m):
                name = m.group(1)
                if name not in figs:
                    raise SystemExit(f"{md}: @@figure:{name}@@ and nothing draws it")
                placed.add(name)
                return figs[name].fence(lang)

            def by_fence(m):
                svg = json.loads(m.group(1)).get("svg", "")
                found = re.search(r'data-fig="([^"]+)"', svg)
                if not found or found.group(1) not in figs:
                    raise SystemExit(f"{md}: a figure nothing in figs/ draws")
                placed.add(found.group(1))
                return figs[found.group(1)].fence(lang)

            new = MARK.sub(by_mark, FENCE.sub(by_fence, text))
            if new != text:
                if check:
                    problems += 1
                    print(f"{md}: a figure differs from what figs/ draws now")
                else:
                    open(md, "w", encoding="utf-8").write(new)
                    print("wrote", md)
        for name in figs:
            if name not in placed:
                problems += 1
                print(f"{os.path.basename(lesson)}: {name} is drawn and placed nowhere")
    sys.exit(1 if problems else 0)


main()
