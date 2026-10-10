#!/usr/bin/env python3
"""Put what a lesson's captures.sh printed into the lesson, in both languages.

    sudo bash captures.sh > /tmp/out.txt
    python3 ../../lab/paste.py /tmp/out.txt        # from inside the lesson

The capture prints `##### SLUG` before each transcript, naming the section it
belongs to. In SLUG.md and SLUG.pt.md, every transcript fence (no info string,
first line a prompt of ana's) and every line that is only `@@cap@@` is a slot,
and the section's transcripts fill its slots in order. A different number of
transcripts and slots is refused, so a capture that lost a command, or a
section that lost a fence, says so instead of shifting every one after it.
"""
import collections
import os
import re
import sys

SLOT = re.compile(r"^```\n(ana@dev:[^\n]*\n.*?)^```$|^@@cap@@$", re.M | re.S)


def main(out):
    blocks = collections.OrderedDict()
    name = None
    for line in open(out, encoding="utf-8").read().splitlines(keepends=True):
        m = re.match(r"^##### (\S+)\n$", line)
        if m:
            name = m.group(1)
            blocks.setdefault(name, []).append("")
        elif name:
            blocks[name][-1] += line
    bad = 0
    for slug, texts in blocks.items():
        for md in (slug + ".md", slug + ".pt.md"):
            if not os.path.exists(md):
                print(f"paste: {md} does not exist", file=sys.stderr)
                bad += 1
                continue
            src = open(md, encoding="utf-8").read()
            slots = SLOT.findall(src)
            if len(slots) != len(texts):
                print(f"paste: {md} has {len(slots)} slots and the capture "
                      f"{len(texts)} transcripts", file=sys.stderr)
                bad += 1
                continue
            it = iter(texts)
            new = SLOT.sub(lambda _: "```\n" + next(it).rstrip("\n") + "\n```", src)
            if new != src:
                open(md, "w", encoding="utf-8").write(new)
                print(f"paste: {md} rewritten")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(sys.argv[1])
