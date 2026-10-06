#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset) and the files ana wrote (put below), which the lesson shows
# in full.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE,
# as rules in lab/scripted/03-*.json. That includes the observation the model
# invents in react_text.py's first run: the course wrote a reply that carries
# a made-up Observation line, to show what a stop sequence is for. The
# parsing, the stop sequence, the tools, their results, the trace and the
# repeat guard are real.
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
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put react_text.py <<'PY'
"""ReAct in plain text: the model writes Thought and Action lines, and the program parses them."""
import json
import re
import sys

import anthropic

import shop

PROMPT = """Answer the customer's question about Marginalia. You can use two tools:
  get_order[order id]    the order, its lines, and its amounts in cents
  search_help[words]     the three help-centre articles closest in meaning
Use this format, one Action at a time:
Thought: what you know and what you need next
Action: tool[argument]
Observation: (the program writes the tool's result here)
... and when you know enough:
Answer: the reply to the customer"""
TOOLS = {
    "get_order": lambda arg: shop.get_order(arg),
    "search_help": lambda arg: [a["title"] + ": " + a["body"] for a in shop.search_help(arg)],
}
STOP = ["Observation:"] if "--stop" in sys.argv else []

client = anthropic.Anthropic()
transcript = "Question: " + sys.argv[1] + "\n"
for step in range(1, 6):
    reply = client.messages.create(model="scripted-1", max_tokens=400, system=PROMPT,
                                   messages=[{"role": "user", "content": transcript}],
                                   stop_sequences=STOP)
    text = reply.content[0].text.rstrip()
    print(f"--- step {step} (stop_reason: {reply.stop_reason})")
    print(text)
    answer = re.search(r"^Answer: (.*)", text, re.M)
    if answer:
        break
    action = re.search(r"^Action: (\w+)\[(.*)\]", text, re.M)
    observation = json.dumps(TOOLS[action.group(1)](action.group(2)))
    print(f"Observation: {observation[:100]}")
    transcript += text + f"\nObservation: {observation}\n"
PY

block text-no-stop
on 'python react_text.py "Can I still return the books in order M-1047, and how would the refund work?"'
block text-stop
on 'python react_text.py "Can I still return the books in order M-1047, and how would the refund work?" --stop'

put react_native.py <<'PY'
"""ReAct with native tool calls: the thought is a text block, the action a tool_use block."""
import json
import sys

import anthropic

import shop

TOOLS = [
    {"name": "get_order",
     "description": "Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents.",
     "input_schema": {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}},
    {"name": "search_help",
     "description": "Search Marginalia's help centre by meaning and return the three closest articles.",
     "input_schema": {"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}},
]
RUN = {
    "get_order": lambda args: shop.get_order(args["order_id"]),
    "search_help": lambda args: [{"title": a["title"], "body": a["body"]} for a in shop.search_help(args["query"])],
}
SYSTEM = ("You answer Marginalia's customers. Before each tool call, say in one sentence what you know "
          "and what you need next. Never guess an order's details.")

client = anthropic.Anthropic()
messages = [{"role": "user", "content": sys.argv[1]}]
seen = set()
with open("trace.jsonl", "w") as trace:
    for step in range(1, 7):
        reply = client.messages.create(model="scripted-1", max_tokens=1024, system=SYSTEM,
                                       tools=TOOLS, messages=messages)
        messages.append({"role": "assistant", "content": reply.content})
        record = {"step": step, "stop_reason": reply.stop_reason, "input_tokens": reply.usage.input_tokens,
                  "text": " ".join(b.text for b in reply.content if b.type == "text"), "calls": []}
        results = []
        for block in reply.content:
            if block.type != "tool_use":
                continue
            call = (block.name, json.dumps(block.input, sort_keys=True))
            if call in seen:
                record["calls"].append({"tool": block.name, "input": block.input, "refused": "repeat"})
                trace.write(json.dumps(record) + "\n")
                print(f"host: step {step} repeats {block.name}({json.dumps(block.input)}); stopping")
                sys.exit(1)
            seen.add(call)
            output = json.dumps(RUN[block.name](block.input))
            record["calls"].append({"tool": block.name, "input": block.input, "output": output[:80]})
            results.append({"type": "tool_result", "tool_use_id": block.id, "content": output})
        trace.write(json.dumps(record) + "\n")
        if reply.stop_reason != "tool_use":
            print(record["text"])
            break
        messages.append({"role": "user", "content": results})
PY

put show_trace.py <<'PY'
"""Print trace.jsonl as one block per step: what the model said, what it called, what came back."""
import json

for line in open("trace.jsonl"):
    r = json.loads(line)
    print(f"step {r['step']}  stop_reason={r['stop_reason']}  input_tokens={r['input_tokens']}")
    print(f"  said:     {r['text'][:96]}")
    for c in r["calls"]:
        print(f"  called:   {c['tool']}({json.dumps(c['input'])})")
        print(f"  returned: {c.get('output', 'refused: ' + c.get('refused', ''))[:72]}")
PY

block native
on 'python react_native.py "Can I still return the books in order M-1047, and how would the refund work?"'
block native-trace
on 'python show_trace.py'

block observation-size
on "python -c 'import json, shop, tiktoken; enc = tiktoken.get_encoding(\"o200k_base\"); o = shop.get_order(\"M-1047\"); small = {k: o[k] for k in (\"status\", \"delivered_on\", \"total\")}; print(len(enc.encode(json.dumps(o))), len(enc.encode(json.dumps(small))))'"
on "python -c 'import json, shop, tiktoken; enc = tiktoken.get_encoding(\"o200k_base\"); print(len(enc.encode(json.dumps(shop.search_help(\"refund after a return\")))))'"

block loop
on 'python react_native.py "Do you sell signed first editions of Dom Casmurro?"'
on 'python show_trace.py'
