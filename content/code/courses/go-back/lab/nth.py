#!/usr/bin/env python3
"""Print the Nth (from 1) ordinary fence of FILE.md whose first line starts with PREFIX.

    python3 nth.py FILE.md PREFIX N

For a lesson that shows the same file twice, before and after a change: the
capture runs the first version, then the second, each taken from the lesson.
"""
import sys
path, prefix, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
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
sys.stdout.write('\n'.join(hits[n - 1]) + '\n')
