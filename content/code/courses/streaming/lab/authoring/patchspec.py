#!/usr/bin/env python3
"""patchspec.py SPEC PATCH: PATCH is a python file defining R = [(old_en_text, new_en, new_pt), ...]
Replaces the (en, pt) text pair of a choice whose English text is old_en_text."""
import re, sys, ast
spec, patch = sys.argv[1], sys.argv[2]
s = open(spec).read(); ns = {}; exec(open(patch).read(), ns)
for old, en, pt in ns["R"]:
    m = re.search(r'\(\s*("(?:[^"\\]|\\.)*")\s*,\s*("(?:[^"\\]|\\.)*")\s*,', s[s.find(repr(old)[1:-1]) - 2:] if False else s)
    # find the tuple start whose first string equals old
    key = '("' + old.replace('\\', '\\\\').replace('"', '\\"') + '",'
    i = s.find(key)
    if i < 0: sys.exit(f"not found: {old}")
    j = i + len(key)
    # skip the pt string
    mm = re.match(r'\s*"(?:[^"\\]|\\.)*"', s[j:])
    s = s[:i] + '(' + repr_q(en) + ',' + repr_q(pt) if False else s
    new = '(' + '"' + en.replace('\\', '\\\\').replace('"', '\\"') + '","' + pt.replace('\\', '\\\\').replace('"', '\\"') + '"'
    s = s[:i] + new + s[j + mm.end():]
open(spec, "w").write(s)
print(len(ns["R"]), "patched")
