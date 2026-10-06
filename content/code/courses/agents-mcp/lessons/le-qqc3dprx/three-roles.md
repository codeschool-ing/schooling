---
title: Three roles, found on this machine
version: 1
---

The specification describes MCP as a **client-host-server** architecture. `ai-dev` lesson 7 named the three roles; this lesson finds each of them in a running system and asks what each one can see and do.

- **The host** is the application: lesson 11's three programs, an editor, a chat app. It holds the conversation and the connection to the model, runs the loop, and decides what the model may do.
- **A client** is the part of the host that talks to **exactly one server**. A host with two servers has two clients. In lesson 11 the clients were `MCPServerStdio` in the OpenAI SDK, `McpToolset` in the ADK and a component inside the Claude Code CLI.
- **A server** offers tools, resources and prompts, and answers requests. It is a separate process, or a service elsewhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"MCP&#x27;s three roles. The host is the application and holds the conversation and the model. Inside it, one client per server: each client talks to exactly one server. The servers are separate processes or services; each receives only the requests its client sends, and none can see the conversation or another server.\"><defs><marker id=\"l12roles-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host: the conversation, the model, the loop</text><rect x=\"40\" y=\"64\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">client 1</text><text x=\"50\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">talks to orders</text><rect x=\"40\" y=\"140\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">client 2</text><text x=\"50\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">talks to help</text><rect x=\"470\" y=\"64\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">server: orders</text><text x=\"480\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order</text><rect x=\"470\" y=\"140\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">server: help</text><text x=\"480\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">search_help</text><path d=\"M180 89 L470 89\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12roles-ah-phosphor)\"></path><path d=\"M180 165 L470 165\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12roles-ah-phosphor)\"></path><text x=\"585\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no path between servers</text></svg>", "caption": "The conversation stays in the host. Each server sees only its own calls."}
```

Among the design principles the specification lists, one is written as a negative: **servers should not be able to read the whole conversation, nor "see into" other servers.** The full history stays with the host, each server receives only what it needs, and anything that crosses from one server to another goes through the host, because nothing else connects them.

The rest of this lesson tests that principle, and the parts of it that depend on the host. It uses three servers: one written to report on itself, the order server of lesson 11 under the name `orders`, and `archive`, a second server from another team, which the course wrote for the purpose. `hosts.py` is lesson 11's three hosts, now told which servers to start on the command line:

```python
"""Three hosts, each given a set of MCP servers to start: python hosts.py HOST TASK SERVER..."""
import asyncio
import sys

host, task, names = sys.argv[1], sys.argv[2], sys.argv[3:]
WRAP = {"tee": lambda n: ["sh", "-c", f"tee {n}.in.jsonl | python {n}_mcp.py"],   # keep a copy of what the client sent
        "clean": lambda n: ["env", "-i", "PATH=/opt/agents/bin:/usr/bin:/bin", "HOME=/home/ana", "python", f"{n}_mcp.py"]}


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
    from agents import Agent, Runner, set_default_openai_api, set_tracing_disabled
    from agents.mcp import MCPServerStdio
    set_default_openai_api("chat_completions")
    set_tracing_disabled(True)
    async with AsyncExitStack() as stack:
        servers = [await stack.enter_async_context(MCPServerStdio(params=p, name=n)) for n, p in SERVERS.items()]
        agent = Agent(name="support", model="scripted-1", instructions=SYSTEM, mcp_servers=servers)
        try:
            print((await Runner.run(agent, task)).final_output)
        except Exception as e:
            print(f"raised {type(e).__name__}: {e}")


async def claude_host():
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query
    options = ClaudeAgentOptions(model="scripted-1", system_prompt=SYSTEM, tools=[], setting_sources=[],
                                 allowed_tools=[f"mcp__{n}" for n in SERVERS],
                                 mcp_servers={n: {"type": "stdio", **p} for n, p in SERVERS.items()})
    async for message in query(prompt=task, options=options):
        if isinstance(message, ResultMessage):
            print(message.result)


async def google_host():
    from google.adk.agents import Agent
    from google.adk.models.google_llm import Gemini
    from google.adk.runners import InMemoryRunner
    from google.adk.tools.mcp_tool import McpToolset, StdioConnectionParams
    from google.genai.types import Content, Part
    from mcp import StdioServerParameters
    toolsets = [McpToolset(connection_params=StdioConnectionParams(server_params=StdioServerParameters(**p)))
                for p in SERVERS.values()]
    agent = Agent(name="support", model=Gemini(model="scripted-1", base_url="http://127.0.0.1:8600"),
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
```
