"""shown: print a file exactly as the lessons of this course show it.

    python3 shown.py COURSE_DIR NAME [LESSON_ID]

The capture scripts never carry their own copy of a program the student types.
They ask this file for it, so the program that ran is the program on the page
and the two cannot drift apart.

Two shapes count as "showing" NAME:

  * a `schooling-example` block whose "file" is NAME. Its parts, in order, are
    joined by two blank lines. A file shown in several sections, or several
    lessons, is all of its blocks in course order, joined the same way; give
    LESSON_ID to take only the blocks of one lesson.
  * a plain fence whose first or second line starts with "# NAME:", which is how
    a shell script introduces itself. Its body is the file, unchanged.

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


def main(course, name, only=None):
    lessons = json.load(open(os.path.join(course, "course.json")))["lessons"]
    blocks, plain = [], None
    for lesson in lessons:
        if only and lesson != only:
            continue
        d = os.path.join(course, "lessons", lesson)
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
        sys.stdout.write("\n\n\n".join(blocks) + "\n")
    elif plain is not None:
        sys.stdout.write(plain)
    else:
        sys.exit(f"shown: no lesson shows {name}")


if __name__ == "__main__":
    main(*sys.argv[1:])
