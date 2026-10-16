#!/usr/bin/env python3
"""The English .md files of one lesson, in the order lesson.json names them.

A file a lesson shows twice is a file that grows, and the version the next
lesson starts from is the last one shown — so the order matters, and the
order is the lesson's, never the directory listing's.
"""
import json
import os
import sys

d = sys.argv[1]
for s in json.load(open(os.path.join(d, 'lesson.json')))['sections']:
    p = os.path.join(d, s['slug'] + '.md')
    if os.path.exists(p):
        print(p)
