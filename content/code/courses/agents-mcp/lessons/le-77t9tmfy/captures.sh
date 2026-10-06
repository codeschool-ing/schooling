#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of agents-mcp, as a script that
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
# as rules in lab/scripted/04-*.json. That includes the arguments that fail
# validation: the course wrote a model that sends "1043" without its prefix
# and "five" for a number, to show what the host does with them. The schemas,
# the validation messages, the tools, the errors, the three SDKs and what
# they put on the wire are real.
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

put tools.py <<'PY'
"""Marginalia's tools for the model: each a schema the model reads and a function the host runs."""
import json
from pathlib import Path

from jsonschema import Draft202012Validator

import shop

GENRES = sorted({json.loads(line)["genre"] for line in open("data/books.jsonl")})

TOOLS = [
    {"name": "get_order",
     "description": ("Look up one Marginalia order by its id, which is M- followed by four digits, such as M-1042. "
                     "Returns status, dates, lines and amounts in cents."),
     "input_schema": {"type": "object", "additionalProperties": False, "required": ["order_id"],
                      "properties": {"order_id": {"type": "string", "pattern": "^M-[0-9]{4}$"}}}},
    {"name": "find_books",
     "description": "List books Marginalia has in stock in one genre, cheapest first, with prices in cents.",
     "input_schema": {"type": "object", "additionalProperties": False, "required": ["genre"],
                      "properties": {"genre": {"type": "string", "enum": GENRES},
                                     "max_results": {"type": "integer", "minimum": 1, "maximum": 10}}}},
    {"name": "issue_refund",
     "description": ("Refund part or all of an order, in cents. Send the same idempotency_key again to retry "
                     "safely: a key already used returns the first result and refunds nothing more."),
     "input_schema": {"type": "object", "additionalProperties": False,
                      "required": ["order_id", "cents", "reason", "idempotency_key"],
                      "properties": {"order_id": {"type": "string", "pattern": "^M-[0-9]{4}$"},
                                     "cents": {"type": "integer", "minimum": 1},
                                     "reason": {"type": "string", "minLength": 3},
                                     "idempotency_key": {"type": "string", "minLength": 8}}}},
]
VALIDATORS = {t["name"]: Draft202012Validator(t["input_schema"]) for t in TOOLS}
KEYS = Path("data/refund_keys.json")


def find_books(genre, max_results=3):
    books = [shop.get_book(json.loads(line)["id"]) for line in open("data/books.jsonl")]
    stocked = [b for b in books if b["genre"] == genre and b["stock"] > 0]
    stocked.sort(key=lambda b: b["cents"])
    return [{"id": b["id"], "title": b["title"], "author": b["author"], "cents": b["cents"]}
            for b in stocked[:max_results]]


def issue_refund(order_id, cents, reason, idempotency_key):
    done = json.loads(KEYS.read_text()) if KEYS.exists() else {}
    if idempotency_key in done:
        return dict(done[idempotency_key], note="already processed with this key; nothing refunded now")
    result = shop.refund(order_id, cents, reason, approved_by="agent")
    done[idempotency_key] = result
    KEYS.write_text(json.dumps(done))
    return result


RUN = {"get_order": shop.get_order, "find_books": find_books, "issue_refund": issue_refund}


def run_tool(name, args):
    """(text for the model, is_error). Nothing reaches a function before its arguments pass the schema."""
    if name not in RUN:
        return f"unknown tool {name!r}; the tools are {', '.join(RUN)}", True
    problems = sorted(VALIDATORS[name].iter_errors(args), key=lambda e: list(e.path))
    if problems:
        return "invalid arguments: " + "; ".join(
            f"{'/'.join(map(str, p.path)) or 'arguments'}: {p.message}" for p in problems), True
    try:
        return json.dumps(RUN[name](**args)), False
    except (LookupError, ValueError) as e:
        return f"{type(e).__name__}: {e}", True
PY

block validate
on 'python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"1043\"}))"'
on 'python -c "from tools import run_tool; print(run_tool(\"find_books\", {\"genre\": \"mystery\", \"max_results\": \"five\"}))"'
on 'python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"M-1043\", \"verbose\": True}))"'
on 'python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"M-9999\"}))"'
on 'python -c "from tools import run_tool; print(run_tool(\"cancel_order\", {\"order_id\": \"M-1045\"}))"'

put agent.py <<'PY'
"""The lesson 1 loop, with the tools of tools.py: every call validated, every failure returned as an error."""
import json
import sys

import anthropic

from tools import TOOLS, run_tool

SYSTEM = ("You are Marginalia's support agent. Use the tools to find facts; "
          "if a tool returns an error, read it and correct the call.")
DROP_ONE = "--drop-one" in sys.argv

client = anthropic.Anthropic()
messages = [{"role": "user", "content": sys.argv[1]}]
for step in range(1, 6):
    reply = client.messages.create(model="scripted-1", max_tokens=1024, system=SYSTEM,
                                   tools=TOOLS, messages=messages)
    messages.append({"role": "assistant", "content": reply.content})
    if reply.stop_reason != "tool_use":
        print(f"[{step}] answer: {reply.content[-1].text}")
        break
    results = []
    for block in reply.content:
        if block.type == "tool_use":
            text, is_error = run_tool(block.name, block.input)
            print(f"[{step}] {block.name}({json.dumps(block.input)}) -> {'ERROR ' if is_error else ''}{text[:70]}")
            results.append({"type": "tool_result", "tool_use_id": block.id, "content": text, "is_error": is_error})
    if DROP_ONE:
        results = results[:1]
    messages.append({"role": "user", "content": results})
PY

block agent-pattern
on 'python agent.py "Where is my order 1043?"'
block agent-type
on 'python agent.py "Which mystery novels do you have in stock?"'
block agent-missing
on 'python agent.py "What happened to my order M-9999?"'
block parallel
on 'python agent.py "What is the status of my orders M-1043 and M-1048?"'
block parallel-drop
on 'python agent.py "What is the status of my orders M-1043 and M-1048?" --drop-one 2>&1 | tail -n 1'

block idempotency
on 'python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-refund\"}))"'
on 'python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-refund\"}))"'
on 'python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-again\"}))"'

put wires.py <<'PY'
"""One tool, one question, three providers' SDKs: what each one sends and gets back."""
import json

import anthropic
import openai
from google import genai
from google.genai import types

NAME, DESCRIPTION = "get_order", "Look up one Marginalia order by its id, such as M-1042."
SCHEMA = {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}
QUESTION = "Where is order M-1043?"

a = anthropic.Anthropic().messages.create(
    model="scripted-1", max_tokens=200, messages=[{"role": "user", "content": QUESTION}],
    tools=[{"name": NAME, "description": DESCRIPTION, "input_schema": SCHEMA}])
call = next(b for b in a.content if b.type == "tool_use")
print("anthropic ", a.stop_reason, call.name, json.dumps(call.input), call.id)

o = openai.OpenAI().chat.completions.create(
    model="scripted-1", messages=[{"role": "user", "content": QUESTION}],
    tools=[{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}])
call = o.choices[0].message.tool_calls[0]
print("openai    ", o.choices[0].finish_reason, call.function.name, call.function.arguments, call.id)

gemini = genai.Client(http_options=types.HttpOptions(base_url="http://127.0.0.1:8600"))
g = gemini.models.generate_content(
    model="scripted-1", contents=QUESTION,
    config=types.GenerateContentConfig(tools=[types.Tool(function_declarations=[
        types.FunctionDeclaration(name=NAME, description=DESCRIPTION, parameters_json_schema=SCHEMA)])]))
call = g.candidates[0].content.parts[0].function_call
print("gemini    ", g.candidates[0].finish_reason.name, call.name, json.dumps(call.args), call.id)
PY

block wires
on 'python wires.py'
on "tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r[\"path\"].split(\"/\")[-1][:28].ljust(28), json.dumps(r[\"request\"][\"tools\"])[:118]) for r in map(json.loads, sys.stdin)]'"
