#!/usr/bin/env python3
"""Write the project files the lessons of `scale` show, from the lessons themselves.

Every file the student builds is shown whole in a lesson, and this reads it
back out of the lesson's English prose, so the file a capture runs and the file
the student copies cannot be two different files.

A block names its file in one of two ways:
  - a ```schooling-example whose JSON has "file": its parts joined by "\n",
    which is exactly what the copy button above it hands over;
  - a plain fence whose FIRST line is a comment naming the file, `# app.py`,
    `-- schema.sql` or `// script.js`.

    extract.py COURSE_DIR DEST N [SLUG]

walks lessons 1..N in course order, sections in lesson order, blocks in file
order, and writes each file into DEST; a later block of the same name replaces
an earlier one. With SLUG it stops after that section of lesson N.
"""
import json, os, re, sys

NAMED = re.compile(r"^(?:#|--|//) ((?:[\w.-]+/)*[\w.-]+\.(?:py|ya?ml|conf|sql|txt|js|sh|toml|cql|cypher|flux)|Dockerfile)$")
FENCE = re.compile(r"^```([\w-]*)\n(.*?)\n```$", re.S | re.M)


def blocks(md):
    for lang, body in FENCE.findall(md):
        if lang == "schooling-example":
            ex = json.loads(body)
            if ex.get("file"):
                yield ex["file"], "\n".join(p["code"] for p in ex["parts"]) + "\n"
        elif lang != "schooling-figure":
            first = body.split("\n", 1)[0]
            m = NAMED.match(first)
            if m:
                yield m.group(1), body + "\n"


def main():
    course, dest, upto = sys.argv[1], sys.argv[2], int(sys.argv[3])
    stop = sys.argv[4] if len(sys.argv) > 4 else None
    lessons = json.load(open(os.path.join(course, "course.json")))["lessons"][:upto]
    files = {}
    for n, lid in enumerate(lessons, 1):
        ldir = os.path.join(course, "lessons", lid)
        for sec in json.load(open(os.path.join(ldir, "lesson.json")))["sections"]:
            path = os.path.join(ldir, sec["slug"] + ".md")
            if os.path.exists(path):
                for name, text in blocks(open(path).read()):
                    files[name] = text
            if n == upto and sec["slug"] == stop:
                break
    for name, text in files.items():
        out = os.path.join(dest, name)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w") as f:
            f.write(text)
    print(" ".join(sorted(files)))


main()
