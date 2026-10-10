#!/usr/bin/env python3
"""Pull a program out of a lesson, so the file a capture runs is the file the lesson shows.

    extract.py LESSON.md NAME    the one block that IS the file NAME: a fence whose
                                 first line is `# NAME`, or a schooling-example
                                 whose "file" is NAME (its parts joined, notes
                                 dropped, exactly what the copy button hands over)
    extract.py LESSON.md --with TEXT
                                 the one fence that contains TEXT, whole

Exactly one match or it exits non-zero: two blocks claiming one name is a lesson
that shows two programs and a capture that would run one of them.
"""
import json
import re
import sys

FENCE = re.compile(r"^```([\w-]*)\n(.*?)^```$", re.S | re.M)


def blocks(text):
    for m in FENCE.finditer(text):
        lang, body = m.group(1), m.group(2)
        if lang == "schooling-example":
            ex = json.loads(body)
            # ui/app/copy.js joins the parts with one newline, so a blank line
            # between two parts is a part whose code ends in "\n"
            yield "example", ex.get("file"), "\n".join(p["code"] for p in ex["parts"]) + "\n"
        elif lang in ("schooling-figure", "schooling-block"):
            continue
        else:
            first = body.split("\n", 1)[0]
            yield "fence", first[2:].strip() if first.startswith("# ") else None, body


def main():
    path, what = sys.argv[1], sys.argv[2]
    text = open(path, encoding="utf-8").read()
    if what == "--with":
        found = [b for _, _, b in blocks(text) if sys.argv[3] in b]
    else:
        found = [b for _, name, b in blocks(text) if name == what]
    if len(found) != 1:
        sys.exit(f"{path}: {len(found)} blocks for {sys.argv[2:]}, and a capture needs exactly one")
    sys.stdout.write(found[0])


main()
