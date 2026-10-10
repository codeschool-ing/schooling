#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in this lesson: the lab
# (lab.sh reset), and agent.py, which is lesson 1's, written again here
# unchanged. Every other file ana wrote is put below and shown in the lesson.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, on 4 CPUs and no graphics chip, captured on 2026-10-08.
# Its labels, its steps and its words are what it said that day, and the
# times in the tallies are what its answers took on this machine, with the
# model already loaded (the warm-up below).
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
sed -n "/^put agent.py <<'PY'$/,/^PY$/p" ../le-fx9p1n5x/captures.sh | sed '1d;$d' | put agent.py
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null
# The model is loaded before anything is measured: the first request after a
# few idle minutes waits while Ollama reads 2 GB from disk.
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1

put router.py <<'PY'
"""A workflow with routing: the model picks a branch once, and the code does the rest."""
import re
import sys

import anthropic

import shop

client = anthropic.Anthropic()
message = sys.argv[1]
label = client.messages.create(
    model="llama3.2:3b",
    max_tokens=5,
    system="Classify the customer's message. Answer with exactly one word: order, policy or other.",
    messages=[{"role": "user", "content": message}],
).content[0].text.strip().strip(".").lower()

if label == "order":
    order = shop.get_order(re.search(r"M-\d{4}", message).group())
    print(f"[order] {order['id']} is {order['status']}"
          + (f", delivered on {order['delivered_on']}" if order["delivered_on"] else ""))
elif label == "policy":
    best = shop.search_help(message, k=1)[0]
    print(f"[policy] {best['title']}: {best['body']}")
else:
    print("[other] passed to a person")
PY

put tally.py <<'PY'
"""What the runs since requests.jsonl was emptied cost: requests, tokens and model time."""
import json

rows = [json.loads(line) for line in open("requests.jsonl")]
tokens_in = sum(r["usage"]["input_tokens"] for r in rows)
tokens_out = sum(r["usage"]["output_tokens"] for r in rows)
seconds = sum(r["ms"] for r in rows) / 1000
print(f"requests {len(rows)}   input tokens {tokens_in}   output tokens {tokens_out}   model time {seconds:.1f} s")
PY

Q1="Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
Q2="My order M-1043 has not arrived yet. Where is it?"
Q3="Which ways can I pay?"
Q4="The courier was rude to me at the door yesterday."

block router
recorder
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11435'
on "python router.py \"$Q1\""
on "python router.py \"$Q2\""
on "python router.py \"$Q3\""
on "python router.py \"$Q4\""
on 'python tally.py'

block agent
on 'rm requests.jsonl'
on "python agent.py \"$Q1\""
on "python agent.py \"$Q2\""
on "python agent.py \"$Q3\""
on 'python tally.py'

block compound
on "python -c 'for p in (0.99, 0.95, 0.90): print(p, *(f\"{p ** n:.2f}\" for n in (1, 3, 5, 10, 20)))'"
