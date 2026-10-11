#!/usr/bin/env python3
"""Put a capture's output into a lesson, byte for byte. THE AUTHOR'S.

A lesson's captures.sh prints blocks, each opened by `##### <name>`. A section
marks where a block goes with a line `@@cap:<name>@@`, in the .md and at the
same place in the .pt.md (a fence in a translation is the English fence). This
replaces the marker with a plain fence holding the block.

On a later run the marker is gone. The previous output, kept outside the
repository, says what the fence held, so a block whose output changed is
replaced where it stands; a block whose fence cannot be found is an error,
because then the lesson quotes something the capture no longer prints.

    bash captures.sh > out.txt
    python3 ../../lab/splice.py . out.txt
"""
import glob
import os
import re
import sys

KEEP = os.environ.get('CAPTURE_KEEP', '/tmp/claude-0/data-fundamentals-captures')


def blocks(text):
    out, name, buf = {}, None, []
    for line in text.split('\n'):
        m = re.match(r'^##### (\S+)$', line)
        if m:
            if name:
                out[name] = '\n'.join(buf).rstrip('\n')
            name, buf = m.group(1), []
        elif name:
            buf.append(line)
    if name:
        out[name] = '\n'.join(buf).rstrip('\n')
    return out


def main():
    lesson, path = sys.argv[1], sys.argv[2]
    lesson = os.path.abspath(lesson)
    new = blocks(open(path, encoding='utf-8').read())
    os.makedirs(KEEP, exist_ok=True)
    keep = os.path.join(KEEP, os.path.basename(lesson) + '.out')
    old = blocks(open(keep, encoding='utf-8').read()) if os.path.exists(keep) else {}
    mds = sorted(glob.glob(os.path.join(lesson, '*.md')))
    texts = {p: open(p, encoding='utf-8').read() for p in mds}
    bad = 0
    for name, body in new.items():
        fence = '```\n' + body + '\n```'
        hit = False
        for p, t in texts.items():
            marker = f'@@cap:{name}@@'
            if marker in t:
                texts[p] = t = t.replace(marker, fence)
                hit = True
            if name in old and old[name] != body:
                was = '```\n' + old[name] + '\n```'
                if was in t:
                    texts[p] = t = t.replace(was, fence)
                    hit = True
            if fence in t:
                hit = True
        if not hit:
            print(f'block {name}: no marker and no fence holding it')
            bad += 1
    for p, t in texts.items():
        for m in re.findall(r'@@cap:([\w-]+)@@', t):
            print(f'{os.path.basename(p)}: @@cap:{m}@@ is not a block the capture printed')
            bad += 1
        if t != open(p, encoding='utf-8').read():
            open(p, 'w', encoding='utf-8').write(t)
    open(keep, 'w', encoding='utf-8').write(open(path, encoding='utf-8').read())
    sys.exit(1 if bad else 0)


main()
