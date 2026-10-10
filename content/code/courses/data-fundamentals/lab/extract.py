#!/usr/bin/env python3
"""Write out every program a lesson shows, exactly as the lesson shows it.

THE AUTHOR'S, NOT THE STUDENT'S. A capture has to run the program the student
reads, so the program is read out of the lesson rather than kept beside it:

  - an ordinary fence whose first line is a comment naming a file
    (`# trips.py`, `-- rides.sql`) is that file, first line included;
  - a `schooling-example` with a "file" is that file, its parts joined in
    order, which is what the copy button hands over.

    python3 lab/extract.py OUTDIR lessons/<id>/*.md

A name found twice with different contents is an error: two sections showing
two versions of one file would leave the capture running whichever came last.
English files only; a translation's fences are the English ones byte for byte,
which validate-content checks.
"""
import json
import os
import re
import sys

NAME = re.compile(r'^(?:#|--) ([\w./-]+\.(?:py|sql|sh|json|csv|txt|log))\s*$')


def fences(text):
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        m = re.match(r'^(`{3,})(.*)$', lines[i])
        if not m:
            i += 1
            continue
        tick, info = m.group(1), m.group(2).strip()
        body = []
        i += 1
        while i < len(lines) and lines[i] != tick:
            body.append(lines[i])
            i += 1
        i += 1
        yield info, '\n'.join(body)


def files(path):
    text = open(path, encoding='utf-8').read()
    for info, body in fences(text):
        if info == 'schooling-example':
            block = json.loads(body)
            if block.get('file'):
                code = ''.join(p['code'] if p['code'].endswith('\n') else p['code'] + '\n'
                               for p in block['parts'])
                yield block['file'], code
            continue
        first = body.split('\n', 1)[0]
        m = NAME.match(first)
        if m and info in ('python', 'py', 'sql', 'sh', 'json', ''):
            yield m.group(1), body + '\n'


def main():
    out, paths = sys.argv[1], sys.argv[2:]
    seen = {}
    for p in paths:
        if p.endswith('.pt.md'):
            continue
        for name, code in files(p):
            if name in seen and seen[name][1] != code:
                sys.exit(f'{name}: two versions, in {seen[name][0]} and {p}')
            seen[name] = (p, code)
    for name, (_, code) in sorted(seen.items()):
        dest = os.path.join(out, name)
        os.makedirs(os.path.dirname(dest) or '.', exist_ok=True)
        with open(dest, 'w', encoding='utf-8') as f:
            f.write(code)
        print(name, file=sys.stderr)


main()
