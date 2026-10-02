#!/usr/bin/env python3
"""assist: an editor assistant small enough to read, written for this course.

The assistants built into editors do three things before a model sees anything:
they decide which text to send (the file around the cursor, other files that look
related, the project's instruction file), they leave out what they were told to
leave out, and they fit the rest into a token budget. This does the same three
things in a hundred lines, against labllm, and prints what it sent, which the
real ones do not. It is not a copy of any of them: their exact rules are their
own and mostly unpublished. Its replies come from labllm's scripted-1 and were
written by the course.

    assist complete FILE:LINE [--open FILE ...]   fill in the code at LINE
    assist ask "QUESTION" [--open FILE ...]       a chat question about the files

Rules: AGENTS.md, if present, goes first. Paths matching a line of
.assistignore are never read. A file holding something shaped like a secret is
refused rather than sent. The budget is 3,000 tokens of context.
"""
import argparse
import fnmatch
import os
import re
import sys

import anthropic
import tiktoken

ENC = tiktoken.get_encoding("o200k_base")
BUDGET = 3000
SECRET = re.compile(r"(?i)(token|secret|password|api_key)\s*[=:]\s*\S{8,}")
CURSOR = "<CURSOR>"


def ignored(path):
    try:
        patterns = [p.strip() for p in open(".assistignore") if p.strip() and not p.startswith("#")]
    except FileNotFoundError:
        return False
    return any(fnmatch.fnmatch(path, p) or fnmatch.fnmatch(os.path.basename(path), p) for p in patterns)


def gather(paths, used):
    """The other files, in order, each whole or not at all, within what is left of the budget."""
    parts, notes = [], []
    for p in paths:
        if ignored(p):
            notes.append(f"skipped {p}: listed in .assistignore")
            continue
        text = open(p).read()
        if SECRET.search(text):
            notes.append(f"refused {p}: it holds something shaped like a secret")
            continue
        n = len(ENC.encode(text))
        if used + n > BUDGET:
            notes.append(f"dropped {p}: {n} tokens would pass the budget")
            continue
        parts.append((p, text, n))
        used += n
    return parts, used, notes


def main():
    ap = argparse.ArgumentParser(prog="assist")
    ap.add_argument("mode", choices=["complete", "ask"])
    ap.add_argument("target")
    ap.add_argument("--open", nargs="*", default=[], help="other files open in the editor")
    a = ap.parse_args()

    sections, used = [], 0
    if os.path.exists("AGENTS.md"):
        text = open("AGENTS.md").read()
        sections.append(("AGENTS.md", text, len(ENC.encode(text))))
        used += sections[-1][2]
    if a.mode == "complete":
        path, line = a.target.rsplit(":", 1)
        lines = open(path).read().split("\n")
        k = int(line)
        here = "\n".join(lines[:k]) + "\n" + CURSOR + "\n" + "\n".join(lines[k:])
        sections.append((path + " (cursor at line " + line + ")", here, len(ENC.encode(here))))
        used += sections[-1][2]
        system = (f"You complete code. The text {CURSOR} marks the cursor. "
                  "Reply with only the lines to insert there, nothing else.")
        question = "Complete the code at the cursor."
    else:
        system = "You answer questions about the files shown, briefly, as a senior colleague would."
        question = a.target
    others, used, notes = gather(a.open, used)
    sections += others

    prompt = "".join(f"### {name}\n{text}\n" for name, text, _ in sections) + "\n" + question
    print(f"context sent ({used} of {BUDGET} tokens):", file=sys.stderr)
    for name, _, n in sections:
        print(f"  {n:5}  {name}", file=sys.stderr)
    for note in notes:
        print(f"  {note}", file=sys.stderr)

    r = anthropic.Anthropic().messages.create(
        model="scripted-1", max_tokens=1500, system=system,
        messages=[{"role": "user", "content": prompt}])
    print("---", file=sys.stderr)
    print(r.content[0].text)


if __name__ == "__main__":
    main()
