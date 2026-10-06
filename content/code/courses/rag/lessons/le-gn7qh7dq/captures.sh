#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of rag, as a script that produces
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
# reindex_cost.py prints its time rounded up to the whole second, because the
# exact figure changes from run to run and the rounded one does not.
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
put sections.py <<'EOF_FILE'
import glob
import os
import re
import sys

from minilm import embed
from openai import OpenAI

skip = set(os.environ.get("WITHOUT", "").split(","))
sections = []
for path in sorted(glob.glob("data/docs/*.md")):
    doc = path.split("/")[-1][:-3]
    if doc in skip:
        continue
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
    return reply


if __name__ == "__main__":
    answer(sys.argv[1])
EOF_FILE
put dataset.py <<'EOF_FILE'
import json

import tiktoken
from sections import search
from openai import OpenAI

# One training example per answerable question in the test set: the question,
# and the answer extract-1 gives when the right section is in front of it.
enc = tiktoken.get_encoding("cl100k_base")
client = OpenAI()
total = 0
with open("ft.jsonl", "w") as out:
    for line in open("data/eval.jsonl"):
        q = json.loads(line)
        if not q["gold"]:
            continue
        name, text, _ = search(q["question"], 1)[0]
        reply = client.chat.completions.create(model="extract-1", messages=[
            {"role": "user", "content": f"[1] {name}\n{text}\nQuestion: {q['question']}"}])
        answer = reply.choices[0].message.content.replace(" [1]", "")
        example = {"messages": [{"role": "user", "content": q["question"]},
                                {"role": "assistant", "content": answer}]}
        out.write(json.dumps(example) + "\n")
        total += sum(len(enc.encode(m["content"])) for m in example["messages"])
print("examples:", sum(1 for _ in open("ft.jsonl")))
print("training tokens per epoch:", total)
EOF_FILE
put reindex_cost.py <<'EOF_FILE'
import glob
import math
import re
import time

import tiktoken
from minilm import embed

enc = tiktoken.get_encoding("cl100k_base")


def cut(path):
    return re.split(r"\n(?=## )", open(path).read())[1:]


one = cut("data/docs/returns-policy.md")
every = [part for path in sorted(glob.glob("data/docs/*.md")) for part in cut(path)]
for label, parts in (("the returns policy", one), ("every document", every)):
    start = time.perf_counter()
    embed(parts)
    seconds = time.perf_counter() - start
    tokens = sum(len(enc.encode(p)) for p in parts)
    print(f"{label:20} {len(parts):3} sections  {tokens:5} tokens  under {math.ceil(seconds)} s")
EOF_FILE
put context_tokens.py <<'EOF_FILE'
import json

import tiktoken
from sections import search

enc = tiktoken.get_encoding("cl100k_base")
sizes = []
for line in open("data/eval.jsonl"):
    q = json.loads(line)["question"]
    sources = "".join(f"[{r}] {name}\n{text}\n" for r, (name, text, _) in enumerate(search(q), 1))
    sizes.append(len(enc.encode(sources)))
print("questions:", len(sizes))
print("retrieved tokens per question, mean:", round(sum(sizes) / len(sizes)))
print("smallest:", min(sizes), " largest:", max(sizes))
EOF_FILE
put costs.py <<'EOF_FILE'
import argparse

p = argparse.ArgumentParser(description="Compare the bill of RAG and of fine-tuning, per month.")
p.add_argument("--questions", type=int, help="questions a month")
p.add_argument("--context", type=int, help="retrieved tokens a RAG question adds to the prompt")
p.add_argument("--train-tokens", type=int, help="training tokens in one epoch")
p.add_argument("--epochs", type=int, default=3)
p.add_argument("--retrains", type=int, help="fine-tuning runs a month, one per change")
p.add_argument("--input-price", type=float, help="price per million input tokens")
p.add_argument("--train-price", type=float, help="price per million training tokens")
a = p.parse_args()

rag = a.questions * a.context * a.input_price / 1e6
tune = a.retrains * a.train_tokens * a.epochs * a.train_price / 1e6
print(f"RAG, extra context:  {rag:10.2f} a month")
print(f"fine-tuning, training: {tune:8.2f} a month")
EOF_FILE

block dataset
on 'python dataset.py'
on 'head -n 2 ft.jsonl'
block freshness
on 'python reindex_cost.py'
block trace
on 'python sections.py "How long do I have to return a printed book?"'
on 'grep -n "30 days from delivery" data/docs/returns-policy.md'
block cost
on 'python context_tokens.py'
on 'python costs.py --questions 30000 --context 332 --train-tokens 968 --epochs 3 --retrains 4 --input-price 3 --train-price 25'
on 'python costs.py --questions 30000 --context 332 --train-tokens 968000 --epochs 3 --retrains 4 --input-price 3 --train-price 25'
block delete
on 'python sections.py "How much does the return label cost?"'
on 'WITHOUT=returns-policy-2025 python sections.py "How much does the return label cost?"'
