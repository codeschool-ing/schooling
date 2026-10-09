---
title: A loop in a subprocess
version: 2
---

The OpenAI Agents SDK of lesson 8 is a loop written in Python, running in your process. The **Claude Agent SDK** (`claude-agent-sdk` on PyPI, imported as `claude_agent_sdk`; this lab pins 0.2.163) is built differently. It ships a copy of **Claude Code**, Anthropic's command-line agent, and runs it:

```
ana@lab:~/agents$ CLI=$(python -c "import claude_agent_sdk, pathlib; print(pathlib.Path(claude_agent_sdk.__file__).parent / \"_bundled/claude\")"); du -h $CLI; $CLI --version
231M	/home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/_bundled/claude
2.1.286 (Claude Code)
```

A 231 MB program inside a Python package. When your code calls `query()`, the SDK starts that program as a subprocess and exchanges JSON lines with it over standard input and output. The loop (the model calls, the tool dispatch, the permission checks, the session files) runs in the subprocess; your program sends a prompt and reads a stream of messages back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"Three processes. Your Python program calls query(); the SDK starts the Claude Code command-line program as a subprocess and talks to it in JSON lines over standard input and output. The subprocess sends HTTP requests to the model provider, here Ollama on port 11434. When the model calls a shop tool, the subprocess sends the call back over the same pipe, and the tool runs inside your program.\"><defs><marker id=\"l9proc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9proc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l9proc-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">your process</text><rect x=\"20\" y=\"44\" width=\"190\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cs_run.py</text><text x=\"30\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls query()</text><rect x=\"20\" y=\"124\" width=\"190\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop_server</text><text x=\"30\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the tools, in-process</text><rect x=\"280\" y=\"44\" width=\"190\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">claude 2.1.286</text><text x=\"290\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subprocess: the loop</text><rect x=\"540\" y=\"80\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Ollama :11434</text><text x=\"550\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the model server</text><path d=\"M210 70 L280 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9proc-ah-amber)\"></path><text x=\"245\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON lines</text><path d=\"M280 150 L210 150\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l9proc-ah-phosphor)\"></path><text x=\"245\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tool calls</text><path d=\"M470 110 L540 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l9proc-ah-wire)\"></path><text x=\"505\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTP</text></svg>", "caption": "The loop runs in the subprocess. Your tools run in your process."}
```

```python
"""The first agent with the Claude Agent SDK, in three configurations."""
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, ClaudeSDKError, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You answer Marginalia's customers in the Claude Agent SDK lesson. Use the tools; never guess."


def options(how):
    o = ClaudeAgentOptions(model="qwen2.5:3b", system_prompt=SYSTEM,
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
```

`ClaudeAgentOptions` holds the configuration that lesson 8 split between `Agent` and `Runner`; `query()` is an async iterator over messages. Section 04 explains the three configurations; this run uses the first, the defaults. `cs_show.py` prints one line per message.

The model here is `qwen2.5:3b`, the third model lesson 1 pulled. Through the Claude Code CLI, `llama3.2:3b` never called a tool in the runs made for this course, and an agent lesson needs one that does. The recorder of lesson 1 runs in the background, and the CLI is pointed at it with `ANTHROPIC_BASE_URL`; `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` stops the CLI's own calls home, which have nothing to do with the agent. `timeout 300` stops the run after five minutes, because with the defaults this agent can loop: in one run made while writing this lesson it was still calling tools when the five minutes ran out.

```python
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
```

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ana@lab:~/agents$ timeout 300 python cs_run.py default "Where is my order M-1043?"
system     init tools=23
assistant  tool_use mcp__shop__get_order {'order_id': '123456'}
user       tool_result (error) no order 123456
system     informational
assistant  Sure, I can help with that. Could you please provide more details on what you need to achieve? For example, are you looking to start a CI run, send a message, invoke a skill, or perform some other action?
result     success turns=2 56527 ms cost_usd=0.0188 session=8ad16af8
```

Every line of the stream is the SDK's. The stream begins with a `system` message of subtype `init`, which lists the tools the session has, and ends with a `result` that carries the number of turns, the time, a cost and a session id. Between them sit the messages lesson 1 described, as typed objects: an assistant message holding a tool use, a user message holding its result, an assistant message holding the answer.

Read what they say, though. The model looked up an order called `123456`, which does not exist, and then asked what it was supposed to do: *start a CI run, send a message, invoke a skill*. None of those words were in the question. Section 04 finds where they came from. One more line came from the CLI itself, a `system` message of subtype `informational`, which `cs_show.py` prints without its text; it is a notice about a Claude Code product feature and has nothing to do with this agent.

Two other things come out of the CLI. Each run writes one warning to standard error, that it does not recognise the model name; it is left out of the captures in this lesson. And `cost_usd=0.0188` is not a bill: Ollama charges nothing, and the CLI estimates a cost from its own price table, guessing for a name it does not know. As a measure of how much was sent it is still useful, and section 04 uses it that way.

| lesson 8 (Agents SDK) | Claude Agent SDK |
|---|---|
| a loop in your process | the Claude Code CLI as a subprocess |
| `Agent(...)` plus `Runner.run_sync(...)` | `query(prompt, ClaudeAgentOptions(...))` |
| `@function_tool` | `@tool` inside an in-process MCP server (section 03) |
| `max_turns`, raises | `max_turns`, a `result` with an error subtype, then raises (section 09) |
| `needs_approval` | `allowed_tools`, permission modes, `can_use_tool` (sections 06 and 07) |
| guardrails | hooks (section 08) |
| `SQLiteSession` | session files written by the CLI, and `resume` (section 09) |
