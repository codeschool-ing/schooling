#!/usr/bin/env python3
"""Hold a lesson's transcripts to the output of its captures.sh.

    python3 sync.py CAPTURE.out FILE.md [FILE.pt.md ...]          # check
    python3 sync.py --write CAPTURE.out FILE.md [FILE.pt.md ...]  # replace

A transcript in a lesson is a fence whose first line is a prompt. Its prompt
lines (the commands, and what was typed at psql) are looked up in the capture
output as a consecutive run, and the fence must equal the output from the
first of them to the end of what the last one printed. With --write, a fence
that differs is replaced by the output, which is how a lesson takes a new run
of its captures: the timestamps and sizes that move between runs move in the
lesson too, and nothing is typed by hand. A fence whose commands are not in
the output is an error either way.
"""
import re, sys

PROMPT = re.compile(r'^(?:ana@\w+:[^$\n]*\$ |root@\w+:[^#\n]*# |postgres@\w+:[^$\n]*\$ |'
                    r'mysql> |[a-z_][a-z0-9_]*[=\-*(\'"!]*\*?[#>] ?)')

def is_prompt(line):
    return bool(PROMPT.match(line))

def fences(text):
    """(start, end, lines) for every fence; start/end index the fence's body lines."""
    lines = text.split('\n')
    out, i = [], 0
    while i < len(lines):
        if lines[i].startswith('```'):
            j = i + 1
            while j < len(lines) and not lines[j].startswith('```'):
                j += 1
            out.append((i + 1, j, lines[i], lines[i + 1:j]))
            i = j + 1
        else:
            i += 1
    return lines, out

def find(cap, body):
    cmds = [l for l in body if is_prompt(l)]
    if not cmds:
        return None
    for k in range(len(cap)):
        if cap[k] != body[0] and cap[k] != cmds[0]:
            continue
        # walk the capture from k, matching prompt lines in order
        idx, c, end = k, 0, None
        while idx < len(cap) and c < len(cmds):
            if cap[idx].startswith('##### '):
                break
            if is_prompt(cap[idx]):
                if cap[idx] != cmds[c]:
                    break
                c += 1
            idx += 1
        if c < len(cmds):
            continue
        end = idx
        while end < len(cap) and not is_prompt(cap[end]) and not cap[end].startswith('##### '):
            end += 1
        seg = cap[k:end]
        while seg and seg[-1] == '':
            seg.pop()
        return seg
    return None

def main():
    args = sys.argv[1:]
    write = args and args[0] == '--write'
    if write:
        args = args[1:]
    cap = open(args[0], encoding='utf-8').read().split('\n')
    bad = 0
    for path in args[1:]:
        text = open(path, encoding='utf-8').read()
        lines, fs = fences(text)
        changed = False
        for start, end, opener, body in reversed(fs):
            if opener.strip() != '```' or not body or not is_prompt(body[0]):
                continue
            seg = find(cap, body)
            if seg is None:
                print('%s:%d: no capture has these commands: %r' % (path, start, body[0]))
                bad += 1
                continue
            if seg != body:
                if write:
                    lines[start:end] = seg
                    changed = True
                else:
                    print('%s:%d: differs from the capture' % (path, start))
                    bad += 1
        if changed:
            open(path, 'w', encoding='utf-8').write('\n'.join(lines))
            print('%s: updated' % path)
    sys.exit(1 if bad else 0)

main()
