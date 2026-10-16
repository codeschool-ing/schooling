#!/usr/bin/env python3
"""Print the fenced block of FILE.md whose first line starts with PREFIX.

    python3 fence.py FILE.md PREFIX

The capture scripts run what a lesson shows by taking it out of the lesson,
so the file a student copies and the file that ran cannot drift apart. Exactly
one block must match; none, or two, is an error.
"""
import sys
path, prefix = sys.argv[1], sys.argv[2]
blocks, cur = [], None
for line in open(path, encoding='utf-8').read().split('\n'):
    if line.startswith('```'):
        if cur is None:
            cur = []
        else:
            blocks.append(cur); cur = None
    elif cur is not None:
        cur.append(line)
hits = [b for b in blocks if b and b[0].startswith(prefix)]
if len(hits) != 1:
    sys.exit('fence.py: %d blocks in %s start with %r' % (len(hits), path, prefix))
sys.stdout.write('\n'.join(hits[0]) + '\n')
