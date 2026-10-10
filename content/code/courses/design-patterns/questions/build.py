#!/usr/bin/env python3
"""The questions of design-patterns, written once with both languages side by side.

    python3 build.py lNN.py ../lessons/le-xxxx/exercises
    python3 build.py exam.py ../exam exam

One file per lesson here holds every question with its English and its
Portuguese next to each other, which is what keeps the two lists the same
length and in the same order. The JSON beside each lesson is written from it;
edit here, not there.

usage: build.py SPEC.py OUT_PREFIX

SPEC.py defines EXERCISES, a list of dicts. Every text a student reads is a
pair (en, pt). OUT_PREFIX is e.g. .../le-xxxx/exercises or .../exam, and the
script writes OUT_PREFIX.json and OUT_PREFIX.pt.json.

  dict(id='ex-...', section='slug', type='quiz', difficulty='easy',
       prompt=(en, pt), hint=(en, pt),                       # hint optional
       choices=[(True, (en, pt), (why_en, why_pt)), (False, ...), ...])
  type='multiple-choice'  same as quiz, several True
  type='ordering'   items=[(en, pt), ...] in the right order, trap=(en, pt)
  type='matching'   pairs=[((l_en, l_pt), (r_en, r_pt)), ...],
                    right_distractors=[(en, pt), ...]   optional
  type='cloze'      blanks=[dict(en=[...], pt=[...], case=False)]  # case=True
                    keeps ignore_case false
  type='numeric'    value=..., tolerance=0, unit=(en, pt)
  drillable defaults to True (False is forced for an exam: pass exam=True
  on the command line as a third argument).
"""
import json, runpy, sys
spec, out = sys.argv[1], sys.argv[2]
exam = len(sys.argv) > 3 and sys.argv[3] == 'exam'
E = runpy.run_path(spec)['EXERCISES']
en_all, pt_all, seen = [], {}, set()
for x in E:
    assert x['id'] not in seen, x['id']; seen.add(x['id'])
    e = {'id': x['id'], 'version': 1}
    if not exam:
        e['section'] = x['section']
    e.update(type=x['type'], difficulty=x['difficulty'],
             drillable=False if exam else x.get('drillable', True),
             prompt=x['prompt'][0])
    p = {'prompt': x['prompt'][1]}
    if 'hint' in x:
        e['hint'], p['hint'] = x['hint']
    t = x['type']
    if t in ('quiz', 'multiple-choice'):
        e['choices'] = [{'text': c[1][0], 'correct': c[0], 'why': c[2][0]} for c in x['choices']]
        p['choices'] = [{'text': c[1][1], 'why': c[2][1]} for c in x['choices']]
        n = sum(c[0] for c in x['choices'])
        assert (n == 1) if t == 'quiz' else (n >= 1), (x['id'], n)
    elif t == 'ordering':
        e['items'] = [i[0] for i in x['items']]; p['items'] = [i[1] for i in x['items']]
        if 'trap' in x:
            e['trap'], p['trap'] = x['trap']
    elif t == 'matching':
        e['pairs'] = [{'left': a[0], 'right': b[0]} for a, b in x['pairs']]
        p['pairs'] = [{'left': a[1], 'right': b[1]} for a, b in x['pairs']]
        if x.get('right_distractors'):
            e['right_distractors'] = [d[0] for d in x['right_distractors']]
            p['right_distractors'] = [d[1] for d in x['right_distractors']]
    elif t == 'cloze':
        e['blanks'] = [{'accept': b['en'], 'ignore_case': not b.get('case', False),
                        'ignore_accents': True} for b in x['blanks']]
        p['blanks'] = [{'accept': b['pt']} for b in x['blanks']]
        assert x['prompt'][0].count('___') == len(x['blanks']) == x['prompt'][1].count('___'), x['id']
    elif t == 'numeric':
        e['value'] = x['value']; e['tolerance'] = x.get('tolerance', 0)
        if 'unit' in x:
            e['unit'], p['unit'] = x['unit']
    else:
        raise SystemExit(f'unknown type {t}')
    en_all.append(e); pt_all[x['id']] = p
json.dump(en_all, open(out + '.json', 'w'), indent=1, ensure_ascii=False); open(out + '.json', 'a').write('\n')
json.dump(pt_all, open(out + '.pt.json', 'w'), indent=1, ensure_ascii=False); open(out + '.pt.json', 'a').write('\n')
print(len(en_all), 'exercises ->', out)
