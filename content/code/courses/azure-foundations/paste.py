#!/usr/bin/env python3
"""Puts what a lesson's captures.sh printed into the lesson's prose. The author's, not the student's.

    bash lessons/<id>/captures.sh > /tmp/out.txt
    python3 paste.py lessons/<id> /tmp/out.txt           # rewrite the transcripts
    python3 paste.py lessons/<id> /tmp/out.txt --check   # say what differs, change nothing

The capture prints blocks, each opened by a line `##### <name>`. A transcript in
the prose is a plain fence whose first line is a prompt, `ana@laptop:...$ ...`.
The k-th fence starting with a given line, walking the sections in the order
lesson.json gives them, takes the k-th block starting with that same line. Both
languages get the same bytes, which is what validate-content demands anyway.

A FENCE THAT MATCHES NO BLOCK IS AN ERROR: it is a transcript nothing produced.
A block no fence uses is only listed, since a capture may record something the
prose describes rather than shows. Under --check a difference in the times a
transcript prints is not reported, since every run happens at another time.
"""
import json, os, re, sys

# A clock is not a finding: under --check, two transcripts that differ only in
# the times they print are the same transcript.
CLOCK = re.compile(r'\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d(\.\d+)?(Z|[+-]\d\d:?\d\d)?'
                   r'|\[\d\d/\w{3}/\d{4} \d\d:\d\d:\d\d\]')


def same(a, b):
    return CLOCK.sub('T', a) == CLOCK.sub('T', b)

FENCE = re.compile(r'^```\n(ana@laptop:[^\n]*)\n(.*?)^```$', re.S | re.M)


def blocks(path):
    out, name, lines = [], None, []
    for line in open(path, encoding='utf-8').read().split('\n'):
        if line.startswith('##### '):
            if name is not None:
                out.append((name, lines))
            name, lines = line[6:].strip(), []
        elif name is not None:
            lines.append(line)
    if name is not None:
        out.append((name, lines))
    result = []
    for name, lines in out:
        while lines and lines[-1] == '':
            lines.pop()
        if lines:
            result.append((name, '\n'.join(lines) + '\n'))
    return result


def main():
    lesson, capture = sys.argv[1], sys.argv[2]
    check = '--check' in sys.argv
    order = [s['slug'] for s in json.load(open(os.path.join(lesson, 'lesson.json')))['sections']]
    pool = {}
    for name, text in blocks(capture):
        pool.setdefault(text.split('\n', 1)[0], []).append([name, text, False])
    bad = 0
    for lang in ('', '.pt'):
        seen = {}
        for slug in order:
            path = os.path.join(lesson, f'{slug}{lang}.md')
            if not os.path.exists(path):
                continue
            src = open(path, encoding='utf-8').read()

            def swap(m):
                nonlocal bad
                first = m.group(1)
                k = seen.get(first, 0)
                seen[first] = k + 1
                cands = pool.get(first, [])
                if k >= len(cands):
                    print(f'{path}: no block for the fence starting {first!r} (occurrence {k + 1})')
                    bad += 1
                    return m.group(0)
                cands[k][2] = True
                new = '```\n' + cands[k][1] + '```'
                if check and same(new, m.group(0)):
                    return m.group(0)
                if new != m.group(0):
                    print(f'{path}: {"differs" if check else "rewrote"}: block {cands[k][0]}')
                    if check:
                        bad += 1
                return new

            new = FENCE.sub(swap, src)
            if new != src and not check:
                open(path, 'w', encoding='utf-8').write(new)
    for first, cands in pool.items():
        for name, _, used in cands:
            if not used:
                print(f'unused block {name}: {first}')
    sys.exit(1 if bad else 0)


main()
