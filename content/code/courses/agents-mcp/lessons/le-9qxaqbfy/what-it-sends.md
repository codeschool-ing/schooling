---
title: What a default run sends
version: 1
---

The first run used the defaults, and the answer took two requests. `wire.py` reads labllm's log and prints, for each request, how many tools it offered, their first names and the tokens it carried in:

```python
"""What each request in the recorder's log carried: tools offered, their names, and tokens in."""
import json

for n, line in enumerate(open("requests.jsonl"), 1):
    r = json.loads(line)
    tools = [t["name"] for t in r["request"].get("tools", [])]
    tokens_in = r["usage"].get("input_tokens", 0)
    print(f"request {n}: {len(tools):2} tools, {tokens_in:6} tokens in  {', '.join(tools[:6])}"
          + (", ..." if len(tools) > 6 else ""))
```

```
ana@lab:~/agents$ python wire.py
request 1: 23 tools,  13531 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
request 2: 23 tools,  13713 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
```

**23 tools and 13,531 tokens, for a question about one order.** Three of the tools are the shop's. The other twenty are Claude Code's own: `Bash`, `Edit`, `Read`, `Write`, `WebFetch`, an `Agent` tool for subagents, scheduling tools and more, each with a long description written for a coding assistant. The system prompt was the one passed in `SYSTEM`, after two lines the CLI adds (a billing header and *"You are a Claude agent, built on Anthropic's Claude Agent SDK."*); most of the tokens are the tool definitions.

Passing a system prompt replaced the prompt but **not the tools**. The option that controls them is `tools`:

```
ana@lab:~/agents$ python cs_run.py no-builtins "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
system     informational
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
assistant  Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
result     success turns=2 1723 ms cost_usd=0.0047 session=d19656ec
ana@lab:~/agents$ python wire.py
request 1:  3 tools,    399 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
request 2:  3 tools,    581 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
```

`tools=[]` removes every built-in tool. The same answer took 399 tokens on its first request and 581 on its second, against 13,531 and 13,713. The CLI's own cost estimate went from 0.1370 to 0.0047, about 29 times less, for the same two calls and the same answer.

The cost is not the only reason. A tool the agent was offered is a tool the model may call: an agent that answers customers had a shell, a file editor and a web fetcher in its hands for no reason, which is the opposite of the least privilege that lesson 17 is about. **Decide the tool list on purpose**, starting from nothing, as `no-builtins` does.
