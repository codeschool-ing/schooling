#!/usr/bin/env python3
"""Print the block of FILE.md that a capture runs.

    python3 fence.py FILE.md PREFIX

The capture scripts run what a lesson shows by taking it out of the lesson,
so the file a student copies and the file that ran cannot drift apart. The
block is an ordinary fence whose first line starts with PREFIX, or a
schooling-example whose "file" is PREFIX, printed as its parts joined, which is
what its copy button hands over. Exactly one block must match; none, or two,
is an error.

Taken from sql-databases' lab, with the second kind of block added.
"""
import json, sys
path, prefix = sys.argv[1], sys.argv[2]
blocks, cur, lang = [], None, None
for line in open(path, encoding='utf-8').read().split('\n'):
    if line.startswith('```'):
        if cur is None:
            cur, lang = [], line[3:].strip()
        else:
            blocks.append((lang, cur)); cur = None
    elif cur is not None:
        cur.append(line)
hits = []
for lang, b in blocks:
    if lang == 'schooling-example':
        ex = json.loads('\n'.join(b))
        if ex.get('file') == prefix:
            hits.append(''.join(p['code'] for p in ex['parts']))
    elif b and b[0].startswith(prefix):
        hits.append('\n'.join(b) + '\n')
if len(hits) != 1:
    sys.exit('fence.py: %d blocks in %s start with %r' % (len(hits), path, prefix))
sys.stdout.write(hits[0])
