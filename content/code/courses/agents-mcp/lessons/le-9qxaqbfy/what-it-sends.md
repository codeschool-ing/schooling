---
title: What a default run sends
version: 2
---

The first run used the defaults, and the answer took two requests. `wire.py` reads the recorder's log and prints, for each request, how many tools it offered, their first names and the tokens the model read:

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
request 1: 23 tools,   4098 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
request 2: 23 tools,   4098 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
```

**23 tools, and 4,098 tokens in each request, for a question about one order.** Three of the tools are the shop's. The other twenty are Claude Code's own: `Bash`, `Edit`, `Read`, `Write`, `WebFetch`, an `Agent` tool for subagents, scheduling tools and more, each with a long description written for a coding assistant. The system prompt was the one passed in `SYSTEM`, after two lines the CLI adds (a billing header and *"You are a Claude agent, built on Anthropic's Claude Agent SDK."*).

And 4,098 is not what the CLI sent. It is what the model read. Lesson 18 meets the same number from the other side: with the 8,192-token context of lesson 1, Ollama keeps 4,098 tokens of a prompt that does not fit, the first few and the last ones, and drops the middle without telling the client. Its own log says what happened here: a prompt of **12,247 tokens**, cut to 4,098. The cut took the question with it, and the model answered from what was left: CI runs, messages and skills are what Claude Code's tool descriptions talk about. A hosted provider with a large window would have read all twelve thousand tokens, and billed them, on every request.

Passing a system prompt replaced the prompt but **not the tools**. The option that controls them is `tools`:

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python cs_run.py no-builtins "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
system     informational
assistant  Your order M-1043 has been placed on September 28, 2026. It is currently in the "shipped" status. The books are being shipped with the tracking number BR5512340003. You have ordered one book each from book IDs b13, b14, and b26. The total amount for the order is 11070 cents. There is no refund history for this order yet. Please keep the order tracking information for your records.
result     success turns=2 24934 ms cost_usd=0.0068 session=187ff694
ana@lab:~/agents$ python wire.py
request 1:  3 tools,    468 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
request 2:  3 tools,    699 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
```

`tools=[]` removes every built-in tool. Now the whole request fit: 468 tokens on the first, 699 on the second, nothing cut, and the model looked up M-1043 and answered about it. The CLI's own estimate went from 0.0188 to 0.0068; against a provider that bills the full 12,247 tokens, the difference would be far larger.

Neither the cost nor a small window is the only reason. A tool the agent was offered is a tool the model may call: an agent that answers customers had a shell, a file editor and a web fetcher in its hands for no reason, which is the opposite of the least privilege that lesson 17 is about. **Decide the tool list on purpose**, starting from nothing, as `no-builtins` does.
