#!/usr/bin/env python3
"""Every question in the people-leadership course, written once in both languages.

    python3 questions.py            # rewrite every exercises.json, exercises.pt.json and the exam
    python3 questions.py --report   # and print where the key sits by length, per lesson and language

The questions live in qs/, one file per lesson plus qs/exam.py. Each call there
carries the English and the Portuguese side by side, so a translation cannot be
written for a question that changed underneath it without somebody seeing both.

An id is written in the file. A call written with the id 'NEW' is given a fresh
one the first time this runs, and the id is written back into the source — so
it is chosen once and never worked out again.

The key is written first in every list of choices, because that is the easiest
way to write a question. Where it ends up in the file is decided here, from the
id, so the position is not a habit of the person writing. Nothing reads that
order later: what reaches the catalogue is the JSON this writes.

Standard library only.
"""
import hashlib
import json
import os
import re
import secrets
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ALPHABET = '0123456789abcdefghjkmnpqrstvwxyz'

LESSON = None        # the lesson id the calls below are filed under; None is the exam
COLLECTED = {}       # lesson id (or 'exam') -> list of (english, portuguese)


def lesson(lid):
    global LESSON
    LESSON = lid
    COLLECTED.setdefault(lid, [])


def exam():
    global LESSON
    LESSON = 'exam'
    COLLECTED.setdefault('exam', [])


def _order(qid, n):
    """A permutation of range(n) chosen by the id: the same id always lands the same way."""
    h = hashlib.sha256(qid.encode()).digest()
    idx = list(range(n))
    out = []
    k = 0
    while idx:
        out.append(idx.pop(h[k % len(h)] % len(idx)))
        k += 1
    return out


def _base(qid, sec, diff, kind, prompt, hint):
    en = {'id': qid, 'version': 1}
    if LESSON != 'exam':
        en['section'] = sec
    en.update({'type': kind, 'difficulty': diff,
               'drillable': LESSON != 'exam', 'prompt': prompt[0]})
    pt = {'prompt': prompt[1]}
    if hint:
        en['hint'], pt['hint'] = hint[0], hint[1]
    return en, pt


def _choices(qid, choices, single):
    keys = [c for c in choices if c[0]]
    if single and len(keys) != 1:
        raise SystemExit(f'{qid}: a quiz has exactly one key, this one has {len(keys)}')
    if single:
        # the key goes to a position picked by the id, the rest keep their written order
        n = len(choices)
        at = _order(qid, n)[0]
        rest = [c for c in choices if not c[0]]
        arranged = rest[:at] + [keys[0]] + rest[at:]
    else:
        arranged = [choices[i] for i in _order(qid, len(choices))]
    en = [{'text': c[1], 'correct': bool(c[0]), 'why': c[2]} for c in arranged]
    pt = [{'text': c[3], 'why': c[4]} for c in arranged]
    return en, pt


def quiz(qid, sec, diff, prompt, hint, choices):
    en, pt = _base(qid, sec, diff, 'quiz', prompt, hint)
    en['choices'], pt['choices'] = _choices(qid, choices, True)
    COLLECTED[LESSON].append((en, pt))


def mc(qid, sec, diff, prompt, hint, choices):
    en, pt = _base(qid, sec, diff, 'multiple-choice', prompt, hint)
    en['choices'], pt['choices'] = _choices(qid, choices, False)
    COLLECTED[LESSON].append((en, pt))


def order(qid, sec, diff, prompt, hint, items, trap=None):
    en, pt = _base(qid, sec, diff, 'ordering', prompt, hint)
    en['items'] = [i[0] for i in items]
    pt['items'] = [i[1] for i in items]
    if trap:
        en['trap'], pt['trap'] = trap
    COLLECTED[LESSON].append((en, pt))


def match(qid, sec, diff, prompt, hint, pairs, distract=()):
    en, pt = _base(qid, sec, diff, 'matching', prompt, hint)
    en['pairs'] = [{'left': p[0], 'right': p[1]} for p in pairs]
    pt['pairs'] = [{'left': p[2], 'right': p[3]} for p in pairs]
    if distract:
        en['right_distractors'] = [d[0] for d in distract]
        pt['right_distractors'] = [d[1] for d in distract]
    COLLECTED[LESSON].append((en, pt))


def cloze(qid, sec, diff, prompt, hint, accepts):
    en, pt = _base(qid, sec, diff, 'cloze', prompt, hint)
    for side, text in (('en', prompt[0]), ('pt', prompt[1])):
        if text.count('___') != len(accepts):
            raise SystemExit(f'{qid}: {len(accepts)} blanks and {text.count("___")} holes in {side}')
    en['blanks'] = [{'accept': a[0], 'ignore_case': True, 'ignore_accents': True} for a in accepts]
    pt['blanks'] = [{'accept': a[1]} for a in accepts]
    COLLECTED[LESSON].append((en, pt))


def num(qid, sec, diff, prompt, hint, value, tolerance, unit, units=None):
    en, pt = _base(qid, sec, diff, 'numeric', prompt, hint)
    en.update({'value': value, 'tolerance': tolerance, 'unit': unit[0]})
    pt['unit'] = unit[1]
    if units:
        en['accept_units'], pt['accept_units'] = units
    COLLECTED[LESSON].append((en, pt))


# --------------------------------------------------------------- ids

def _taken():
    out = subprocess.run(['git', 'grep', '-h', '-o', '-E', r'ex-[0-9a-z]{8}'], cwd=HERE,
                         capture_output=True, text=True).stdout
    return set(out.split())


def _assign(path, taken):
    src = open(path, encoding='utf-8').read()
    if "'NEW'" not in src:
        return
    def fresh(_):
        while True:
            i = 'ex-' + ''.join(secrets.choice(ALPHABET) for _ in range(8))
            if i not in taken:
                taken.add(i)
                return repr(i)
    open(path, 'w', encoding='utf-8').write(re.sub(r"'NEW'", fresh, src))


# --------------------------------------------------------------- writing

def _dump(obj, path):
    text = json.dumps(obj, ensure_ascii=False, indent=2) + '\n'
    if not os.path.exists(path) or open(path, encoding='utf-8').read() != text:
        open(path, 'w', encoding='utf-8').write(text)
        return 1
    return 0


def _slugs(lid):
    with open(os.path.join(HERE, 'lessons', lid, 'lesson.json')) as f:
        return {s['slug'] for s in json.load(f)['sections']}


def _rank(choices, key):
    lens = sorted({len(c['text']) for c in choices}, reverse=True)
    if len(lens) < 2:
        return None
    return lens.index(len(choices[key]['text']))


def report(lid, items):
    for side in (0, 1):
        ranks, n = {}, 0
        for en, pt in items:
            if en['type'] != 'quiz':
                continue
            cs = en['choices'] if side == 0 else [dict(c, correct=e['correct']) for c, e in
                                                  zip(pt['choices'], en['choices'])]
            key = [i for i, c in enumerate(en['choices']) if c['correct']][0]
            r = _rank(cs, key)
            if r is None:
                continue
            n += 1
            ranks[r] = ranks.get(r, 0) + 1
            if '--detail' in sys.argv:
                print(f'   {"en" if side == 0 else "pt"} {en["id"]} rank {r} key {len(cs[key]["text"])} '
                      f'others {sorted(len(c["text"]) for i, c in enumerate(cs) if i != key)}')
        worst = max(ranks.values()) / n if n else 0
        flag = '  <-- over 45%' if worst > 0.45 else ''
        print(f'{lid} [{"en" if side == 0 else "pt"}] {n} quizzes, key by length rank '
              f'{dict(sorted(ranks.items()))}{flag}')


def main():
    import importlib
    sys.path.insert(0, HERE)
    files = sorted(f for f in os.listdir(os.path.join(HERE, 'qs')) if f.endswith('.py')
                   and f != '__init__.py')
    taken = _taken()
    for f in files:
        _assign(os.path.join(HERE, 'qs', f), taken)
    for f in files:
        importlib.import_module('qs.' + f[:-3])
    seen, changed = set(), 0
    for lid, items in COLLECTED.items():
        for en, _ in items:
            if en['id'] in seen:
                raise SystemExit(f'{en["id"]} is written twice')
            seen.add(en['id'])
        if lid == 'exam':
            changed += _dump([e for e, _ in items], os.path.join(HERE, 'exam.json'))
            changed += _dump({e['id']: p for e, p in items}, os.path.join(HERE, 'exam.pt.json'))
        else:
            slugs = _slugs(lid)
            for en, _ in items:
                if en['section'] not in slugs:
                    raise SystemExit(f'{en["id"]}: no section {en["section"]} in {lid}')
            d = os.path.join(HERE, 'lessons', lid)
            changed += _dump([e for e, _ in items], os.path.join(d, 'exercises.json'))
            changed += _dump({e['id']: p for e, p in items}, os.path.join(d, 'exercises.pt.json'))
        if '--report' in sys.argv:
            report(lid, items)
    total = sum(len(v) for k, v in COLLECTED.items() if k != 'exam')
    print(f'{total} lesson questions, {len(COLLECTED.get("exam", []))} in the exam, '
          f'{changed} files rewritten')


sys.modules.setdefault('questions', sys.modules[__name__])
sys.dont_write_bytecode = True

if __name__ == '__main__':
    main()
