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
# (lab.sh reset), and the files ana wrote (put below), which the lessons show
# in full, each checked by lab/shown.py.
#
# THE MODELS ARE REAL: llama3.2:3b (a80c4f17acd5) and llama3.2:1b in Ollama
# 0.40.0 with an 8192-token context, on this machine's CPU, captured on
# 2026-10-08. The token counts, the times, the cache reads, the truncation and
# the SDK's retries are real measurements. The 529s come from flaky.py, which
# lesson 7 shows whole. Times vary from run to run and from machine to
# machine; the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
lab exec 'ollama run llama3.2:3b hello; ollama run llama3.2:1b hello' < /dev/null >/dev/null 2>&1
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
        print(f"       tool {call.name} {json.dumps(call.input)}", end="", flush=True)
        out = json.dumps(RUN[call.name](call.input))
        print(f": {(time.perf_counter() - t0) * 1000:.0f} ms")
        results.append({"type": "tool_result", "tool_use_id": call.id, "content": out})
    messages.append({"role": "user", "content": results})
print(f"total {totals['input']:7} {totals['cache_write']:8} {totals['cache_read']:7} {totals['output']:7} "
      f"{(time.perf_counter() - start) * 1000:6.0f}")
PY

put limits.py <<'PY'
"""Three limits, met one at a time: the reply's length, the context window, and a server too busy to answer."""
import sys
import time

import anthropic

client = anthropic.Anthropic()
SYSTEM = "You answer Marginalia's customers in the cost lesson."
ASK = [{"role": "user", "content": "Say hello to a customer."}]

what = sys.argv[1]
t0 = time.perf_counter()
try:
    if what == "max-tokens":
        r = client.messages.create(model="llama3.2:3b", max_tokens=8, system=SYSTEM, messages=ASK)
        print(r.stop_reason, repr(r.content[0].text))
    if what == "window":                      # about six times the 8192 tokens Ollama was given
        huge = "word " * 50_000 + "\nWhat is the last line of this message?"
        r = client.messages.create(model="llama3.2:3b", max_tokens=32, messages=[{"role": "user", "content": huge}])
        print(r.stop_reason, "input_tokens:", r.usage.input_tokens, repr(r.content[0].text))
    if what == "overloaded":                  # run with ANTHROPIC_BASE_URL at lesson 7's flaky.py
        r = client.messages.create(model="llama3.2:3b", max_tokens=64, system=SYSTEM, messages=ASK)
        print("answered:", r.content[0].text)
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code}: {e.message[:120]}")
print(f"{(time.perf_counter() - t0) * 1000:.0f} ms")
PY

put flaky.py <<'PY'
"""flaky.py N: answer the first N requests on port 11437 with 529 Overloaded, then pass the rest on to Ollama."""
import http.client
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

left = int(sys.argv[1])


class Flaky(BaseHTTPRequestHandler):
    def do_POST(self):
        global left
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if left > 0:
            left -= 1
            status = 529
            data = json.dumps({"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}}).encode()
        else:
            upstream = http.client.HTTPConnection("127.0.0.1", 11434, timeout=900)
            upstream.request("POST", self.path, body, {"Content-Type": "application/json"})
            reply = upstream.getresponse()
            status, data = reply.status, reply.read()
        print(status, flush=True)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11437), Flaky).serve_forever()
PY

block run
on 'python cost_run.py llama3.2:3b'

block again
on 'python cost_run.py llama3.2:3b'

block cache
on 'python cost_run.py llama3.2:3b --cache'

block stamp
on 'python cost_run.py llama3.2:3b --cache --stamp'

block mini
on 'python cost_run.py llama3.2:1b'

block max-tokens
on 'python limits.py max-tokens'

block window
on 'python limits.py window'

block overloaded
on 'python flaky.py 2 > flaky.log & sleep 1; ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python limits.py overloaded; kill $!; echo $(cat flaky.log)'
on 'python flaky.py 3 > flaky.log & sleep 1; ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python limits.py overloaded; kill $!; echo $(cat flaky.log)'
