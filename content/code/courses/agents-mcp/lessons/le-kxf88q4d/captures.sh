#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), shown in full in the
# lesson; agent.py, which is lesson 1's, written again here unchanged; and
# emptying labllm's log before each measured run, which is done as root
# because the log belongs to the labllm user.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE:
# the router's one-word labels are rules in lab/scripted/02-*.json, and the
# agent's steps are lesson 1's rules. The programs, the timings, the token
# counts and the search are real. The time a request takes is labllm's own
# rule (200 ms, then 40 ms a token), not a provider's.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, with LAB_TODAY=2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
fresh_log() { : > /var/log/labllm/requests.jsonl; }
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
sed -n "/^put agent.py <<'PY'$/,/^PY$/p" ../le-fx9p1n5x/captures.sh | sed '1d;$d' | put agent.py
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put router.py <<'PY'
"""A workflow with routing: the model picks a branch once, and the code does the rest."""
import re
import sys

import anthropic

import shop

client = anthropic.Anthropic()
message = sys.argv[1]
label = client.messages.create(
    model="scripted-1",
    max_tokens=5,
    system="Classify the customer's message with one word: order, policy or other.",
    messages=[{"role": "user", "content": message}],
).content[0].text.strip()

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
"""What the runs since the log was emptied cost: requests, tokens and model time."""
import json

rows = [json.loads(line) for line in open("/var/log/labllm/requests.jsonl")]
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
fresh_log
on "python router.py \"$Q1\""
on "python router.py \"$Q2\""
on "python router.py \"$Q3\""
on "python router.py \"$Q4\""
on 'python tally.py'

block agent
fresh_log
on "python agent.py \"$Q1\""
on "python agent.py \"$Q2\""
on "python agent.py \"$Q3\""
on 'python tally.py'

block compound
on "python -c 'for p in (0.99, 0.95, 0.90): print(p, *(f\"{p ** n:.2f}\" for n in (1, 3, 5, 10, 20)))'"
