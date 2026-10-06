#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full; and emptying labllm's log before the runs whose requests are read,
# done as root because the log belongs to the labllm user.
#
# THE MODEL'S WORDS AND DECISIONS IN THIS LESSON WERE WRITTEN BY THE COURSE,
# as rules in lab/scripted/11-mcp-problem.json. The MCP server (mcp 2.3.0),
# the three hosts and their MCP clients (openai-agents 0.23.1, claude-agent-sdk
# 0.2.163 with the Claude Code CLI 2.1.286, google-adk 2.11.0), every message
# each client sent the server, and every request each host sent labllm are
# real. Python's UserWarnings and the Claude Code CLI's warning about the model
# name go to standard error, which these commands drop; the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, with LAB_TODAY=2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1; $*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
fresh_log() { : > /var/log/labllm/requests.jsonl; }
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put shop_mcp.py <<'PY'
"""Marginalia's order lookup as an MCP server: written once, for any host."""
import json

from mcp.server.mcpserver import MCPServer

import shop

server = MCPServer("marginalia-shop")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."""
    return json.dumps(shop.get_order(order_id))


if __name__ == "__main__":
    server.run()  # stdio: one JSON-RPC message per line on standard input and output
PY

put hosts.py <<'PY'
"""The same MCP server, used by three hosts built with three libraries."""
import asyncio
import sys

TASK = "Where is my order M-1043?"


def server(host):
    """How to start the server. `tee` keeps a copy of everything the host's client sends it."""
    return {"command": "sh", "args": ["-c", f"tee {host}.in.jsonl | python shop_mcp.py"]}


async def openai_host():
    from agents import Agent, Runner, set_default_openai_api, set_tracing_disabled
    from agents.mcp import MCPServerStdio
    set_default_openai_api("chat_completions")
    set_tracing_disabled(True)
    async with MCPServerStdio(params=server("openai"), name="shop") as shop:
        agent = Agent(name="support", model="scripted-1", mcp_servers=[shop],
                      instructions="You are the OpenAI host of the MCP lesson.")
        print((await Runner.run(agent, TASK)).final_output)


async def claude_host():
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query
    options = ClaudeAgentOptions(model="scripted-1", system_prompt="You are the Claude host of the MCP lesson.",
                                 tools=[], setting_sources=[], allowed_tools=["mcp__shop__get_order"],
                                 mcp_servers={"shop": {"type": "stdio", **server("claude")}})
    async for message in query(prompt=TASK, options=options):
        if isinstance(message, ResultMessage):
            print(message.result)


async def google_host():
    from google.adk.agents import Agent
    from google.adk.models.google_llm import Gemini
    from google.adk.runners import InMemoryRunner
    from google.adk.tools.mcp_tool import McpToolset, StdioConnectionParams
    from google.genai.types import Content, Part
    from mcp import StdioServerParameters
    shop = McpToolset(connection_params=StdioConnectionParams(server_params=StdioServerParameters(**server("google"))))
    agent = Agent(name="support", model=Gemini(model="scripted-1", base_url="http://127.0.0.1:8600"),
                  instruction="You are the Google host of the MCP lesson.", tools=[shop])
    runner = InMemoryRunner(agent=agent, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text=TASK)])):
        for part in event.content.parts if event.content else []:
            if part.text:
                print(part.text)
    await shop.close()


asyncio.run({"openai": openai_host, "claude": claude_host, "google": google_host}[sys.argv[1]]())
PY

put wire.py <<'PY'
"""For the first request in labllm's log: which provider's format, and get_order as the host described it."""
import json
import textwrap

for line in open("/var/log/labllm/requests.jsonl"):
    r = json.loads(line)
    q = r["request"]
    tools = q.get("tools", [])
    if "functionDeclarations" in json.dumps(tools):
        tools = [f for t in tools for f in t["functionDeclarations"]]
    for t in tools:
        print(r["path"])
        print(textwrap.fill(json.dumps(t, ensure_ascii=False), 100, initial_indent="  ", subsequent_indent="  "))
    break
PY

put said.py <<'PY'
"""What each host's MCP client said to the server, one line per message."""
import json
import sys

for host in sys.argv[1:]:
    print(host)
    for line in open(f"{host}.in.jsonl"):
        m = json.loads(line)
        p = m.get("params", {})
        version = p.get("protocolVersion") or p.get("_meta", {}).get("io.modelcontextprotocol/protocolVersion", "")
        print(f"  {m['method']:28} {version}")
PY

block one-server
for h in openai claude google; do
  on "python hosts.py $h 2> /dev/null"
done

block wire
for h in openai claude google; do
  fresh_log
  on "python hosts.py $h > /dev/null 2>&1; python wire.py"
done

block said
on 'python said.py openai claude google'

block list-again
on "python -c 'import json; [print(json.loads(l)[\"method\"]) for l in open(\"openai.in.jsonl\")]' | sort | uniq -c"
