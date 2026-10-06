#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py and answer.py live in ../../lab/code and
# are lessons 4 to 7's. The other programs are written by `put`.
#
# THE QUERY LOG IS GENERATED, NOT RECORDED. data/querylog.jsonl is 500
# questions over a week drawn by lab/querylog.py with a fixed seed from forty
# phrasings the course wrote, with a topic label on each. It has far fewer
# distinct questions than a real support queue, so the hit rates measured
# here are higher than a real one would show; what the lesson measures is how
# each cache behaves, and the labels are what let it count a cache's wrong
# answers. Token counts are labgen's usage figures, and every reply comes
# from extract-1, the lab's stand-in generator, which is not a language model
# (lab/labgen.py says what it does, including the prompt cache it imitates).
# No price is quoted: costs are in tokens, which a reader multiplies by their
# provider's current price list.
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
use chunking.py ingest.py search.py answer.py
lab exec 'python ingest.py' >/dev/null
put priced.py <<'EOF_FILE'
import json

import tiktoken
from answer import SYSTEM, prompt, sources_for
from openai import OpenAI

client = OpenAI()
enc = tiktoken.get_encoding("cl100k_base")
LOG = [json.loads(line) for line in open("data/querylog.jsonl")]


def run(question):
    """What answering one question costs, in tokens, through lesson 7's pipeline."""
    sources = sources_for(question)
    cost = {"embedding": len(enc.encode(question)), "input": 0, "output": 0, "instructions": 0, "sources": 0}
    if sources:
        user = prompt(question, sources)
        reply = client.chat.completions.create(model="extract-1", messages=[
            {"role": "system", "content": SYSTEM}, {"role": "user", "content": user}])
        cost.update(input=reply.usage.prompt_tokens, output=reply.usage.completion_tokens,
                    instructions=len(enc.encode(SYSTEM)), sources=len(enc.encode(user)) - len(enc.encode(f"Question: {question}")))
    return cost


if __name__ == "__main__":
    costs = {text: run(text) for text in sorted({q["text"] for q in LOG})}
    json.dump(costs, open("costs.json", "w"), indent=1)
    total = {k: sum(costs[q["text"]][k] for q in LOG) for k in ("embedding", "input", "output")}
    calls = sum(1 for q in LOG if costs[q["text"]]["input"])
    print(f"{len(LOG)} questions, {calls} model calls, {len(LOG) - calls} refused before the model")
    print(f"embedding {total['embedding']:6} tokens")
    print(f"input     {total['input']:6} tokens   {total['input'] / calls:.0f} per call")
    print(f"output    {total['output']:6} tokens   {total['output'] / calls:.0f} per call")
EOF_FILE
put split.py <<'EOF_FILE'
import json

costs = json.load(open("costs.json"))
LOG = [json.loads(line) for line in open("data/querylog.jsonl")]
answered = [costs[q["text"]] for q in LOG if costs[q["text"]]["input"]]
total = sum(c["input"] + c["output"] for c in answered)
for part in ("instructions", "sources", "output"):
    n = sum(c[part] for c in answered)
    print(f"{part:13} {n:6} tokens  {n / total:4.0%}")
rest = sum(c["input"] - c["instructions"] - c["sources"] for c in answered)
print(f"{'question etc':13} {rest:6} tokens  {rest / total:4.0%}")
EOF_FILE
put repeats.py <<'EOF_FILE'
import collections
import json
import re

LOG = [json.loads(line) for line in open("data/querylog.jsonl")]
norm = lambda t: re.sub(r"[^a-z0-9 ]", "", t.lower()).strip()
print(f"{len(LOG)} questions, {len({q['text'] for q in LOG})} distinct as typed, "
      f"{len({norm(q['text']) for q in LOG})} after lower-casing and dropping punctuation, "
      f"{len({q['topic'] for q in LOG})} topics")
for text, n in collections.Counter(q["text"] for q in LOG).most_common(5):
    print(f"{n:4}  {text}")
EOF_FILE
put exact.py <<'EOF_FILE'
import hashlib
import json
import re

from search import conn

costs = json.load(open("costs.json"))
LOG = [json.loads(line) for line in open("data/querylog.jsonl")]


def version():
    """The index the answers came from: a hash of every chunk id, which changes when any chunk does."""
    ids = [i for (i,) in conn.execute("SELECT id FROM chunks ORDER BY id")]
    return hashlib.sha256("\n".join(ids).encode()).hexdigest()[:12]


def key(question, audiences, index):
    """Same words, same reader's permissions, same index: only then is an answer the same answer."""
    words = re.sub(r"[^a-z0-9 ]", "", question.lower()).split()
    return (" ".join(words), ",".join(sorted(audiences)), index)


if __name__ == "__main__":
    index = version()
    cache, calls, saved = set(), 0, 0
    for q in LOG:
        k = key(q["text"], ["public"], index)
        c = costs[q["text"]]
        if k in cache:
            saved += c["input"] + c["output"]
        else:
            cache.add(k)
            calls += bool(c["input"])
    print(f"index version {index}")
    print(f"{len(cache)} keys, {len(LOG) - len(cache)} hits of {len(LOG)} ({(len(LOG) - len(cache)) / len(LOG):.0%}), "
          f"{calls} model calls, {saved} tokens not spent")
EOF_FILE
put semantic.py <<'EOF_FILE'
import json

import numpy as np
from minilm import embed

LOG = [json.loads(line) for line in open("data/querylog.jsonl")]
texts = sorted({q["text"] for q in LOG})
vectors = dict(zip(texts, embed(texts)))
topic = {q["text"]: q["topic"] for q in LOG}
print(f"{'threshold':>9} {'misses':>7} {'hits':>5} {'wrong':>6}")
for threshold in (0.95, 0.9, 0.85, 0.8, 0.75, 0.7):
    stored, hits, wrong = [], 0, 0
    for q in LOG:
        v = vectors[q["text"]]
        best = max(stored, key=lambda s: float(v @ vectors[s]), default=None)
        if best is not None and float(v @ vectors[best]) >= threshold:
            hits += 1
            wrong += topic[best] != q["topic"]
        else:
            stored.append(q["text"])
    print(f"{threshold:9.2f} {len(stored):7} {hits:5} {wrong:6}")
EOF_FILE
put near.py <<'EOF_FILE'
from minilm import embed

pairs = [("Can I cancel a pre-order?", "Can I cancel my order?"),
         ("how do I cancel a pre-order", "how do I cancel an order"),
         ("how long does a refund take", "refund timing after return")]
for a, b in pairs:
    v = embed([a, b])
    print(f"{float(v[0] @ v[1]):.3f}  {a!r}  {b!r}")
EOF_FILE
put cached_prompt.py <<'EOF_FILE'
import anthropic
from chunking import load

docs = load()
standing = "\n".join(f'<source id="{key}">{body}</source>' for key, (meta, body) in docs.items()
                     if key in ("returns-policy", "shipping-and-delivery", "terms-of-sale"))
client = anthropic.Anthropic()
for question in ("How much is express delivery?", "How many days do I have to return a printed book?"):
    message = client.messages.create(
        model="extract-1", max_tokens=200,
        system=[{"type": "text", "text": "Answer Marginalia's customers from these documents.\n\n" + standing,
                 "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": question}])
    u = message.usage
    print(f"{question}\n  input {u.input_tokens}, written to cache {u.cache_creation_input_tokens}, "
          f"read from cache {u.cache_read_input_tokens}, output {u.output_tokens}")
EOF_FILE

block cost
on 'python priced.py'
on 'python split.py'
block repeats
on 'python repeats.py'
block exact
on 'python exact.py'
block semantic
on 'python semantic.py'
on 'python near.py'
block version
on 'python -c "import exact; print(exact.version())"'
on 'sed -i "s/valid for two years from the day it was bought/valid for three years from the day it was bought/" data/docs/gift-cards.md && python ingest.py'
on 'python -c "import exact; print(exact.version())"'
block prompt
on 'python cached_prompt.py'
