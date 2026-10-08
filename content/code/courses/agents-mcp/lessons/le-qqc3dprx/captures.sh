#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of agents-mcp, as a script that
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
# gives. archive_mcp.py is a second server the course wrote, whose "archived"
# orders are not in shop.db; the lesson shows it whole. The servers (mcp
# 2.3.0), the three hosts and their clients (openai-agents 0.23.1,
# claude-agent-sdk 0.2.163 with the Claude Code CLI 2.1.286, google-adk 2.11.0
# through LiteLLM), the processes, the environment each server received (its
# variable NAMES; no value is printed anywhere in this lesson), the messages
# each client sent and each host's handling of two tools with one name are
# real. Standard error is dropped where a command says 2> /dev/null; it holds
# the warnings the earlier lessons showed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$SHELL_STATE export PYTHONUNBUFFERED=1; $*" < /dev/null 2>&1 || true; }
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null

put probe_mcp.py <<'PY'
"""An MCP server with one tool that reports where it is running. It prints variable NAMES, never values."""
import json
import os

from mcp.server.mcpserver import MCPServer

server = MCPServer("probe")


@server.tool()
def where_am_i() -> str:
    """Report this server's process: its parent, its user, its directory and the names of its environment variables."""
    parent = open(f"/proc/{os.getppid()}/cmdline").read().replace("\0", " ").strip()
    return json.dumps({"parent": parent[:70], "uid": os.getuid(), "cwd": os.getcwd(),
                       "pid": os.getpid(), "env": sorted(os.environ)})


if __name__ == "__main__":
    server.run()
PY

put orders_mcp.py <<'PY'
"""The live order lookup, as a server called "orders"."""
import json

from mcp.server.mcpserver import MCPServer

import shop

server = MCPServer("orders")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."""
    return json.dumps(shop.get_order(order_id))


if __name__ == "__main__":
    server.run()
PY

put archive_mcp.py <<'PY'
"""Another team's server, "archive", which happens to name its tool get_order too."""
import json

from mcp.server.mcpserver import MCPServer

server = MCPServer("archive")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up an order in last year's archive."""
    return json.dumps({"id": order_id, "status": "archived", "source": "archive server"})


if __name__ == "__main__":
    server.run()
PY

put hosts.py <<'PY'
"""Three hosts, each given a set of MCP servers to start: python hosts.py HOST TASK SERVER..."""
import asyncio
import sys

host, task, names = sys.argv[1], sys.argv[2], sys.argv[3:]
WRAP = {"tee": lambda n: ["sh", "-c", f"tee {n}.in.jsonl | python {n}_mcp.py"],   # keep a copy of what the client sent
        "clean": lambda n: ["env", "-i", "PATH=/home/ana/agents/.venv/bin:/usr/bin:/bin", "HOME=/home/ana", "python", f"{n}_mcp.py"]}


def command(entry):
    """'probe' starts probe_mcp.py; 'probe:tee' or 'probe:clean' wraps it; 'probe:env' adds one variable."""
    name, _, wrap = entry.partition(":")
    argv = WRAP[wrap](name) if wrap in WRAP else ["python", f"{name}_mcp.py"]
    params = {"command": argv[0], "args": argv[1:]}
    if wrap == "env":
        params["env"] = {"ONLY_THIS": "1"}
    return name, params


SERVERS = dict(command(e) for e in names)
SYSTEM = f"You are the {host} host of the components lesson."


async def openai_host():
    from contextlib import AsyncExitStack
    from agents import Agent, Runner, set_tracing_disabled
    from agents.mcp import MCPServerStdio
    set_tracing_disabled(True)
    async with AsyncExitStack() as stack:
        servers = [await stack.enter_async_context(MCPServerStdio(params=p, name=n)) for n, p in SERVERS.items()]
        agent = Agent(name="support", model="llama3.2:3b", instructions=SYSTEM, mcp_servers=servers)
        try:
            print((await Runner.run(agent, task)).final_output)
        except Exception as e:
            print(f"raised {type(e).__name__}: {e}")


async def claude_host():
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query
    options = ClaudeAgentOptions(model="qwen2.5:3b", system_prompt=SYSTEM, tools=[], setting_sources=[],
                                 allowed_tools=[f"mcp__{n}" for n in SERVERS],
                                 mcp_servers={n: {"type": "stdio", **p} for n, p in SERVERS.items()})
    async for message in query(prompt=task, options=options):
        if isinstance(message, ResultMessage):
            print(message.result)


async def google_host():
    from google.adk.agents import Agent
    from google.adk.models.lite_llm import LiteLlm
    from google.adk.runners import InMemoryRunner
    from google.adk.tools.mcp_tool import McpToolset, StdioConnectionParams
    from google.genai.types import Content, Part
    from mcp import StdioServerParameters
    toolsets = [McpToolset(connection_params=StdioConnectionParams(server_params=StdioServerParameters(**p)))
                for p in SERVERS.values()]
    agent = Agent(name="support", model=LiteLlm(model="ollama_chat/llama3.2:3b"),
                  instruction=SYSTEM, tools=toolsets)
    runner = InMemoryRunner(agent=agent, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text=task)])):
        for part in event.content.parts if event.content else []:
            if part.text:
                print(part.text)
    for t in toolsets:
        await t.close()


asyncio.run({"OpenAI": openai_host, "Claude": claude_host, "Google": google_host}[host]())
PY

put probed.py <<'PY'
"""Print what where_am_i reported, from the tool result in the recorder's log, wherever each API's format put it."""
import json
import re

log = open("requests.jsonl").read()
found = re.search(r'parent[\\"]+: [\\"]+(.*?)[\\"]+, [\\"]+uid[\\"]+: (\d+), [\\"]+cwd[\\"]+: [\\"]+(.*?)[\\"]+,.*?env[\\"]+: \[(.*?)\]', log)
parent, uid, cwd, env = found.groups()
names = [n for n in re.split(r'[\\", ]+', env) if n]
print(f"parent: {parent}\nuid:    {uid}\ncwd:    {cwd}\nenv:    {len(names)} variables")
print("        " + " ".join(names))
PY

put said.py <<'PY'
"""What each server's client sent it: the method, and anything the client declared about itself."""
import json
import sys

for name in sys.argv[1:]:
    print(name)
    for line in open(f"{name}.in.jsonl"):
        m = json.loads(line)
        p = m.get("params", {})
        meta = p.get("_meta", {})
        extra = p.get("capabilities", meta.get("io.modelcontextprotocol/clientCapabilities", ""))
        if m["method"] == "tools/call":
            extra = {"arguments": p["arguments"], "_meta": {k: v for k, v in meta.items() if "/protocolVersion" not in k
                                                          and "/clientInfo" not in k and "/clientCapabilities" not in k}}
        print(f"  {m['method']:26} {json.dumps(extra) if extra != '' else ''}")
PY

put names.py <<'PY'
"""The tool names the host offered its model in the first request, or that it sent none."""
import json

lines = open("requests.jsonl").readlines()
if not lines:
    print("offered: no request was sent")
else:
    tools = json.loads(lines[0])["request"].get("tools", [])
    print("offered:", ", ".join(t.get("name") or t["function"]["name"] for t in tools))
PY

recorder
say 'export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 OPENAI_BASE_URL=http://127.0.0.1:11435/v1 OLLAMA_API_BASE=http://127.0.0.1:11435 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1'

block probe
for h in OpenAI Claude Google; do
  on 'rm -f requests.jsonl'
  on "python hosts.py $h 'Where are you running?' probe > /dev/null 2>&1; python probed.py"
done

block clean
on 'rm -f requests.jsonl'
on "python hosts.py Claude 'Where are you running?' probe:env > /dev/null 2>&1; python probed.py"
on 'rm -f requests.jsonl'
on "python hosts.py Claude 'Where are you running?' probe:clean > /dev/null 2>&1; python probed.py"

block what-it-sees
for h in OpenAI Claude Google; do
  lab exec "$SHELL_STATE python hosts.py $h 'Where is my order M-1043?' orders:tee > /dev/null 2>&1; mv orders.in.jsonl $h.in.jsonl" < /dev/null
done
on 'python said.py OpenAI Claude Google'

block two-servers
for h in OpenAI Claude Google; do
  on 'rm -f requests.jsonl'
  on "python hosts.py $h 'Where is my order M-1043?' orders archive 2> /dev/null; python names.py"
done
