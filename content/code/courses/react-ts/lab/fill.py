"""fill.py LESSON_DIR CAPTURE_OUTPUT: put captured transcripts into a lesson.

A captures.sh prints `##### NAME` before each piece of what it recorded. A
fence in the lesson's English prose whose only line is `@@typed:NAME@@` is
replaced by that piece, exactly as it was printed, the first time the lesson
is written. After that the lesson is the text, and transcripts.py checks it
against the next run.
"""
import re
import sys
from pathlib import Path


def pieces(text):
    out, name = {}, None
    for line in text.splitlines(keepends=True):
        m = re.match(r"^##### (\S+)\n$", line)
        if m:
            name = m.group(1)
            out[name] = ""
        elif line.startswith("#####F ") or line.startswith("#####E"):
            continue
        elif name:
            out[name] += line
    return {k: v.rstrip("\n") for k, v in out.items()}


def main(lesson, capture):
    got = pieces(Path(capture).read_text())
    bad = 0
    for md in sorted(Path(lesson).glob("*.md")):
        text = md.read_text()

        def rep(m):
            nonlocal bad
            name = m.group(1)
            if name not in got:
                print(f"fill: {md.name} asks for {name}, which the capture did not print", file=sys.stderr)
                bad += 1
                return m.group(0)
            return got[name]
        new = re.sub(r"^@@typed:([a-z0-9-]+)@@$", rep, text, flags=re.M)
        if new != text:
            md.write_text(new)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(*sys.argv[1:])
