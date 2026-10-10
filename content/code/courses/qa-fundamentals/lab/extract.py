#!/usr/bin/env python3
"""Write out every program a lesson shows, exactly as the lesson shows it.

THE AUTHOR'S, NOT THE STUDENT'S. A capture has to run the program the student
reads, so the program is read out of the lesson rather than kept beside it:

  - an ordinary fence whose first line is a comment naming a file
    (`# tickets.py`, `# wednesday.feature`) is that file, first line included;
  - a `schooling-example` with a "file" is that file, its parts joined in
    order, which is what the copy button hands over.

    python3 lab/extract.py OUTDIR lessons/<id>/<section>.md ...

The files are read in the order given, and a file shown more than once keeps
every version: OUTDIR/<name> is the last one, and OUTDIR/.versions/<name>@<n>
is the nth, so a capture of a lesson where one file grows step by step can put
each step in place. English files only; a translation's fences are the English
ones byte for byte, which validate-content checks.
"""
import json
import os
import re
import sys

NAME = re.compile(r'^# ([\w./-]+\.(?:py|feature|txt|csv|ini|cfg))\s*$')


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
        if m and info in ('python', 'py', ''):
            yield m.group(1), body + '\n'


def main():
    out = sys.argv[1]
    os.makedirs(os.path.join(out, '.versions'), exist_ok=True)
    count = {}
    for path in sys.argv[2:]:
        for name, code in files(path):
            prev = os.path.join(out, name)
            if os.path.exists(prev) and open(prev, encoding='utf-8').read() == code:
                continue
            count[name] = count.get(name, 0) + 1
            os.makedirs(os.path.dirname(prev) or '.', exist_ok=True)
            for p in (prev, os.path.join(out, '.versions', f'{name.replace("/", "_")}@{count[name]}')):
                with open(p, 'w', encoding='utf-8') as f:
                    f.write(code)


if __name__ == '__main__':
    main()
