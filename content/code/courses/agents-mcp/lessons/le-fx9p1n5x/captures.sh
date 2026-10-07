#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: ana, ~/agents, the venv, the models
#   sudo bash captures.sh
#
# A line that starts with ana@lab:~/agents$ is what ana typed and what it
# printed. What is STAGED rather than typed, and not shown in the lesson: the
# lab itself (lab.sh reset), and the files ana wrote (put below). Every put
# is checked by ../../lab/shown.py against the lesson's fences before it runs.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, captured on 2026-10-07. Its words, and which tool it
# called, are what it said that day; a second run may word them differently.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
SHOWN=${SHOWN:-../../lab/shown.py}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/agents, and what it printed.
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/agents, from stdin. It must be shown whole in a lesson.
put() {
  local t; t=$(mktemp); cat > "$t"
  python3 "$SHOWN" "$t" || { rm -f "$t"; exit 1; }
  lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'" < "$t"; rm -f "$t"
}
# on_tty 'command': the same, for a program that draws for a terminal (ollama run's
# spinner). Its control codes are removed, leaving what a terminal shows.
on_tty() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$*" < /dev/null 2>&1 | python3 -c '
import re, sys
t = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]|[\u2800-\u28ff] ?", "", sys.stdin.read())
print(t.strip("\n"))' || true; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/agents from nothing.
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null

block lab-check
on 'python --version'
on 'ollama --version'
on 'ollama list'
on 'python make_shop.py'
on 'ls data'
on 'python -c "import shop; print(shop.get_order(\"M-1042\"))"'
on_tty 'ollama run llama3.2:3b "Say hello in five words."'
on 'ollama ps'
on 'du -sh .venv'

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
    model="llama3.2:3b",
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
    reply = client.messages.create(model="llama3.2:3b", max_tokens=1024, system=SYSTEM,
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
on 'python recorder.py &'
sleep 1
on 'ANTHROPIC_BASE_URL=http://127.0.0.1:11435 python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"'
on "python -c 'import json; [print(n, r[\"usage\"][\"input_tokens\"], r[\"usage\"][\"cached_tokens\"], r[\"usage\"][\"output_tokens\"], r[\"ms\"]) for n, r in enumerate(map(json.loads, open(\"requests.jsonl\")), 1)]'"
lab exec 'pkill -u ana -f "python recorder.py"' || true

block failures
on 'ANTHROPIC_BASE_URL=http://127.0.0.1:11435 python agent.py "Which ways can I pay?" 2>&1 | tail -n 1'
on 'python3.11 -c "import shop; print(shop.search_help(\"returns\"))" 2>&1 | tail -n 1'
on_tty 'ollama run llama3.2:3x "Hello"'
on 'ollama ps'
