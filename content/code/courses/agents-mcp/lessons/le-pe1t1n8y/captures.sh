#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); tools.py, which is lesson 4's, written again unchanged; and
# the files ana wrote (put below), which the lesson shows in full, each
# checked by lab/shown.py.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, captured on 2026-10-08. Every agent in this lesson is
# that one model with a different system prompt and different tools; their
# delegations, transfers, summaries and answers are what it wrote that day.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
sed -n "/^put tools.py <<'PY'$/,/^PY$/p" ../le-77t9tmfy/captures.sh | sed '1d;$d' | put tools.py
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put multi.py <<'PY'
"""Several agents: an orchestrator that delegates to specialists, a triage agent that hands over, or one agent alone."""
import json
import sys

import anthropic

import shop
from tools import TOOLS as SHOP_TOOLS, run_tool

client = anthropic.Anthropic()
BY_NAME = {t["name"]: t for t in SHOP_TOOLS}
SEARCH_HELP = {"name": "search_help", "description": "Search Marginalia's help centre and return the three closest articles.",
               "input_schema": {"type": "object", "additionalProperties": False, "required": ["query"],
                                "properties": {"query": {"type": "string"}}}}
QUESTION = {"type": "object", "additionalProperties": False, "required": ["question"],
            "properties": {"question": {"type": "string"}}}
EVIDENCE = "--evidence" in sys.argv


def shop_tool(name, args):
    if name == "search_help":
        return json.dumps([{"title": a["title"], "body": a["body"]} for a in shop.search_help(args["query"])]), False
    return run_tool(name, args)


def loop(name, system, tools, messages, run, depth=0):
    """One agent: its own system prompt, its own tools, its own conversation. Returns (answer, evidence)."""
    pad, evidence = "    " * depth, []
    for step in range(1, 6):
        reply = client.messages.create(model="llama3.2:3b", max_tokens=1024, system=system,
                                       tools=tools, messages=messages)
        messages.append({"role": "assistant", "content": reply.content})
        calls = [b for b in reply.content if b.type == "tool_use"]
        if not calls:
            answer = " ".join(b.text for b in reply.content if b.type == "text")
            print(f"{pad}{name}: {answer}")
            return answer, evidence
        results = []
        for b in calls:
            print(f"{pad}{name} -> {b.name}({json.dumps(b.input)})")
            text, is_error = run(b.name, b.input, depth)
            evidence.append(f"{b.name} {json.dumps(b.input)} -> {text[:110]}")
            results.append({"type": "tool_result", "tool_use_id": b.id, "content": text, "is_error": is_error})
        messages.append({"role": "user", "content": results})
    return f"{name} stopped after 5 steps", evidence


SPECIALISTS = {
    "orders": ("You are Marginalia's orders specialist. Answer the question about orders with your tools, "
               "in two sentences at most.", [BY_NAME["get_order"], SEARCH_HELP]),
    "catalogue": ("You are Marginalia's catalogue specialist. Answer the question about books with your tools, "
                  "in two sentences at most.", [BY_NAME["find_books"]]),
}


def ask(specialist, question, depth):
    """A specialist used as a tool: it gets the question only, and its answer is the tool's result."""
    system, tools = SPECIALISTS[specialist]
    answer, evidence = loop(specialist, system, tools, [{"role": "user", "content": question}],
                            lambda n, a, d: shop_tool(n, a), depth + 1)
    if EVIDENCE:
        answer += "\nEvidence:\n" + "\n".join(evidence)
    return answer, False


def orchestrate(task):
    tools = [{"name": "ask_orders", "description": "Ask the orders specialist one question about orders.",
              "input_schema": QUESTION},
             {"name": "ask_catalogue", "description": "Ask the catalogue specialist one question about books.",
              "input_schema": QUESTION}]
    system = ("You are Marginalia's support orchestrator. Delegate: ask_orders for anything about an order, "
              "ask_catalogue for books. Then answer the customer.")
    loop("orchestrator", system, tools, [{"role": "user", "content": task}],
         lambda n, a, d: ask(n.removeprefix("ask_"), a["question"], d))


def triage(task):
    """Handoff: the triage agent transfers control, and the specialist answers the customer itself."""
    messages = [{"role": "user", "content": task}]
    tools = [{"name": f"transfer_to_{s}", "description": f"Hand this conversation to the {s} specialist.",
              "input_schema": {"type": "object", "properties": {}}} for s in SPECIALISTS]
    reply = client.messages.create(model="llama3.2:3b", max_tokens=200, tools=tools, messages=messages,
                                   system="You are Marginalia's triage agent. Transfer the conversation to the right specialist.")
    call = next(b for b in reply.content if b.type == "tool_use")
    target = call.name.removeprefix("transfer_to_")
    print(f"triage hands the conversation to {target}")
    system, specialist_tools = SPECIALISTS[target]
    loop(target, system, specialist_tools, [{"role": "user", "content": task}], lambda n, a, d: shop_tool(n, a))


def alone(task):
    tools = [BY_NAME["get_order"], SEARCH_HELP, BY_NAME["find_books"]]
    loop("agent", "You are Marginalia's support agent, working alone. Use the tools, then answer.", tools,
         [{"role": "user", "content": task}], lambda n, a, d: shop_tool(n, a))


if __name__ == "__main__":
    mode = "--handoff" in sys.argv and triage or "--single" in sys.argv and alone or orchestrate
    mode(sys.argv[1])
PY

put tally.py <<'PY'
"""Requests and tokens since requests.jsonl was emptied, per agent, told apart by their system prompts."""
import json
from collections import defaultdict

WHO = {"orchestrator": "orchestrator", "orders specialist": "orders", "catalogue specialist": "catalogue",
       "triage agent": "triage", "working alone": "agent"}
rows = defaultdict(lambda: [0, 0, 0])
for line in open("requests.jsonl"):
    r = json.loads(line)
    who = next(name for key, name in WHO.items() if key in (r["request"].get("system") or ""))
    rows[who][0] += 1
    rows[who][1] += r["usage"]["input_tokens"]
    rows[who][2] += r["usage"]["output_tokens"]
for who, (n, i, o) in rows.items():
    print(f"{who:13} requests {n}   input {i:5}   output {o:4}")
print(f"{'total':13} requests {sum(v[0] for v in rows.values())}   input {sum(v[1] for v in rows.values()):5}   "
      f"output {sum(v[2] for v in rows.values()):4}")
PY

Q="Did my order M-1043 ship yet? Also, can you suggest a science fiction book you have in stock?"
block orchestrator
recorder
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11435'
on "python multi.py \"$Q\""
block orchestrator-cost
on 'python tally.py'
block single
on 'rm requests.jsonl'
on "python multi.py \"$Q\" --single"
on 'python tally.py'
block handoff
on 'rm requests.jsonl'
on 'python multi.py "My order M-1046 still has not shipped. What can I do?" --handoff'
on 'python tally.py'
block telephone
on 'python multi.py "Are both of my orders, M-1043 and M-1048, on their way?"'
block evidence
on 'rm requests.jsonl'
on 'python multi.py "Are both of my orders, M-1043 and M-1048, on their way?" --evidence'
on "python -c 'import json; r = [json.loads(l)[\"request\"] for l in open(\"requests.jsonl\")]; o = [x for x in r if \"orchestrator\" in x[\"system\"]][-1]; [print(b[\"content\"]) for b in o[\"messages\"][-1][\"content\"]]'"
