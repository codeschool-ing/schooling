#!/usr/bin/env python3
"""Run every lesson's capture script and say whether its lesson still quotes it.

    sudo python3 lab/check.py              # every lesson with a captures.sh
    sudo python3 lab/check.py le-zz75x0ba  # one lesson

A capture script prints blocks headed `##### name`. Each block has to appear,
byte for byte, inside a fence of one of the lesson's English sections, and the
same fence has to be in its translation, which validate-content already holds
to the English. A block the prose does not carry is printed with what the
script produced, so the fix is a paste.
"""
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
only = set(sys.argv[1:])
bad = 0
for script in sorted(glob.glob(os.path.join(HERE, "lessons", "*", "captures.sh"))):
    lesson = os.path.dirname(script)
    if only and os.path.basename(lesson) not in only:
        continue
    out = subprocess.run(["bash", script], capture_output=True, text=True, cwd=lesson).stdout
    fences = []
    for md in glob.glob(os.path.join(lesson, "*.md")):
        if not md.endswith(".pt.md"):
            fences += re.findall(r"^```[\w-]*\n(.*?)^```$", open(md, encoding="utf-8").read(),
                                 re.S | re.M)
    for name, body in re.findall(r"^##### (\S+)\n(.*?)(?=^##### |\Z)", out, re.S | re.M):
        if not any(body.strip("\n") in f for f in fences):
            bad += 1
            print(f"--- {os.path.basename(lesson)} {name}: not in the lesson\n{body}")
print("every block is quoted" if not bad else f"{bad} block(s) the lessons do not quote")
sys.exit(1 if bad else 0)
