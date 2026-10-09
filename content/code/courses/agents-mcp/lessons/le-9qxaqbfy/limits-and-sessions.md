---
title: Turn limits, and sessions on disk
version: 2
---

## The turn limit

```
ana@lab:~/agents$ python cs_run.py one-turn "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
system     informational
result     error_max_turns turns=2 5968 ms cost_usd=0.0018 session=3109c2c9
raised     ResultError: Claude Code returned an error result: Reached maximum number of turns (1) (exit code: 1)
```

With `max_turns=1` the run stopped after the first tool result. The stream still ended with a `result`, of subtype `error_max_turns`, so a program reading the stream knows what happened; and then `query()` **raised `ResultError`** as well, which `cs_run.py` catches. Lesson 8's SDK raised; this one reports and then raises, and a program has to handle the exception either way. Notice `turns=2` in a run limited to one: what the CLI counts as a turn and what the option limits are not the same count. Test a limit against what the run did, not against the number you set.

## Sessions

Every run writes its conversation to a file, and each `result` carries the session's id. `cs_session.py` sends two messages from Bia, first as two separate runs, then with the second resuming the first:

```python
"""Two messages from one customer: separate runs, then the second resuming the first."""
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You answer Marginalia's customers in the Claude Agent SDK lesson."


async def turn(text, resume=None):
    o = ClaudeAgentOptions(model="qwen2.5:3b", system_prompt=SYSTEM, mcp_servers={"shop": shop_server},
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
```

```
ana@lab:~/agents$ python cs_session.py separate
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1042'}
user       tool_result {"id": "M-1042", "customer_id": "c-101", "placed_on": "2026-09-20", "status": "delivered",
system     informational
assistant  Your order M-1042 was delivered on 2026-09-24. The shipping cost was 490 cents. You can track your package with the tracking number: BR5512340002.
result     success turns=2 16602 ms cost_usd=0.0055 session=5e16f94d
---
system     init tools=3
assistant  I'm sorry, it seems there is some information missing for me to assist you with returning an item. Could you please provide me with the order ID and the reason for the refund?
system     informational
result     success turns=1 7361 ms cost_usd=0.0025 session=1f5aee2e
ana@lab:~/agents$ python cs_session.py resume
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1042'}
user       tool_result {"id": "M-1042", "customer_id": "c-101", "placed_on": "2026-09-20", "status": "delivered",
system     informational
assistant  Your order M-1042 was delivered on 2026-09-24.
result     success turns=2 5940 ms cost_usd=0.0013 session=2ff7ac48
---
system     init tools=3
assistant  Based on the information provided, your order was marked as delivered. Unfortunately, once an order is marked as delivered, it cannot be returned. If you have any issues or need further assistance, you can contact our customer support team at support@marginalia.com.
system     informational
result     success turns=1 10367 ms cost_usd=0.0046 session=2ff7ac48
ana@lab:~/agents$ ls ~/.claude/projects/-home-ana-agents/ | wc -l; grep -l "this is Bia" ~/.claude/projects/-home-ana-agents/*.jsonl | wc -l
3
2
```

Separately, the second run asked for the order id. Resumed with `resume=first`, it answered about M-1042 and stayed **in the same session**, `2ff7ac48` in both results: the history that made the difference was the SDK's, and it was in the request, as lesson 1 said it has to be. The answer itself was wrong, and confidently so. It said a delivered order cannot be returned, where Marginalia's policy gives 30 days from delivery: the model had the order, not the policy, and did not search for it. Resuming gives the model the conversation, not the knowledge. The resumed turn's estimate, 0.0046, is more than three times the first turn's 0.0013, because it carried the first turn as well.

The last command is the part to remember. The CLI kept **three session files**, one per session, in `~/.claude/projects/` under a directory named after the working directory, and two of them hold Bia's message. Nobody passed a path; they are there because Claude Code keeps every session so it can resume it. For an agent answering customers that is a store of personal data the program never mentions, which lesson 8 said about `sessions.db` and which applies here with less warning. Decide where those files live, how long they stay and how they are deleted when a customer asks; the SDK's session store options exist for exactly that.
