#!/usr/bin/env python3
"""Where the key sits by length, per question and language. THE AUTHOR'S.

    python3 lab/ranks.py le-xxxxxxxx      (or exam)

check-exercises refuses a lesson where the key lands on one length rank in
more than 45% of its questions; this prints the rank of each so the writing
can be fixed where it happens. Rank 1 is the longest; `=` is a tie.
"""
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
COURSE = os.path.dirname(HERE)
w = sys.argv[1]
base = COURSE if w == 'exam' else os.path.join(COURSE, 'lessons', w)
name = 'exam' if w == 'exam' else 'exercises'
en = json.load(open(os.path.join(base, name + '.json')))
pt = json.load(open(os.path.join(base, name + '.pt.json')))
HEDGE = re.compile(r'\b(usually|often|can|may|tends?|generally|sometimes|typically|might|could|geralmente|normalmente|pode|podem|costuma|costumam|às vezes|tende|tendem)\b', re.I)
tot = {'en': collections.Counter(), 'pt': collections.Counter()}
for q in en:
    if q['type'] != 'quiz':
        continue
    row = [q['id']]
    for lang in ('en', 'pt'):
        texts = [c['text'] for c in q['choices']] if lang == 'en' else [c['text'] for c in pt[q['id']]['choices']]
        k = [c['correct'] for c in q['choices']].index(True)
        ls = [len(t) for t in texts]
        if len(set(ls)) == 1:
            r = '='
        else:
            r = 1 + sum(1 for l in ls if l > ls[k])
            if ls.count(ls[k]) > 1:
                r = f'{r}='
        tot[lang][str(r)] += 1
        h = [i for i, t in enumerate(texts) if HEDGE.search(t)]
        row.append(f'{lang}:{r}' + (f' hedge{h}' if h else ''))
    row.append(f'pos {k}')
    print('  '.join(row))
for lang in tot:
    n = sum(tot[lang].values())
    print(lang, ' '.join(f'r{k}={v}({100*v//n}%)' for k, v in sorted(tot[lang].items())))
