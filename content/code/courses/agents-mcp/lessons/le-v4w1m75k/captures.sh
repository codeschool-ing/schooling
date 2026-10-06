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
# (lab.sh reset); tools.py, which is lesson 4's, written again unchanged; and
# agent.py, which the lesson shows in full.
#
# THE MODEL'S PLANS, CALLS AND ANSWERS IN THIS LESSON WERE WRITTEN BY THE
# COURSE, as rules in lab/scripted/05-*.json. The budget, the limits, the
# validation, the tools and the outcomes the host prints are real. The time a
# request takes is labllm's rule (200 ms, then 40 ms a token), so the run
# stopped by --max-seconds stops where that rule puts it.
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
sed -n "/^put tools.py <<'PY'$/,/^PY$/p" ../le-77t9tmfy/captures.sh | sed '1d;$d' | put tools.py

put agent.py <<'PY'
"""An agent that keeps a written plan, answers through finish, and runs inside a budget set by the host."""
import argparse
import json
import time

import anthropic

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
        reply = client.messages.create(model="scripted-1", max_tokens=1024, system=SYSTEM,
                                       tools=TOOLS, messages=messages)
        used += reply.usage.input_tokens + reply.usage.output_tokens
        messages.append({"role": "assistant", "content": reply.content})
        results = []
        for block in reply.content:
            if block.type != "tool_use":
                continue
            if block.name == "finish":
                return {"status": "answered", "steps": step, "tokens": used,
                        "answer": block.input["answer"], "sources": block.input["sources"]}
            if block.name == "update_plan":
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
on "python agent.py \"$GIFT\" --max-steps 3"
block token-budget
on "python agent.py \"$GIFT\" --max-tokens 1500"
block time-budget
on "python agent.py \"$GIFT\" --max-seconds 1"
on "tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r[\"usage\"][\"output_tokens\"], \"output tokens in\", r[\"ms\"], \"ms\")'"
block replan
on 'python agent.py "Is my order M-1049 delivered, and can I still return it?"'
