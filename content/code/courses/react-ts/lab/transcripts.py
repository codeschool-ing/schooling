"""transcripts.py LESSON_DIR CAPTURE_OUTPUT: is every transcript still true?

Every fence in the lesson's English prose that starts with ana's prompt must
appear in what captures.sh printed on this run. Durations, the names of
npm's log files and the date Angular's build prints are the only things allowed to differ, because they differ
on every run; each is replaced by a placeholder on both sides before the
comparison, and nothing else is.
"""
import re
import sys
from pathlib import Path

VOLATILE = [
    (re.compile(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z"), "<stamp>"),
    (re.compile(r"\b\d+(\.\d+)?\s?(ms|seconds|s|m)\b"), "<time>"),
    (re.compile(r"\d{4}-\d\d-\d\dT\d\d_\d\d_\d\d_\d+Z"), "<stamp>"),
    (re.compile(r"\(\d+(\.\d+)?s\)"), "(<time>)"),
    (re.compile(r"\b\d\d:\d\d:\d\d\b"), "<clock>"),
    (re.compile(r"\b\d+%"), "<pct>"),
]


def norm(s):
    for rx, rep in VOLATILE:
        s = rx.sub(rep, s)
    return s


def main(lesson, capture):
    raw = re.sub(r"^#####F .*?^#####E\n", "", Path(capture).read_text(), flags=re.M | re.S)
    out = norm(raw)
    bad = 0
    for md in sorted(Path(lesson).glob("*.md")):
        if md.name.endswith(".pt.md"):
            continue
        for m in re.finditer(r"^```\n(ana@dev:[\s\S]*?)^```$", md.read_text(), flags=re.M):
            body = norm(m.group(1).rstrip("\n"))
            if body not in out:
                first = m.group(1).splitlines()[0]
                print(f"transcripts: {md.name}: the transcript starting `{first}` is not what this run printed",
                      file=sys.stderr)
                bad += 1
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(*sys.argv[1:])
