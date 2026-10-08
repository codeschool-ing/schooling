---
title: One server, three hosts
version: 2
---

The order lookup, written once as an MCP server with the `mcp` SDK (this lab pins 2.3.0):

```python
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
```

It is lesson 4's tool again: a name, a type hint, a docstring, and a function that returns text. `server.run()` speaks MCP over **stdio**: the host starts the program and they exchange one JSON-RPC message per line on its standard input and output.

Three hosts, one per library, each told to use that server:

```python
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
```

Each library has its own way of naming a server: `MCPServerStdio` in the OpenAI SDK, an entry in `mcp_servers` for the Claude Agent SDK, `McpToolset` in the ADK. None of them needed a line of `get_order` itself. `server()` starts the program through `sh -c "tee … | python shop_mcp.py"`: `tee` copies everything the host's client writes to the server into a file, so section 04 can read it.

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 OPENAI_BASE_URL=http://127.0.0.1:11435/v1 OLLAMA_API_BASE=http://127.0.0.1:11435 LITELLM_LOCAL_MODEL_COST_MAP=True CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ana@lab:~/agents$ python hosts.py openai 2> /dev/null
The status of your order M-1043 is that it has been shipped. Your order number is BR5512340003. You can track the status of your order by following this tracking number.
ana@lab:~/agents$ python hosts.py claude 2> /dev/null
Your order M-1043 has been shipped. Here are the details:

- **Book 1 (Book ID: b13)**: Quantity: 1, Price: 24.90
- **Book 2 (Book ID: b14)**: Quantity: 1, Price: 25.90
- **Book 3 (Book ID: b26)**: Quantity: 1, Price: 59.90

The total amount for the order is 110.70 cents. 

Your order's tracking number is BR5512340003. Please keep this information for reference. If you need any further assistance, feel free to ask.
ana@lab:~/agents$ python hosts.py google 2> /dev/null
Your order M-1043 was shipped on 2026-09-28 and has a tracking number BR5512340003. The total cost of the order is 11070 cents, and it includes books with IDs b13, b14, and b26. If you have any questions or concerns about your order, I recommend contacting our customer support team.
```

The recorder runs in the background and the three SDKs point at it, so section 02 can read what each host sent; `LITELLM_LOCAL_MODEL_COST_MAP=True` keeps LiteLLM from fetching a price list from GitHub, as lesson 10 explained. The models are real: `llama3.2:3b` for the OpenAI and Google hosts, and `qwen2.5:3b` for the Claude host, for the reason lesson 9 gave. Each called `get_order` and answered in its own words, and one of them slipped: the Claude host's model wrote 110.70 for a total that `get_order` gives as 11070 cents, and called it cents. Standard error was dropped (`2> /dev/null`) for the warnings the earlier lessons already showed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A host sits between two connections that are easy to confuse. To the model provider it speaks the provider&#x27;s API, and each provider describes a tool in its own format. To each MCP server it speaks MCP, the same for every server. The host translates the server&#x27;s tool list into the provider&#x27;s format, and the server never sees the model.\"><defs><marker id=\"l11wires-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11wires-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">model provider</text><text x=\"30\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ollama :11434</text><rect x=\"280\" y=\"50\" width=\"160\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host</text><text x=\"290\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the loop, the model,</text><text x=\"290\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the permissions</text><rect x=\"540\" y=\"70\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop_mcp.py</text><text x=\"550\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">an MCP server</text><path d=\"M280 100 L180 100\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l11wires-ah-wire)\"></path><text x=\"230\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provider&#x27;s API</text><path d=\"M440 100 L540 100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l11wires-ah-phosphor)\"></path><text x=\"490\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MCP</text></svg>", "caption": "MCP is the right-hand wire. The left-hand one is still each provider's own."}
```

This is the division MCP makes. The host keeps talking to its model in the provider's format, as the previous section showed; that wire is not MCP. Between the host and the server, the wire is the same whoever the host is, and the server never learns which model, if any, is on the other side.
