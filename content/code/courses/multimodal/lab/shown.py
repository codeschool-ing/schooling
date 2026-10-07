"""shown: the files a lesson SHOWS, read back out of its .md so a capture runs exactly them.

    python3 shown.py get MD NAME     print the file called NAME in MD
    python3 shown.py check MD...     read a file on stdin; fail unless one of the
                                     MDs shows it byte for byte

A file is shown in one of two ways, and both are read:

  - a `schooling-example` block whose "file" is NAME: the parts' code, joined;
  - a line that starts with `NAME` and ends in a colon, and the fence under it.

`check` accepts any fence or example in the files given, which is how a capture
that writes a program with a heredoc proves the lesson prints the same bytes.
A program a capture runs and no lesson shows is the defect C-40 names, and this
is where it fails.
"""
import json
import re
import sys

FENCE = re.compile(r"^```([\w-]*)\n(.*?)^```$", re.M | re.S)


def blocks(md):
    """Every fence's body and every example's joined code, with the name each is shown under."""
    text = open(md).read()
    for m in FENCE.finditer(text):
        lang, body = m.group(1), m.group(2)
        if lang == "schooling-example":
            ex = json.loads(body)
            yield ex.get("file"), "".join(p["code"] for p in ex["parts"]) + "\n"
            continue
        if lang == "schooling-figure":
            continue
        before = text[:m.start()].rstrip("\n").rsplit("\n", 1)[-1]
        name = re.match(r"^`([^`]+)`.*:$", before)
        yield (name.group(1) if name else None), body


def main():
    if sys.argv[1] == "get":
        md, name = sys.argv[2], sys.argv[3]
        for n, body in blocks(md):
            if n == name:
                sys.stdout.write(body)
                return
        sys.exit(f"{md} shows no {name}")
    if sys.argv[1] == "check":
        data = sys.stdin.read()
        if not data.endswith("\n"):
            data += "\n"
        for md in sys.argv[2:]:
            if any(body == data for _, body in blocks(md)):
                return
        first = data.splitlines()[0] if data else "(empty)"
        sys.exit(f"no lesson shows this file, byte for byte: {first}")


if __name__ == "__main__":
    main()
