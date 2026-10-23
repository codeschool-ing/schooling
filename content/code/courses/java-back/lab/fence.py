#!/usr/bin/env python3
"""The bridge between what a lesson SHOWS and what the lab RUNS.

    fence.py extract FILE.md PREFIX     print the one fenced block whose first
                                        line starts with PREFIX
    fence.py check FILE.md PATH...      every PATH must be shown in FILE.md,
                                        byte for byte: as the body of a plain
                                        fence, or as the code of a
                                        schooling-example (its parts joined
                                        with newlines, as the copy button
                                        joins them)

A capture script extracts what a student types, or checks that every file of
the bookshop the lesson prints is the file the lab built. None, or two
matches for extract, and any PATH not found by check, is an error.
"""
import json
import sys


def fences(path):
    blocks, cur, info = [], None, ''
    for line in open(path, encoding='utf-8').read().split('\n'):
        if line.startswith('```'):
            if cur is None:
                cur, info = [], line[3:].strip()
            else:
                blocks.append((info, '\n'.join(cur)))
                cur = None
        elif cur is not None:
            cur.append(line)
    return blocks


def shown(path):
    out = []
    for info, body in fences(path):
        if info == 'schooling-example':
            ex = json.loads(body)
            out.append('\n'.join(p['code'] for p in ex['parts']))
        elif not info.startswith('schooling-'):
            out.append(body)
    return out


def main():
    mode = sys.argv[1]
    if mode == 'extract':
        md, prefix = sys.argv[2], sys.argv[3]
        hits = [b for i, b in fences(md) if b.startswith(prefix)]
        if len(hits) != 1:
            sys.exit('fence.py: %d blocks in %s start with %r' % (len(hits), md, prefix))
        sys.stdout.write(hits[0] + '\n')
    elif mode == 'check':
        md, paths = sys.argv[2], sys.argv[3:]
        bodies = shown(md)
        bad = 0
        for p in paths:
            text = open(p, encoding='utf-8').read()
            if text.endswith('\n'):
                text = text[:-1]
            if text not in bodies:
                print('fence.py: %s is not shown byte for byte in %s' % (p, md))
                bad += 1
        sys.exit(1 if bad else 0)
    else:
        sys.exit(__doc__)


main()
