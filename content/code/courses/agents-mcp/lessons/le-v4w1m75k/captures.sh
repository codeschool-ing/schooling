#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); tools.py (lesson 4's) and standin.py (lesson 3's), written
# again unchanged; and the files ana wrote (put below), which the lesson shows
# in full, each checked by lab/shown.py.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, on 4 CPUs and no graphics chip, captured on 2026-10-08.
# Its plans, calls and words are what it wrote that day, and the times are
# this machine's. Where a run shows the stand-in instead, its replies are the
# JSON file the lesson shows beside it.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
sed -n "/^put tools.py <<'PY'$/,/^PY$/p" ../le-77t9tmfy/captures.sh | sed '1d;$d' | put tools.py
put standin.py < ../../lab/work/standin.py

put agent.py <<'PY'
"""An agent that keeps a written plan, answers through finish, and runs inside a budget set by the host."""
import argparse
import json
import time

import anthropic

from jsonschema import Draft202012Validator

from tools import TOOLS as SHOP_TOOLS, run_tool

PLAN_TOOLS = [
    {"name": "update_plan",
     "description": "Write or rewrite your plan: the whole list of steps, each with a status.",
     "input_schema": {"type": "object", "additionalProperties": False, "required": ["steps"],
                      "properties": {"steps": {"type": "array", "minItems": 1, "maxItems": 8, "items": {
                          "type": "object", "additionalProperties": False, "required": ["step", "status"],
                          "properties": {"step": {"type": "string"},
                                         "status": {"enum": ["todo", "done", "dropped"]}}}}}}},
    {"name": "finish",
     "description": "Give the final answer to the customer, and list the tool calls it rests on.",
     "input_schema": {"type": "object", "additionalProperties": False, "required": ["answer", "sources"],
                      "properties": {"answer": {"type": "string", "minLength": 1},
                                     "sources": {"type": "array", "items": {"type": "string"}}}}},
]
TOOLS = [t for t in SHOP_TOOLS if t["name"] != "issue_refund"] + PLAN_TOOLS
CHECK = {t["name"]: Draft202012Validator(t["input_schema"]) for t in PLAN_TOOLS}
SYSTEM = ("You are Marginalia's support agent. Keep a plan with update_plan before you start and whenever "
          "it changes. Use the tools to find facts. When you know the answer, call finish.")
MARKS = {"todo": " ", "done": "x", "dropped": "-"}


def stopped(reason, plan):
    """A run that did not finish still returns something a person can pick up."""
    done = [s["step"] for s in plan if s["status"] == "done"]
    todo = [s["step"] for s in plan if s["status"] == "todo"]
    return {"status": "stopped", "reason": reason, "done": done, "not_done": todo,
            "handoff": "Passed to a person. " + (f"Done: {'; '.join(done)}. " if done else "")
                       + (f"Not done: {'; '.join(todo)}." if todo else "No plan was written.")}


def run(task, max_steps, max_tokens, max_seconds):
    client = anthropic.Anthropic()
    messages = [{"role": "user", "content": task}]
    plan, used, started = [], 0, time.monotonic()
    for step in range(1, max_steps + 1):
        if used >= max_tokens:
            return stopped(f"token budget: {used} of {max_tokens} used", plan)
        if time.monotonic() - started >= max_seconds:
            return stopped(f"time budget: {max_seconds} s", plan)
        reply = client.messages.create(model="llama3.2:3b", max_tokens=1024, system=SYSTEM,
                                       tools=TOOLS, messages=messages)
        used += reply.usage.input_tokens + (reply.usage.cache_read_input_tokens or 0) + reply.usage.output_tokens
        messages.append({"role": "assistant", "content": reply.content})
        results = []
        for block in reply.content:
            if block.type != "tool_use":
                continue
            problem = next(CHECK[block.name].iter_errors(block.input), None) if block.name in CHECK else None
            if problem:
                text, is_error = f"invalid arguments: {problem.message}", True
                print(f"[{step}] {block.name} -> ERROR {text}")
            elif block.name == "finish":
                return {"status": "answered", "steps": step, "tokens": used,
                        "answer": block.input["answer"], "sources": block.input["sources"]}
            elif block.name == "update_plan":
                plan = block.input["steps"]
                print(f"[{step}] plan")
                for s in plan:
                    print(f"      [{MARKS[s['status']]}] {s['step']}")
                text, is_error = "plan recorded", False
            else:
                text, is_error = run_tool(block.name, block.input)
                print(f"[{step}] {block.name}({json.dumps(block.input)}) -> {'ERROR ' if is_error else ''}{text[:60]}")
            results.append({"type": "tool_result", "tool_use_id": block.id, "content": text, "is_error": is_error})
        if not results:
            return stopped("replied without calling finish", plan)
        messages.append({"role": "user", "content": results})
    return stopped(f"step limit: {max_steps}", plan)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("task")
    p.add_argument("--max-steps", type=int, default=8)
    p.add_argument("--max-tokens", type=int, default=20000)
    p.add_argument("--max-seconds", type=float, default=60)
    a = p.parse_args()
    print(json.dumps(run(a.task, a.max_steps, a.max_tokens, a.max_seconds), indent=1, ensure_ascii=False))
PY

GIFT="I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?"
block plan
on "python agent.py \"$GIFT\""
block step-limit
on "python agent.py \"$GIFT\" --max-steps 1"
block token-budget
on "python agent.py \"$GIFT\" --max-tokens 500"
block time-budget
recorder
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11435'
on "python agent.py \"$GIFT\" --max-seconds 2"
on "python -c 'import json; [print(r[\"usage\"][\"output_tokens\"], \"output tokens in\", r[\"ms\"], \"ms\") for r in map(json.loads, open(\"requests.jsonl\"))]'"
block replan
on 'python agent.py "Is my order M-1049 delivered, and can I still return it?"'

put plan.json <<'JSON'
{"adventure stories": [
  {"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1045", "status": "todo"},
    {"step": "Find adventure books in stock", "status": "todo"},
    {"step": "Answer both questions", "status": "todo"}]}},
  {"tool": "get_order", "input": {"order_id": "M-1045"}},
  [{"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1045", "status": "done"},
    {"step": "Find adventure books in stock", "status": "todo"},
    {"step": "Answer both questions", "status": "todo"}]}},
   {"tool": "find_books", "input": {"genre": "adventure"}}],
  {"tool": "finish", "input": {
    "answer": "Your order M-1045 is packed and will leave our warehouse soon; the tracking link comes by email when it ships. For a nephew who likes adventure, we have Moby-Dick by Herman Melville at 49.90 and The Count of Monte Cristo by Alexandre Dumas at 59.90 in stock.",
    "sources": ["get_order M-1045", "find_books adventure"]}}
 ],
 "M-1049": [
  {"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1049", "status": "todo"},
    {"step": "Check the return window", "status": "todo"},
    {"step": "Answer", "status": "todo"}]}},
  {"tool": "get_order", "input": {"order_id": "M-1049"}},
  {"tool": "update_plan", "input": {"steps": [
    {"step": "Look up order M-1049", "status": "done"},
    {"step": "Check the return window", "status": "dropped"},
    {"step": "Ask the customer for the order number", "status": "todo"}]}},
  {"tool": "finish", "input": {
    "answer": "I cannot find an order M-1049, so I cannot check its return window yet. Could you send the order number from your confirmation email? It starts with M- and has four digits.",
    "sources": ["get_order M-1049"]}}
 ]
}
JSON

block standin-plan
quiet
on 'python standin.py plan.json &'
sleep 1
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11436'
on "python agent.py \"$GIFT\""
block standin-step-limit
on "python agent.py \"$GIFT\" --max-steps 3"
block standin-replan
on 'python agent.py "Is my order M-1049 delivered, and can I still return it?"'
