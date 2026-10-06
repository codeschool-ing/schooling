#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py and ingest.py live in ../../lab/code and build lesson 5's index;
# rag.py, the whole pipeline in one file, lives there too and is this lesson's.
# The other programs are written by `put`. Every reply comes from extract-1,
# the lab's stand-in generator, which is not a language model, through the
# OpenAI and Anthropic SDKs talking to labgen (lab/labgen.py says what it does
# and which parts of each API it implements). The refusals in the section on
# errors are injected on purpose through labgen's /lab/config. Timings are not
# quoted anywhere, because they change from run to run.
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
use chunking.py ingest.py rag.py
lab exec 'python ingest.py' >/dev/null
put last_query.py <<'EOF_FILE'
import json

record = json.loads(open("queries.jsonl").read().splitlines()[-1])
del record["ms"]
print(json.dumps(record, indent=2))
EOF_FILE
put rag_claude.py <<'EOF_FILE'
import sys

import anthropic
from rag import retrieve

client = anthropic.Anthropic()
question = sys.argv[1]
sources = retrieve(question)
documents = [{"type": "document", "title": path, "citations": {"enabled": True},
              "source": {"type": "text", "media_type": "text/plain", "data": text}}
             for _, path, text, _, _ in sources]
message = client.messages.create(
    model="extract-1", max_tokens=300,
    system="Answer the customer's question from the documents.",
    messages=[{"role": "user", "content": documents + [{"type": "text", "text": question}]}])
for block in message.content:
    if block.type == "text" and block.text.strip():
        print(block.text)
        for c in block.citations or []:
            print(f"  document {c.document_index}, {c.document_title}, characters {c.start_char_index}-{c.end_char_index}")
print("usage:", message.usage.input_tokens, "in,", message.usage.output_tokens, "out")
EOF_FILE
put stream.py <<'EOF_FILE'
import sys

from openai import OpenAI
from rag import SYSTEM, retrieve

client = OpenAI()
question = sys.argv[1]
sources = retrieve(question)
numbered = "\n\n".join(f"[{n}] {path} (updated {updated})\n{text}"
                       for n, (_, path, text, updated, _) in enumerate(sources, 1))
stream = client.chat.completions.create(
    model="extract-1", stream=True, stream_options={"include_usage": True},
    messages=[{"role": "system", "content": SYSTEM},
              {"role": "user", "content": f"{numbered}\n\nQuestion: {question}"}])
pieces = 0
for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
        pieces += 1
    if chunk.usage:
        usage = chunk.usage
print()
print(f"{pieces} pieces; usage: {usage.prompt_tokens} in, {usage.completion_tokens} out")
EOF_FILE
put fragile.py <<'EOF_FILE'
import sys

import openai
import rag

rag.client = openai.OpenAI(max_retries=2, timeout=20)
try:
    print(rag.ask(sys.argv[1])[0])
except openai.RateLimitError as e:
    print("gave up after retries:", e.status_code)
    print("Our assistant is busy right now. Please try again in a minute.")
EOF_FILE
put statuses.py <<'EOF_FILE'
import json

for line in open("/var/log/labgen/requests.jsonl").read().splitlines()[-6:]:
    r = json.loads(line)
    print(r["path"], r["status"])
EOF_FILE
put budget.py <<'EOF_FILE'
import sys

import tiktoken
from rag import SYSTEM, retrieve

enc = tiktoken.get_encoding("cl100k_base")
BUDGET = int(sys.argv[2])
question = sys.argv[1]
sources = retrieve(question)
cost = lambda s: len(enc.encode(f"[0] {s[1]} (updated {s[3]})\n{s[2]}"))
fixed = len(enc.encode(SYSTEM)) + len(enc.encode(f"Question: {question}"))
print(f"instructions and question: {fixed} tokens")
kept, used = [], fixed
for s in sources:
    if used + cost(s) > BUDGET:
        print(f"  drop  {cost(s):4} tokens  {s[1]}")
        continue
    kept.append(s)
    used += cost(s)
    print(f"  keep  {cost(s):4} tokens  {s[1]}")
print(f"{used} of {BUDGET} tokens, {len(kept)} of {len(sources)} sources")
EOF_FILE

block whole
on 'python rag.py "How long after my return arrives will I get the refund?"'
on 'python rag.py "Can I place an order by phone?"'
block log
on 'wc -l < queries.jsonl'
on 'python rag.py "How long is a gift card valid?" > /dev/null; python last_query.py'
block claude
on 'python rag_claude.py "How long is a gift card valid?"'
block stream
on 'python stream.py "How long is a gift card valid?"'
block errors
on 'curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 2, \"status\": 429}"; echo'
on 'python rag.py "How long is a gift card valid?"'
on 'python statuses.py'
on 'curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 5, \"status\": 429}"; echo'
on 'python fragile.py "How long is a gift card valid?"'
on 'python statuses.py'
on 'curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 0}"; echo'
block budget
on 'python budget.py "How long after my return arrives will I get the refund?" 400'
on 'python budget.py "How long after my return arrives will I get the refund?" 250'
