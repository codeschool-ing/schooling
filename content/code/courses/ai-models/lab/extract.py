#!/usr/bin/env python3
"""extract: a file the student is given, taken out of the lesson that gives it.

THE LESSON IS THE SOURCE. A program, a prompt or a data file the student types
in is shown whole in a lesson, and the capture runs exactly what is shown: this
reads it back out of the .md, so the two cannot drift apart.

    extract.py LESSON.md LANG N        the Nth fence labelled LANG (1-based);
                                       LANG may be "" for an unlabelled fence
    extract.py LESSON.md example NAME  the schooling-example whose "file" is
                                       NAME, its parts joined in order
    extract.py LESSON.md after TEXT    the first fence after the first line that
                                       contains TEXT, such as `prompts/triage.txt`:

A fence that is not there is an error, never an empty file.
"""
import json
import re
import sys


def fences(text):
    for m in re.finditer(r"^```([\w-]*)\n(.*?)^```$", text, re.S | re.M):
        yield m.group(1), m.group(2)


def main():
    path, lang, which = sys.argv[1:4]
    text = open(path, encoding="utf-8").read()
    if lang == "example":
        for label, body in fences(text):
            if label == "schooling-example":
                ex = json.loads(body)
                if ex.get("file") == which:
                    sys.stdout.write("".join(p["code"] for p in ex["parts"]))
                    return
        sys.exit(f"extract: {path} has no schooling-example for {which}")
    if lang == "after":
        at = text.find(which)
        if at < 0:
            sys.exit(f"extract: {path} never mentions {which!r}")
        for m in re.finditer(r"^```([\w-]*)\n(.*?)^```$", text[at:], re.S | re.M):
            sys.stdout.write(m.group(2))
            return
        sys.exit(f"extract: {path} has no fence after {which!r}")
    found = [body for label, body in fences(text) if label == lang]
    n = int(which)
    if n < 1 or n > len(found):
        sys.exit(f"extract: {path} has {len(found)} fence(s) labelled {lang!r}, not {n}")
    sys.stdout.write(found[n - 1])


if __name__ == "__main__":
    main()
