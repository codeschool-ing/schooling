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
# (lab.sh reset), and the files ana wrote (put below), which the lesson shows
# in full, each checked by lab/shown.py.
#
# THE MODELS ARE REAL, in Ollama 0.40.0 with an 8192-token context, captured
# on 2026-10-08: llama3.2:3b (a80c4f17acd5) for the OpenAI and Google hosts,
# and qwen2.5:3b (357c53fb659c) for the Claude host, for the reason lesson 9
# gives. The MCP server (mcp 2.3.0), the three hosts and their MCP clients
# (openai-agents 0.23.1, claude-agent-sdk 0.2.163, google-adk 2.11.0 through
# LiteLLM), every message each client sent the server and every request each
# host sent the model are real. Python's UserWarnings and the Claude Code
# CLI's warning about the model name go to standard error, which these
# commands drop; the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$SHELL_STATE export PYTHONUNBUFFERED=1; $*" < /dev/null 2>&1 || true; }
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
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
    from agents import Agent, Runner, set_tracing_disabled
    from agents.mcp import MCPServerStdio
    set_tracing_disabled(True)
    async with MCPServerStdio(params=server("openai"), name="shop") as shop:
        agent = Agent(name="support", model="llama3.2:3b", mcp_servers=[shop],
                      instructions="You are the OpenAI host of the MCP lesson.")
        print((await Runner.run(agent, TASK)).final_output)


async def claude_host():
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query
    options = ClaudeAgentOptions(model="qwen2.5:3b", system_prompt="You are the Claude host of the MCP lesson.",
                                 tools=[], setting_sources=[], allowed_tools=["mcp__shop__get_order"],
                                 mcp_servers={"shop": {"type": "stdio", **server("claude")}})
    async for message in query(prompt=TASK, options=options):
        if isinstance(message, ResultMessage):
            print(message.result)


async def google_host():
    from google.adk.agents import Agent
    from google.adk.models.lite_llm import LiteLlm
    from google.adk.runners import InMemoryRunner
    from google.adk.tools.mcp_tool import McpToolset, StdioConnectionParams
    from google.genai.types import Content, Part
    from mcp import StdioServerParameters
    shop = McpToolset(connection_params=StdioConnectionParams(server_params=StdioServerParameters(**server("google"))))
    agent = Agent(name="support", model=LiteLlm(model="ollama_chat/llama3.2:3b"),
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
"""For the first request in the recorder's log: which API it went to, and get_order as the host described it."""
import json
import textwrap

for line in open("requests.jsonl"):
    r = json.loads(line)
    tools = r["request"].get("tools", [])
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
recorder
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 OPENAI_BASE_URL=http://127.0.0.1:11435/v1 OLLAMA_API_BASE=http://127.0.0.1:11435 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1'
for h in openai claude google; do
  on "python hosts.py $h 2> /dev/null"
done

block wire
for h in openai claude google; do
  on 'rm -f requests.jsonl'
  on "python hosts.py $h > /dev/null 2>&1; python wire.py"
done

block said
on 'python said.py openai claude google'

block list-again
on "python -c 'import json; [print(json.loads(l)[\"method\"]) for l in open(\"openai.in.jsonl\")]' | sort | uniq -c"
