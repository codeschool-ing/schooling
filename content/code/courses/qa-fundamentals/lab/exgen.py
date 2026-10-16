#!/usr/bin/env python3
"""Write a lesson's exercises.json and exercises.pt.json from one source. THE AUTHOR'S.

Every question is written once, with each student-facing text as an
(English, Portuguese) pair, in lab/exercises/<lesson-id>.py (or exam.py), with
the builders in ex.py. A choice added in one language is then a choice added
in both, at the same position, which is how the loader joins them.

    python3 lab/exgen.py le-xxxxxxxx      # writes lessons/le-xxxxxxxx/exercises*.json
    python3 lab/exgen.py exam             # writes exam.json and exam.pt.json

A question written with the id 'ex-new' is given a fresh one first, and the
id is written back into the source: an id is written down, never worked out,
and this is only the pen. The key is written first in the source; the order
the student sees is a rotation chosen by the question's own id, so it is fixed
for as long as the id is and spread across the lesson.
"""
import importlib.util
import json
import os
import re
import secrets
import subprocess
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
COURSE = os.path.dirname(HERE)
REPO = os.path.abspath(os.path.join(COURSE, '..', '..', '..', '..'))
A = '0123456789abcdefghjkmnpqrstvwxyz'


def taken():
    out = subprocess.run(['git', '-C', REPO, 'grep', '-ohE', r'ex-[0-9a-z]{8}'],
                         capture_output=True, text=True).stdout.split()
    s = set(out)
    for root, _, files in os.walk(COURSE):
        for f in files:
            if f.endswith(('.py', '.json')):
                s |= set(re.findall(r'ex-[0-9a-z]{8}', open(os.path.join(root, f)).read()))
    return s


def assign(src):
    text = open(src, encoding='utf-8').read()
    if "'ex-new'" not in text:
        return
    seen = taken()

    def fresh(_):
        while True:
            i = 'ex-' + ''.join(secrets.choice(A) for _ in range(8))
            if i not in seen:
                seen.add(i)
                return repr(i)
    open(src, 'w', encoding='utf-8').write(re.sub(r"'ex-new'", fresh, text))


def rotate(q):
    cs = q['choices']
    if q['type'] != 'quiz':
        return cs
    k = sum(A.index(c) for c in q['id'][3:]) % len(cs)
    return cs[k:] + cs[:k]


def build(qs, exam):
    en, pt = [], {}
    for q in qs:
        e = {'id': q['id'], 'version': 1}
        if not exam:
            e['section'] = q['section']
        e['type'] = q['type']
        e['difficulty'] = q['difficulty']
        if not exam:
            e['drillable'] = True
        e['prompt'] = q['prompt'][0]
        e['hint'] = q['hint'][0]
        t = {'prompt': q['prompt'][1], 'hint': q['hint'][1]}
        k = q['type']
        if k in ('quiz', 'multiple-choice'):
            cs = rotate(q)
            e['choices'] = [{'text': c['en'], 'correct': c['ok'], 'why': c['why_en']} for c in cs]
            t['choices'] = [{'text': c['pt'], 'why': c['why_pt']} for c in cs]
        elif k == 'numeric':
            e['value'], e['tolerance'], e['unit'] = q['value'], q['tolerance'], q['unit'][0]
            t['unit'] = q['unit'][1]
        elif k == 'cloze':
            e['blanks'] = [{'accept': q['accept'][0], 'ignore_case': q['ignore_case'],
                            'ignore_accents': True}]
            t['blanks'] = [{'accept': q['accept'][1]}]
        elif k == 'ordering':
            e['items'] = [i[0] for i in q['items']]
            e['trap'] = q['trap'][0]
            t['items'] = [i[1] for i in q['items']]
            t['trap'] = q['trap'][1]
        elif k == 'matching':
            e['pairs'] = [{'left': l[0], 'right': r[0]} for l, r in q['pairs']]
            t['pairs'] = [{'left': l[1], 'right': r[1]} for l, r in q['pairs']]
        en.append(e)
        pt[q['id']] = t
    ids = [q['id'] for q in qs]
    if len(set(ids)) != len(ids):
        sys.exit('a question id is used twice')
    return en, pt


def main():
    which = sys.argv[1]
    src = os.path.join(HERE, 'exercises', which + '.py')
    assign(src)
    sys.path.insert(0, HERE)
    spec = importlib.util.spec_from_file_location('src', src)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    exam = which == 'exam'
    en, pt = build(mod.QUESTIONS, exam)
    out = COURSE if exam else os.path.join(COURSE, 'lessons', which)
    base = 'exam' if exam else 'exercises'
    with open(os.path.join(out, base + '.json'), 'w', encoding='utf-8') as f:
        json.dump(en, f, indent=2, ensure_ascii=False)
        f.write('\n')
    with open(os.path.join(out, base + '.pt.json'), 'w', encoding='utf-8') as f:
        json.dump(pt, f, indent=2, ensure_ascii=False)
        f.write('\n')
    print(f'{which}: {len(en)} questions')


main()
