#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full; and emptying labllm's log before the runs whose requests are counted,
# done as root because the log belongs to the labllm user.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE,
# as rules in lab/scripted/18-cost.json. The token counts, the times, the cache
# accounting, the refusals and the SDK's retries are real MEASUREMENTS OF
# labllm, whose rules for each (time per token, the window, the cache) are its
# own and are written at the top of lab/labllm.py; the lesson says where they
# differ from a real provider's. The failures in the last block are simulated
# by labllm's /lab/config, which no real provider has. Timings vary by a few
# milliseconds from run to run.
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
STATUSES="python -c 'import json; print(\" \".join(str(json.loads(l)[\"status\"]) for l in open(\"/var/log/labllm/requests.jsonl\")))'"
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put cost_run.py <<'PY'
"""One agent run, measured: tokens and time per request, per tool, and in total."""
import argparse
import json
import time

import anthropic

import shop

parser = argparse.ArgumentParser()
parser.add_argument("model")
parser.add_argument("--cache", action="store_true", help="mark the policy as a cacheable prefix")
parser.add_argument("--stamp", action="store_true", help="put the current time at the top of the system prompt")
args = parser.parse_args()

POLICY = "\n\n".join(f"## {a['title']}\n{a['body']}" for a in map(json.loads, open("data/help.jsonl")))
SYSTEM = [{"type": "text", "text": "You answer Marginalia's customers in the cost lesson. Use the tools; never guess."},
          {"type": "text", "text": "Marginalia's policies, which every answer must respect:\n\n" + POLICY}]
if args.stamp:                                    # a value that changes on every request, at the very front
    SYSTEM.insert(0, {"type": "text", "text": ""})
if args.cache:                                    # everything up to here is the same on every request
    SYSTEM[-1]["cache_control"] = {"type": "ephemeral"}
TOOLS = [
    {"name": "get_order", "description": "Look up one Marginalia order by its id, M- and four digits.",
     "input_schema": {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}},
    {"name": "search_help", "description": "Search Marginalia's help centre by meaning.",
     "input_schema": {"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}},
]
RUN = {"get_order": lambda a: shop.get_order(a["order_id"]),
       "search_help": lambda a: [x["title"] for x in shop.search_help(a["query"])]}

client = anthropic.Anthropic()
messages = [{"role": "user", "content": "Where is my order M-1043?"}]
totals = {"input": 0, "cache_write": 0, "cache_read": 0, "output": 0}
start = time.perf_counter()
print("step   input  c.write  c.read  output     ms  stop")
for step in range(1, 7):
    if args.stamp:
        SYSTEM[0]["text"] = f"Request sent at {time.time():.3f}."
    t0 = time.perf_counter()
    reply = client.messages.create(model=args.model, max_tokens=1024, system=SYSTEM, tools=TOOLS, messages=messages)
    ms = (time.perf_counter() - t0) * 1000
    u = reply.usage
    row = {"input": u.input_tokens, "cache_write": u.cache_creation_input_tokens or 0,
           "cache_read": u.cache_read_input_tokens or 0, "output": u.output_tokens}
    for k in totals:
        totals[k] += row[k]
    print(f"{step:4} {row['input']:7} {row['cache_write']:8} {row['cache_read']:7} {row['output']:7} {ms:6.0f}  {reply.stop_reason}")
    messages.append({"role": "assistant", "content": reply.content})
    calls = [b for b in reply.content if b.type == "tool_use"]
    if not calls:
        break
    results = []
    for call in calls:
        t0 = time.perf_counter()
        out = json.dumps(RUN[call.name](call.input))
        print(f"       tool {call.name}: {(time.perf_counter() - t0) * 1000:.0f} ms")
        results.append({"type": "tool_result", "tool_use_id": call.id, "content": out})
    messages.append({"role": "user", "content": results})
print(f"total {totals['input']:7} {totals['cache_write']:8} {totals['cache_read']:7} {totals['output']:7} "
      f"{(time.perf_counter() - start) * 1000:6.0f}")
PY

put limits.py <<'PY'
"""Four limits a provider enforces, met one at a time."""
import json
import sys
import time
import urllib.request

import anthropic

client = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Say hello to a customer."}]


def lab_config(**settings):
    """labllm's own switch for simulated failures (lab only; a real provider has no such thing)."""
    req = urllib.request.Request("http://127.0.0.1:8600/lab/config", data=json.dumps(settings).encode(),
                                 headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req).read()


what = sys.argv[1]
t0 = time.perf_counter()
try:
    if what == "max-tokens":
        r = client.messages.create(model="scripted-1", max_tokens=8, system="You answer Marginalia's customers in the cost lesson.", messages=ASK)
        print(r.stop_reason, repr(r.content[0].text))
    if what == "window":
        huge = "word " * 210_000
        client.messages.create(model="scripted-1", max_tokens=1024, messages=[{"role": "user", "content": huge}])
    if what in ("overloaded", "overloaded-3"):
        lab_config(fail_next=529, fail_count=2 if what == "overloaded" else 3)
        r = client.messages.create(model="scripted-1", max_tokens=64, system="You answer Marginalia's customers in the cost lesson.", messages=ASK)
        print("answered:", r.content[0].text)
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code}: {e.message[:120]}")
print(f"{(time.perf_counter() - t0) * 1000:.0f} ms")
PY

block run
on 'python cost_run.py scripted-1'

block mini
on 'python cost_run.py scripted-mini'

block cache
on 'python cost_run.py scripted-1 --cache'
on 'python cost_run.py scripted-1 --cache'

block stamp
on 'python cost_run.py scripted-1 --cache --stamp'

block max-tokens
on 'python limits.py max-tokens'

block window
on 'python limits.py window'

block overloaded
fresh_log
on "python limits.py overloaded; $STATUSES"
fresh_log
on "python limits.py overloaded-3; $STATUSES"
