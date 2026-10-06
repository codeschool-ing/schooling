#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/rag by `put`.
# Nothing is staged. Every reply in this lesson comes from extract-1, the
# lab's stand-in generator, which is not a language model: its rules are at
# the top of lab/labgen.py, and its closed-book answers are sentences the
# course wrote in lab/memory.json. Every count of tokens and every similarity
# was computed on this machine.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/rag, and what it printed.
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/rag, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/rag from nothing.
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
put ask.py <<'EOF_FILE'
import sys
from openai import OpenAI

client = OpenAI()
reply = client.chat.completions.create(
    model="extract-1",
    messages=[{"role": "user", "content": sys.argv[1]}],
)
print(reply.choices[0].message.content)
EOF_FILE
put with_doc.py <<'EOF_FILE'
import sys
from openai import OpenAI

client = OpenAI()
policy = open("data/docs/returns-policy.md").read()
reply = client.chat.completions.create(
    model="extract-1",
    messages=[
        {"role": "system", "content": "Answer the question from the source below."},
        {"role": "user", "content": f"[1] returns-policy\n{policy}\nQuestion: {sys.argv[1]}"},
    ],
)
print(reply.choices[0].message.content)
print("prompt tokens:", reply.usage.prompt_tokens)
EOF_FILE
put count.py <<'EOF_FILE'
import glob
import tiktoken

enc = tiktoken.get_encoding("cl100k_base")
total = 0
for path in sorted(glob.glob("data/docs/*.md")):
    n = len(enc.encode(open(path).read()))
    total += n
    print(f"{n:6,}  {path}")
print(f"{total:6,}  in all")
EOF_FILE
put everything.py <<'EOF_FILE'
import glob
from openai import BadRequestError, OpenAI

client = OpenAI()
sources = ""
for i, path in enumerate(sorted(glob.glob("data/docs/*.md")), 1):
    sources += f"[{i}] {path}\n{open(path).read()}\n"
try:
    reply = client.chat.completions.create(
        model="extract-1",
        messages=[{"role": "user", "content": sources + "Question: How much is express delivery?"}],
    )
    print(reply.choices[0].message.content)
except BadRequestError as e:
    print("refused:", e.body["message"])
EOF_FILE
put tiny_rag.py <<'EOF_FILE'
import glob
import re
import sys

from minilm import embed
from openai import OpenAI

# 1. Cut every document into its sections, at each "## " heading.
sections = []
for path in sorted(glob.glob("data/docs/*.md")):
    doc = path.split("/")[-1][:-3]
    for part in re.split(r"\n(?=## )", open(path).read())[1:]:
        heading = part.splitlines()[0][3:]
        sections.append((f"{doc} > {heading}", part))

# 2. Embed them once, and the question every time.
vectors = embed([text for _, text in sections])
question = sys.argv[1]
scores = vectors @ embed(question)[0]

# 3. Keep the best three.
best = scores.argsort()[::-1][:3]
for rank, i in enumerate(best, 1):
    print(f"[{rank}] {scores[i]:.3f}  {sections[i][0]}")

# 4. Put only those in the prompt, numbered, and ask.
sources = "".join(f"[{rank}] {sections[i][0]}\n{sections[i][1]}\n" for rank, i in enumerate(best, 1))
reply = OpenAI().chat.completions.create(
    model="extract-1",
    messages=[
        {"role": "system", "content": "Answer from the sources and cite them by number."},
        {"role": "user", "content": f"{sources}Question: {question}"},
    ],
)
print(reply.choices[0].message.content)
EOF_FILE

block closed-book
on 'python ask.py "How many days do I have to return a printed book?"'
on 'python ask.py "What is the phone number for customer service?"'
on 'python ask.py "Can I get my money back for an e-book I downloaded yesterday?"'
block memory
on 'grep -c "\"q\"" /opt/rag/share/memory.json'
block tour
on 'ls data'
on 'wc -l data/*.jsonl'
on 'ls data/docs'
on 'head -12 data/docs/returns-policy.md'
on 'wc -w data/docs/*.md | tail -1'
on 'grep -c "14 days" data/docs/*.md | grep -v ":0"'
on 'du -sh /opt/emb /opt/rag 2>/dev/null'
on 'curl -s localhost:8600/; echo'
block with-doc
on 'python with_doc.py "How many days do I have to return a printed book?"'
on 'python with_doc.py "What is the phone number for customer service?"'
block count
on 'python count.py'
on 'python everything.py'
block tiny
on 'cat data/docs/*.md | grep -c "^## "'
on 'python tiny_rag.py "How many days do I have to return a printed book?"'
on 'python tiny_rag.py "How much is express delivery?"'
block fails
on 'python tiny_rag.py "Who pays for the return postage?"'
on 'python tiny_rag.py "Can I place an order by phone?"'
