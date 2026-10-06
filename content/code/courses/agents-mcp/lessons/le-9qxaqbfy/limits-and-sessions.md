---
title: Turn limits, and sessions on disk
version: 1
---

## The turn limit

```
ana@lab:~/agents$ python cs_run.py one-turn "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
system     informational
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
result     error_max_turns turns=2 378 ms cost_usd=0.0018 session=eecf2e5e
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
```

```
ana@lab:~/agents$ python cs_session.py separate
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1042'}
system     informational
user       tool_result {"id": "M-1042", "customer_id": "c-101", "placed_on": "2026-09-20", "status": "delivered",
assistant  Order M-1042 was delivered on 24 September 2026.
result     success turns=2 1207 ms cost_usd=0.0043 session=61027713
---
system     init tools=3
assistant  Which order do you mean? Please send me its number, such as M-1042.
system     informational
result     success turns=1 1050 ms cost_usd=0.0019 session=9428d322
ana@lab:~/agents$ python cs_session.py resume
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1042'}
system     informational
user       tool_result {"id": "M-1042", "customer_id": "c-101", "placed_on": "2026-09-20", "status": "delivered",
assistant  Order M-1042 was delivered on 24 September 2026.
result     success turns=2 1224 ms cost_usd=0.0043 session=09b2f915
---
system     init tools=3
assistant  tool_use mcp__shop__search_help {'query': 'return a book'}
system     informational
user       tool_result [{"title": "How to return a book", "body": "You have 30 days from delivery to return a pri
assistant  Yes. M-1042 was delivered on 24 September, and books can be returned within 30 days of delivery, so until 24 October.
result     success turns=2 2208 ms cost_usd=0.0106 session=09b2f915
ana@lab:~/agents$ ls ~/.claude/projects/-home-ana-agents/ | wc -l; grep -l "this is Bia" ~/.claude/projects/-home-ana-agents/*.jsonl | wc -l
3
2
```

Separately, the second run asked which order. Resumed with `resume=first`, it carried the first turn, used it, and stayed **in the same session**, `09b2f915` in both results. **The model's words were written by the course**; the history that made the difference was the SDK's, and it was in the request, as lesson 1 said it has to be. The resumed turn's estimate, 0.0106, is more than twice the first turn's 0.0043, because it carried the first turn as well as a search result.

The last command is the part to remember. The CLI kept **three session files**, one per session, in `~/.claude/projects/` under a directory named after the working directory, and two of them hold Bia's message. Nobody passed a path; they are there because Claude Code keeps every session so it can resume it. For an agent answering customers that is a store of personal data the program never mentions, which lesson 8 said about `sessions.db` and which applies here with less warning. Decide where those files live, how long they stay and how they are deleted when a customer asks; the SDK's session store options exist for exactly that.
