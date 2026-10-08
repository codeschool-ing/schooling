"""shown: print a file exactly as the lessons of this course show it.

    python3 shown.py COURSE_DIR NAME [LESSON_ID [--only]]

The capture scripts never carry their own copy of a program the student types.
They ask this file for it, so the program that ran is the program on the page
and the two cannot drift apart.

Two shapes count as "showing" NAME:

  * a `schooling-example` block whose "file" is NAME. Its parts, in order, are
    joined by two blank lines, and so are several blocks of one lesson.
  * a plain fence whose first or second line starts with "# NAME:", which is how
    a shell script introduces itself. Its body is the file, unchanged.

A file belongs to the lesson that shows it. When a later lesson shows the same
name again, that is a new version of the file and replaces the earlier one, so
the answer is the last lesson that shows NAME, up to and including LESSON_ID
when one is given. With --only, it is LESSON_ID's version or nothing.

A name shown nowhere is an error, never an empty file.
"""
import json
import os
import re
import sys


def fences(text):
    lines, out, i = text.split("\n"), [], 0
    while i < len(lines):
        m = re.match(r"^(`{3,})(.*)$", lines[i])
        if not m:
            i += 1
            continue
        tick, info, body, j = m.group(1), m.group(2).strip(), [], i + 1
        while j < len(lines) and not lines[j].startswith(tick):
            body.append(lines[j])
            j += 1
        out.append((info, "\n".join(body) + "\n"))
        i = j + 1
    return out


def shown_in(course, lesson, name):
    d = os.path.join(course, "lessons", lesson)
    blocks, plain = [], None
    for section in json.load(open(os.path.join(d, "lesson.json")))["sections"]:
        path = os.path.join(d, section["slug"] + ".md")
        if not os.path.exists(path):
            continue
        for info, body in fences(open(path).read()):
            if info == "schooling-example":
                block = json.loads(body)
                if block.get("file") == name:
                    blocks.append("\n\n\n".join(p["code"] for p in block["parts"]))
            elif plain is None and any(l.startswith(f"# {name}:") for l in body.split("\n")[:2]):
                plain = body
    if blocks:
        return "\n\n\n".join(blocks) + "\n"
    return plain


def main(course, name, upto=None, only=None):
    lessons = json.load(open(os.path.join(course, "course.json")))["lessons"]
    if upto:
        lessons = [upto] if only == "--only" else lessons[:lessons.index(upto) + 1]
    for lesson in reversed(lessons):
        text = shown_in(course, lesson, name)
        if text is not None:
            sys.stdout.write(text)
            return
    sys.exit(f"shown: no lesson shows {name}")


if __name__ == "__main__":
    main(*sys.argv[1:])
