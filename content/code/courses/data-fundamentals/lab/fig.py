#!/usr/bin/env python3
"""Draw every figure of data-fundamentals into the lessons. THE AUTHOR'S.

Each lesson's figures are described in lab/figures/<lesson-id>.py, which
defines FIGURES, a list of svg.Fig. A figure enters a section as a line
`@@fig:<name>@@` in both the .md and the .pt.md; once drawn, the fence carries
data-fig="<name>" and is found and redrawn the same way on every later run.

    python3 lab/fig.py              # every lesson
    python3 lab/fig.py le-xxxxxxxx  # one lesson
"""
import sys
sys.dont_write_bytecode = True
import glob
import importlib.util
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
COURSE = os.path.dirname(HERE)
sys.path.insert(0, HERE)


def load(path):
    spec = importlib.util.spec_from_file_location(os.path.basename(path)[:-3], path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.FIGURES


def main():
    only = sys.argv[1:]
    bad = 0
    for path in sorted(glob.glob(os.path.join(HERE, 'figures', 'le-*.py'))):
        lesson = os.path.basename(path)[:-3]
        if only and lesson not in only:
            continue
        figs = {f.name: f for f in load(path)}
        placed = set()
        for md in sorted(glob.glob(os.path.join(COURSE, 'lessons', lesson, '*.md'))):
            lang = 'pt' if md.endswith('.pt.md') else 'en'
            text = open(md, encoding='utf-8').read()
            new = text
            for name, f in figs.items():
                fence = f.fence(lang)
                pat_fence = re.compile(r'```schooling-figure\n[^\n]*data-fig=\\"' + re.escape(name) +
                                       r'\\"[^\n]*\n```')
                new, n1 = pat_fence.subn(lambda m: fence, new)
                new, n2 = re.subn(r'^@@fig:' + re.escape(name) + r'@@$', lambda m: fence, new,
                                  flags=re.M)
                if n1 + n2:
                    placed.add((name, lang))
            left = re.findall(r'@@fig:([\w-]+)@@', new)
            for name in left:
                print(f'{md}: @@fig:{name}@@ names no figure in {os.path.basename(path)}')
                bad += 1
            if new != text:
                open(md, 'w', encoding='utf-8').write(new)
        for name in figs:
            for lang in ('en', 'pt'):
                if (name, lang) not in placed:
                    print(f'{lesson}: figure {name} is placed in no {lang} section')
                    bad += 1
    sys.exit(1 if bad else 0)


main()
