#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, search.py and memory.py live in ../../lab/code and are lessons
# 4, 6 and 13's; compact.py, there too, is this lesson's. Every summary comes
# from extract-1, the lab's stand-in generator, which is not a language model:
# asked to summarise, it keeps whole sentences of the text, the ones nearest
# the text's average meaning, up to the word limit it was given
# (lab/labgen.py, rule 2). A language model writes summaries in its own words
# and loses different things; what this lesson measures is how to find out
# what any summariser lost, and the stand-in gives that test something to
# catch. The list of facts that must survive is written for the course, in
# essentials.py.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
use chunking.py search.py memory.py compact.py
put essentials.py <<'EOF_FILE'
import json

# What a support agent picking up Beatriz's conversation must still know, each as words that have to
# appear. Written by a person who read the conversation; that is what makes it a test.
ESSENTIALS = {
    "order number": ["MG-20481937"],
    "contact by email only": ["email only"],
    "replacement for Persuasion": ["Persuasion", "replacement"],
    "wrong book received": ["Mansfield Park"],
    "money back for Middlemarch": ["Middlemarch", "money back"],
    "new address": ["Rua das Flores 120"],
}
TURNS = [json.loads(line)["text"] for line in open("data/chat-a.jsonl")]


def kept(text):
    """The essentials TEXT still carries: every word of each one has to be there."""
    return [name for name, words in ESSENTIALS.items() if all(w.lower() in text.lower() for w in words)]
EOF_FILE
put summaries.py <<'EOF_FILE'
from compact import summarise, tokens
from essentials import ESSENTIALS, TURNS, kept

older = TURNS[:11]
print(f"{'':10} {'tokens':>6}  essentials")
print(f"{'all turns':10} {tokens(' '.join(older)):6}  {len(kept(' '.join(older)))}/{len(ESSENTIALS)}")
for words in (20, 40, 60, 100):
    summary = summarise(older, words)
    print(f"{words:3} words  {tokens(summary):6}  {len(kept(summary))}/{len(ESSENTIALS)}  lost: {', '.join(n for n in ESSENTIALS if n not in kept(summary))}")
EOF_FILE
put one.py <<'EOF_FILE'
import sys

from compact import summarise
from essentials import TURNS

print(summarise(TURNS[:11], int(sys.argv[1])))
EOF_FILE
put compacted.py <<'EOF_FILE'
from compact import compact, text_of, tokens
from essentials import ESSENTIALS, TURNS, kept

c = compact(TURNS[:11])
print("pinned:")
for s in c["pinned"]:
    print("  ", s)
print("summary:")
print("  ", c["summary"])
print("recent:")
for t in c["recent"]:
    print("  ", t)
text = text_of(c)
print(f"{tokens(text)} tokens, essentials {len(kept(text))}/{len(ESSENTIALS)}")
EOF_FILE
put rolling.py <<'EOF_FILE'
from compact import summarise, tokens
from essentials import ESSENTIALS, TURNS, kept

summary = ""
for start in range(0, 12, 4):
    block = ([summary] if summary else []) + TURNS[start:start + 4]
    summary = summarise(block, 40)
    print(f"after turns {start + 1:2}-{start + 4:2}: {tokens(summary):3} tokens, essentials {len(kept(summary))}/{len(ESSENTIALS)}")
    print("  ", summary)
EOF_FILE
put policy.py <<'EOF_FILE'
import sys

from chunking import load, sections
from compact import summarise

meta, body = load()["returns-policy"]
for path, text in sections(body):
    if path.endswith(sys.argv[1]):
        print(" ".join(text.split()))
        print("summary:")
        print(summarise([text], int(sys.argv[2])))
EOF_FILE

block summaries
on 'python summaries.py'
on 'python one.py 40'
block compacted
on 'python compacted.py'
block rolling
on 'python rolling.py'
block policy
on 'python policy.py "Items that cannot be returned" 25'
on 'python policy.py "Gifts" 25'
