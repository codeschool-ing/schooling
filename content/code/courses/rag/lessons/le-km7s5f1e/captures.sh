#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/rag by `put`.
# Nothing is staged. Every reply comes from extract-1, the lab's stand-in
# generator, which is not a language model (lab/labgen.py says what it does);
# every similarity was computed on this machine with all-MiniLM-L6-v2.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
put sections.py <<'EOF_FILE'
import glob
import re
import sys

from minilm import embed
from openai import OpenAI

sections = []
for path in sorted(glob.glob("data/docs/*.md")):
    doc = path.split("/")[-1][:-3]
    for part in re.split(r"\n(?=## )", open(path).read())[1:]:
        sections.append((f"{doc} > {part.splitlines()[0][3:]}", part))
vectors = embed([text for _, text in sections])


def search(question, k=3):
    scores = vectors @ embed(question)[0]
    return [(sections[i][0], sections[i][1], float(scores[i])) for i in scores.argsort()[::-1][:k]]


def answer(question, k=3):
    found = search(question, k)
    for rank, (name, _, score) in enumerate(found, 1):
        print(f"[{rank}] {score:.3f}  {name}")
    sources = "".join(f"[{rank}] {name}\n{text}\n" for rank, (name, text, _) in enumerate(found, 1))
    reply = OpenAI().chat.completions.create(model="extract-1", messages=[
        {"role": "system", "content": "Answer from the sources and cite them by number."},
        {"role": "user", "content": f"{sources}Question: {question}"}])
    print(reply.choices[0].message.content)


if __name__ == "__main__":
    answer(sys.argv[1])
EOF_FILE
put help_search.py <<'EOF_FILE'
import json
import sys

from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
vectors = embed([h["title"] + ". " + h["body"] for h in help])
scores = vectors @ embed(sys.argv[1])[0]
for i in scores.argsort()[::-1][:3]:
    print(f"{scores[i]:.3f}  {help[i]['id']} {help[i]['lang']}  {help[i]['title']}")
EOF_FILE

block docs
on 'python sections.py "What does error E-4104 mean?"'
on 'grep -n "E-4104" data/docs/*.md'
on 'python sections.py "What is the rate limit of the affiliate API?"'
block support
on 'python help_search.py "how do I send a book back"'
on 'python help_search.py "como devolvo um livro"'
on 'python help_search.py "quanto custa a entrega expressa"'
block legal
on 'python sections.py "When is the contract of sale formed?"'
on 'grep -n "^2\.2" data/docs/terms-of-sale.md'
block internal
on 'grep -h "^audience:" data/docs/*.md | sort | uniq -c'
on 'python sections.py "When does an order get held for manual fraud review?"'
block wrong-tool
on 'python sections.py "Which documents mention a 14-day limit?"'
on 'grep -l "14 days" data/docs/*.md'
on 'python sections.py "Summarise all of our policies"'
