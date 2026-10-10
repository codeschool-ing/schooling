#!/usr/bin/env python3
"""Where the correct option sits by length, per question and per language. THE AUTHOR'S.

check-exercises refuses a lesson where the key lands on one length rank in more
than 45% of its questions. This prints the rank of every single-answer key (1 is
the longest) in both languages, and the share at each rank, so a rewrite can aim
at the questions that make the share rather than at the ones that happen to be
read first.

    python3 lab/ranks.py le-xxxxxxxx | exam
"""
import collections
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
COURSE = os.path.dirname(HERE)
which = sys.argv[1]
base = COURSE if which == 'exam' else os.path.join(COURSE, 'lessons', which)
name = 'exam' if which == 'exam' else 'exercises'
en = json.load(open(os.path.join(base, name + '.json'), encoding='utf-8'))
pt = json.load(open(os.path.join(base, name + '.pt.json'), encoding='utf-8'))
share = {'en': collections.Counter(), 'pt': collections.Counter()}
rows = []
for q in en:
    if q['type'] not in ('quiz',) or sum(c['correct'] for c in q['choices']) != 1:
        continue
    k = next(i for i, c in enumerate(q['choices']) if c['correct'])
    out = []
    for lang, texts in (('en', [c['text'] for c in q['choices']]),
                        ('pt', [c['text'] for c in pt[q['id']]['choices']])):
        ls = [len(t) for t in texts]
        if len(set(ls)) == 1:
            out.append('=')
            continue
        rank = sorted(set(ls), reverse=True).index(ls[k]) + 1
        if ls.count(ls[k]) > 1:
            out.append('t')
            continue
        share[lang][rank] += 1
        out.append(str(rank))
    rows.append((q['id'], q.get('section', ''), out, k))
for i, s, o, k in rows:
    print(f'{i}  {s:24} en {o[0]}  pt {o[1]}  pos {k + 1}')
for lang in ('en', 'pt'):
    n = sum(share[lang].values())
    print(lang, ' '.join(f'r{r}:{c} ({100 * c // n}%)' for r, c in sorted(share[lang].items())), f'of {n}')
