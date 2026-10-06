#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@lab:~/agents$ is what ana typed and what it
# printed. What is STAGED rather than typed, and not shown in the lesson: the
# lab itself (lab.sh reset), and the files ana wrote (put below), whose
# contents the lesson shows in full.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE.
# The draft the assistant writes, which tool the agent calls with which
# arguments, and its final answers are rules in lab/scripted/01-*.json. The
# programs, the SDK, the requests, the tool results and the search are real.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, with LAB_TODAY=2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/agents, and what it printed.
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/agents, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/agents from nothing.
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null

block lab-check
on 'curl -s http://127.0.0.1:8600/; echo'
on 'ls data'
on 'du -sh /opt/agents/share /opt/agents/lib'
on 'du -sh /opt/agents/lib/python3.11/site-packages/claude_agent_sdk'
on 'python -c "import shop; print(shop.get_order(\"M-1042\"))"'

put automation.py <<'PY'
"""Automation: the programmer wrote the path, and the program follows it."""
import sys
from datetime import date, timedelta

import shop

RETURN_DAYS = 30

order = shop.get_order(sys.argv[1])
if order["status"] != "delivered":
    print(f"{order['id']}: not delivered yet ({order['status']}), nothing to return")
else:
    last = date.fromisoformat(order["delivered_on"]) + timedelta(days=RETURN_DAYS)
    if shop.TODAY <= last:
        print(f"{order['id']}: can be returned until {last}")
    else:
        print(f"{order['id']}: the return window closed on {last}")
PY

block automation
on 'python automation.py M-1042'
on 'python automation.py M-1044'
on 'python automation.py M-1043'
on 'python automation.py "the book I bought last week"'

put assistant.py <<'PY'
"""Assistant: one request. The model writes a draft, and a person decides what to send."""
import json
import sys

import anthropic

articles = [json.loads(line) for line in open("data/help.jsonl")]
handbook = "\n\n".join(f"# {a['title']}\n{a['body']}" for a in articles)

client = anthropic.Anthropic()
reply = client.messages.create(
    model="scripted-1",
    max_tokens=1024,
    system="You draft replies for Marginalia's support team. The help centre follows.\n\n" + handbook,
    messages=[{"role": "user", "content": sys.argv[1]}],
)
print(reply.content[0].text)
PY

block assistant
on 'python assistant.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"'

put agent.py <<'PY'
"""Agent: the model chooses the next step, the program runs it, until the model answers."""
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
SYSTEM = "You answer Marginalia's customers. Use the tools to find facts, and never guess an order's details."

client = anthropic.Anthropic()
messages = [{"role": "user", "content": sys.argv[1]}]
for step in range(1, 6):
    reply = client.messages.create(model="scripted-1", max_tokens=1024, system=SYSTEM,
                                   tools=TOOLS, messages=messages)
    messages.append({"role": "assistant", "content": reply.content})
    if reply.stop_reason != "tool_use":
        print(f"[{step}] answer: {reply.content[0].text}")
        break
    results = []
    for block in reply.content:
        if block.type == "tool_use":
            print(f"[{step}] {block.name}({json.dumps(block.input)})")
            output = RUN[block.name](block.input)
            results.append({"type": "tool_result", "tool_use_id": block.id, "content": json.dumps(output)})
    messages.append({"role": "user", "content": results})
PY

block agent-return
on 'python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"'
block agent-late
on 'python agent.py "My order M-1043 has not arrived yet. Where is it?"'
block agent-pay
on 'python agent.py "Which ways can I pay?"'

block requests
on "python -c 'import json; [print(r[\"n\"], r[\"rule\"], r[\"usage\"][\"input_tokens\"], r[\"usage\"][\"output_tokens\"]) for r in map(json.loads, open(\"/var/log/labllm/requests.jsonl\"))]'"
