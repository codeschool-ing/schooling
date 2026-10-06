#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full; emptying labllm's log before the runs whose requests are read, done as
# root because the log belongs to the labllm user; and the answers a person
# typed at the approval prompts, fed on standard input; and removing the
# session files the earlier blocks left, before the session block counts them.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE,
# as rules in lab/scripted/09-claude-agent-sdk.json. The Claude Agent SDK
# (claude-agent-sdk 0.2.163, which bundles the Claude Code CLI 2.1.286), the
# subprocess it starts, what that subprocess sent on the wire, its tool list,
# its permission decisions and their messages, the hooks, the cost it
# estimated, the turn limit and the session files are real. The CLI warns
# once per run that it does not recognise the model name; that line goes to
# standard error and is dropped below, and the lesson says so.
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 stops the CLI's own background
# requests (update checks and the like), which would otherwise go to a
# network this lab cannot reach.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, with LAB_TODAY=2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1; { $*; } 2>&1 | grep -v 'unrecognized_model'" || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
fresh_log() { : > /var/log/labllm/requests.jsonl; }
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put cs_tools.py <<'PY'
"""Marginalia's tools for the Claude Agent SDK: an MCP server that runs inside this process."""
import json

from claude_agent_sdk import create_sdk_mcp_server, tool

import shop


def text(value):
    return {"content": [{"type": "text", "text": json.dumps(value, ensure_ascii=False)}]}


@tool("get_order", "Look up one Marginalia order by its id, M- and four digits. "
      "Returns status, dates, lines and amounts in cents.", {"order_id": str})
async def get_order(args):
    return text(shop.get_order(args["order_id"]))


@tool("search_help", "Search Marginalia's help centre by meaning and return the three closest articles.",
      {"query": str})
async def search_help(args):
    return text([{"title": a["title"], "body": a["body"]} for a in shop.search_help(args["query"])])


@tool("refund", "Refund part or all of an order to the customer's original payment, in cents.",
      {"order_id": str, "cents": int, "reason": str})
async def refund(args):
    return text(shop.refund(args["order_id"], args["cents"], args["reason"], approved_by="ana"))


shop_server = create_sdk_mcp_server("shop", version="1.0.0", tools=[get_order, search_help, refund])
PY

put cs_show.py <<'PY'
"""Print the SDK's message stream one line per message, shortened for reading."""
from claude_agent_sdk import (AssistantMessage, ResultMessage, SystemMessage, TextBlock,
                              ToolResultBlock, ToolUseBlock, UserMessage)


def show(m):
    if isinstance(m, SystemMessage):
        extra = f" tools={len(m.data['tools'])}" if m.subtype == "init" else ""
        print(f"system     {m.subtype}{extra}")
    elif isinstance(m, AssistantMessage):
        for b in m.content:
            if isinstance(b, ToolUseBlock):
                print(f"assistant  tool_use {b.name} {b.input}")
            elif isinstance(b, TextBlock):
                print(f"assistant  {b.text}")
    elif isinstance(m, UserMessage):
        for b in m.content if isinstance(m.content, list) else []:
            if isinstance(b, ToolResultBlock):
                body = b.content if isinstance(b.content, str) else b.content[0]["text"]
                print(f"user       tool_result{' (error)' if b.is_error else ''} {body[:90]}")
    elif isinstance(m, ResultMessage):
        print(f"result     {m.subtype} turns={m.num_turns} {m.duration_ms} ms "
              f"cost_usd={m.total_cost_usd:.4f} session={m.session_id[:8]}")
PY

put cs_run.py <<'PY'
"""The first agent with the Claude Agent SDK, in three configurations."""
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, ClaudeSDKError, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You answer Marginalia's customers in the Claude Agent SDK lesson. Use the tools; never guess."


def options(how):
    o = ClaudeAgentOptions(model="scripted-1", system_prompt=SYSTEM,
                           mcp_servers={"shop": shop_server},
                           allowed_tools=["mcp__shop__get_order", "mcp__shop__search_help"])
    if how in ("no-builtins", "isolated", "one-turn"):
        o.tools = []                # none of Claude Code's own tools: only the shop's
    if how in ("isolated", "one-turn"):
        o.setting_sources = []      # read no settings files and no CLAUDE.md
    if how == "one-turn":
        o.max_turns = 1
    return o


async def main(how, task):
    try:
        async for message in query(prompt=task, options=options(how)):
            show(message)
    except ClaudeSDKError as e:
        print(f"raised     {type(e).__name__}: {e}")


anyio.run(main, sys.argv[1], sys.argv[2])
PY

put wire.py <<'PY'
"""What each request in labllm's log carried: tools offered, their names, and tokens in."""
import json

for n, line in enumerate(open("/var/log/labllm/requests.jsonl"), 1):
    r = json.loads(line)
    tools = [t["name"] for t in r["request"].get("tools", [])]
    u = r["usage"]
    tokens_in = u["input_tokens"] + u.get("cache_creation_input_tokens", 0) + u.get("cache_read_input_tokens", 0)
    print(f"request {n}: {len(tools):2} tools, {tokens_in:6} tokens in  {', '.join(tools[:6])}"
          + (", ..." if len(tools) > 6 else ""))
PY

put cs_refund.py <<'PY'
"""A refund under four permission arrangements."""
import json
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, HookMatcher, PermissionResultAllow, PermissionResultDeny, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You handle refunds for Marginalia's customers in the Claude Agent SDK lesson."
LIMIT = 5000  # cents; above this a refund is refused in code and no person is asked


async def ask_a_person(tool_name, tool_input, context):
    print(f"approve?   {tool_name} {tool_input} [y/n] ", end="", flush=True)
    answer = sys.stdin.readline().strip()
    print(answer)
    if answer == "y":
        return PermissionResultAllow()
    return PermissionResultDeny(message="Not approved by staff. A colleague will review this refund.")


async def audit_and_limit(hook_input, tool_use_id, context):
    with open("audit.jsonl", "a") as f:
        f.write(json.dumps({"tool": hook_input["tool_name"], "input": hook_input["tool_input"]}) + "\n")
    if hook_input["tool_name"] == "mcp__shop__refund" and hook_input["tool_input"]["cents"] > LIMIT:
        return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                       "permissionDecisionReason": f"Refunds above {LIMIT} cents need a manager."}}
    return {}


async def main(how, task):
    o = ClaudeAgentOptions(model="scripted-1", system_prompt=SYSTEM, mcp_servers={"shop": shop_server},
                           tools=[], setting_sources=[], allowed_tools=["mcp__shop__get_order"])
    if how == "dont-ask":
        o.permission_mode = "dontAsk"
    if how in ("ask", "hooked"):
        o.permission_mode = "default"
        o.can_use_tool = ask_a_person
    if how == "hooked":
        o.hooks = {"PreToolUse": [HookMatcher(matcher="mcp__shop__.*", hooks=[audit_and_limit])]}
    async for message in query(prompt=task, options=o):
        show(message)


anyio.run(main, sys.argv[1], sys.argv[2])
PY

put cs_session.py <<'PY'
"""Two messages from one customer: separate runs, then the second resuming the first."""
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You answer Marginalia's customers in the Claude Agent SDK lesson."


async def turn(text, resume=None):
    o = ClaudeAgentOptions(model="scripted-1", system_prompt=SYSTEM, mcp_servers={"shop": shop_server},
                           tools=[], setting_sources=[], resume=resume,
                           allowed_tools=["mcp__shop__get_order", "mcp__shop__search_help"])
    session = None
    async for message in query(prompt=text, options=o):
        show(message)
        if isinstance(message, ResultMessage):
            session = message.session_id
    return session


async def main(how):
    first = await turn("Hello, this is Bia. When was my order M-1042 delivered?")
    print("---")
    await turn("Can I still return it?", resume=first if how == "resume" else None)


anyio.run(main, sys.argv[1])
PY

block bundled
on 'CLI=$(python -c "import claude_agent_sdk, pathlib; print(pathlib.Path(claude_agent_sdk.__file__).parent / \"_bundled/claude\")"); du -h $CLI; $CLI --version'

block first-run
fresh_log
on 'python cs_run.py default "Where is my order M-1043?"'

block first-wire
on 'python wire.py'

block no-builtins
fresh_log
on 'python cs_run.py no-builtins "Where is my order M-1043?"'
on 'python wire.py'

block claude-md
printf 'Sign every reply as "The Marginalia team".\n' | put CLAUDE.md
on 'cat CLAUDE.md'
fresh_log
on 'python cs_run.py no-builtins "Where is my order M-1043?" > /dev/null; python wire.py; grep -c "The Marginalia team" /var/log/labllm/requests.jsonl'
fresh_log
on 'python cs_run.py isolated "Where is my order M-1043?" > /dev/null; python wire.py; grep -c "The Marginalia team" /var/log/labllm/requests.jsonl'
lab exec 'rm CLAUDE.md'

block auto
fresh_log
on 'python cs_refund.py default "One copy of M-1047 arrived damaged; please refund it."'
on "python -c 'import json; [print(r[\"status\"], r[\"request\"][\"model\"], r[\"request\"][\"system\"][1][\"text\"].splitlines()[0]) for r in map(json.loads, open(\"/var/log/labllm/requests.jsonl\"))]' | sort | uniq -c"

block dont-ask
fresh_log
on 'python cs_refund.py dont-ask "One copy of M-1047 arrived damaged; please refund it."'
on "python -c 'import json; [print(b[\"content\"]) for r in map(json.loads, open(\"/var/log/labllm/requests.jsonl\")) for m in r[\"request\"][\"messages\"] if isinstance(m[\"content\"], list) for b in m[\"content\"] if b.get(\"type\") == \"tool_result\"]' | head -1"

block ask
on 'echo n | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."'
on 'echo y | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."'
on "python -c 'import sqlite3; print(sqlite3.connect(\"data/shop.db\").execute(\"SELECT order_id, cents, approved_by FROM refunds\").fetchall())'"

block hooked
on 'echo n | python cs_refund.py hooked "Please refund the whole order M-1047."'
on 'python cs_refund.py hooked "Where is my order M-1043?" | tail -1'
on 'cat audit.jsonl'

block one-turn
on 'python cs_run.py one-turn "Where is my order M-1043?"'

block session
lab exec 'rm -rf ~/.claude/projects'
on 'python cs_session.py separate'
on 'python cs_session.py resume'
on 'ls ~/.claude/projects/-home-ana-agents/ | wc -l; grep -l "this is Bia" ~/.claude/projects/-home-ana-agents/*.jsonl | wc -l'
