#!/usr/bin/env python3
"""Print one block of a lesson's Markdown, as the student would copy it.

    python3 fence.py FILE.md PREFIX

A fenced block whose first line starts with PREFIX is printed whole. A
schooling-example whose "file" is PREFIX is printed the way the page's copy
button hands it over: the code of every part, joined, without the notes.

The capture scripts run what a lesson shows by taking it out of the lesson, so
the file a student copies and the file that ran cannot drift apart. Exactly one
block must match; none, or two, is an error.
"""
import json, sys
path, prefix = sys.argv[1], sys.argv[2]
blocks, cur, info = [], None, ''
for line in open(path, encoding='utf-8').read().split('\n'):
    if line.startswith('```'):
        if cur is None:
            cur, info = [], line[3:].strip()
        else:
            blocks.append((info, cur)); cur = None
    elif cur is not None:
        cur.append(line)
hits = []
for info, body in blocks:
    if info == 'schooling-example':
        ex = json.loads('\n'.join(body))
        if ex.get('file') == prefix:
            hits.append('\n'.join(p['code'] for p in ex['parts']))
    elif body and body[0].startswith(prefix):
        hits.append('\n'.join(body))
if len(hits) != 1:
    sys.exit('fence.py: %d blocks in %s match %r' % (len(hits), path, prefix))
sys.stdout.write(hits[0] + '\n')
