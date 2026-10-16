#!/usr/bin/env python3
"""Put a lesson's captures into its prose. THE AUTHOR'S.

    bash lessons/<id>/captures.sh > /tmp/out.txt
    python3 lab/splice.py lessons/<id> /tmp/out.txt

The output is cut at the `##### NAME` lines the capture script prints. Each
block replaces the line `@@cap:NAME@@` in every .md of the lesson, English and
Portuguese alike, as a plain fence; on a later run, when the placeholder is
gone, it replaces the fence whose first line is the block's first line, the
prompt and the command, unless another block of the lesson starts with the
same line, as two runs of one query do. A block nothing
asks for is reported, and so is a placeholder no block filled.
"""
import collections
import glob
import os
import re
import sys

d, out = sys.argv[1], sys.argv[2]
blocks, name = {}, None
for line in open(out, encoding='utf-8').read().split('\n'):
    m = re.match(r'^##### (\S+)$', line)
    if m:
        name = m.group(1)
        blocks[name] = []
    elif name:
        blocks[name].append(line)
blocks = {k: '\n'.join(v).rstrip('\n') for k, v in blocks.items()}
used = set()
paths = sorted(glob.glob(os.path.join(d, '*.md')))
texts = {p: open(p, encoding='utf-8').read() for p in paths}
# First, every placeholder, in every file.
for p in paths:
    for k, body in blocks.items():
        ph = f'@@cap:{k}@@'
        if ph in texts[p]:
            texts[p] = texts[p].replace(ph, '```\n' + body + '\n```')
            used.add(k)
# Then, for a block no placeholder asked for, the fence that starts with the
# same prompt line, but only when no other block starts with that line too:
# two blocks running the same query would otherwise overwrite each other.
firsts = collections.Counter(b.split('\n', 1)[0] for b in blocks.values())
for k, body in blocks.items():
    if k in used:
        continue
    first = body.split('\n', 1)[0]
    if not first.startswith('lia@') or firsts[first] > 1:
        continue
    pat = re.compile(r'```\n' + re.escape(first) + r'\n.*?\n```', re.S)
    for p in paths:
        if pat.search(texts[p]):
            texts[p] = pat.sub(lambda _: '```\n' + body + '\n```', texts[p], count=1)
            used.add(k)
for p in paths:
    for left in re.findall(r'@@cap:([\w-]+)@@', texts[p]):
        print(f'{os.path.basename(p)}: no block named {left}')
    if texts[p] != open(p, encoding='utf-8').read():
        open(p, 'w', encoding='utf-8').write(texts[p])
for k in blocks:
    if k not in used:
        print(f'block {k} is used nowhere')
