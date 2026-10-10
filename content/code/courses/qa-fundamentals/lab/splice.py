#!/usr/bin/env python3
"""Put a lesson's captures into its prose. THE AUTHOR'S.

    bash lessons/<id>/captures.sh > /tmp/out.txt
    python3 lab/splice.py lessons/<id> /tmp/out.txt

The output is cut at the `##### NAME` lines the capture script prints. Each
block replaces the line `@@cap:NAME@@` in every .md of the lesson, English and
Portuguese alike, as a plain fence; on a later run, when the placeholder is
gone, it replaces the fence whose first line is the block's first line, which
is the prompt and the command and is unique within a lesson. A block nothing
asks for is reported, and so is a placeholder no block filled.
"""
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
for p in sorted(glob.glob(os.path.join(d, '*.md'))):
    t = open(p, encoding='utf-8').read()
    n = t
    for k, body in blocks.items():
        ph = f'@@cap:{k}@@'
        if ph in n:
            n = n.replace(ph, '```\n' + body + '\n```')
            used.add(k)
            continue
        first = body.split('\n', 1)[0]
        pat = re.compile(r'```\n' + re.escape(first) + r'\n.*?\n```', re.S)
        if first.startswith('lia@') and pat.search(n):
            n = pat.sub(lambda _: '```\n' + body + '\n```', n, count=1)
            used.add(k)
    for left in re.findall(r'@@cap:([\w-]+)@@', n):
        print(f'{os.path.basename(p)}: no block named {left}')
    if n != t:
        open(p, 'w', encoding='utf-8').write(n)
for k in blocks:
    if k not in used:
        print(f'block {k} is used nowhere')
