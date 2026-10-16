#!/usr/bin/env python3
"""Print the program inside FILE.md's ```schooling-example whose "file" is NAME.

    python3 example.py FILE.md NAME

The parts' code is joined with newlines, which is what the copy button hands
a student. Exactly one example must match.
"""
import json, re, sys
path, name = sys.argv[1], sys.argv[2]
text = open(path, encoding='utf-8').read()
hits = []
for body in re.findall(r'^```schooling-example\n(.*?)\n```$', text, flags=re.M | re.S):
    ex = json.loads(body)
    if ex.get('file') == name:
        hits.append(ex)
if len(hits) != 1:
    sys.exit('example.py: %d examples in %s are files called %r' % (len(hits), path, name))
sys.stdout.write('\n'.join(p['code'] for p in hits[0]['parts']) + '\n')
