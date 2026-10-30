"""same.py LESSON_DIR: put the English fences into the Portuguese prose.

A translation translates the prose and never the program, so a .pt.md is
written with a line `@@same:N@@` wherever the English file has its Nth fence
(counting every fence except figures, which are drawn per language by fig.py),
and this replaces each one with that fence, byte for byte. A schooling-example
is the exception: its notes are prose, so it is written out in full in the
translation, and validate-content compares its code with the English.
"""
import re
import sys
from pathlib import Path

FENCE = re.compile(r"^```([a-z-]*)\n[\s\S]*?^```$", re.M)


def fences(text):
    return [m.group(0) for m in FENCE.finditer(text) if m.group(1) != "schooling-figure"]


def main(lesson):
    bad = 0
    for pt in sorted(Path(lesson).glob("*.pt.md")):
        en = pt.with_name(pt.name.replace(".pt.md", ".md"))
        src = fences(en.read_text())
        text = pt.read_text()

        def rep(m):
            nonlocal bad
            n = int(m.group(1))
            if n < 1 or n > len(src):
                print(f"same: {pt.name} asks for fence {n} and {en.name} has {len(src)}", file=sys.stderr)
                bad += 1
                return m.group(0)
            return src[n - 1]
        new = re.sub(r"^@@same:(\d+)@@$", rep, text, flags=re.M)
        if new != text:
            pt.write_text(new)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(sys.argv[1])
