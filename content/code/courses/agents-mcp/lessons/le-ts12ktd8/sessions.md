---
title: Sessions: a conversation that outlives a run
version: 1
---

Every agent so far forgot everything at the end of a run: the conversation was a local variable. A customer who writes a second message expects the agent to remember the first. The SDK's **sessions** keep the history between runs and send it with each new one.

```python
"""Two turns of one conversation, with and without the SDK's session memory."""
import sys

from agents import Agent, Runner, SQLiteSession, set_default_openai_api, set_tracing_disabled

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")
set_tracing_disabled(True)

agent = Agent(name="Support", model="scripted-1", tools=[get_order, search_help],
              instructions="You remember the conversation in the OpenAI Agents SDK lesson. Use the tools.")
session = SQLiteSession("bia", "sessions.db") if sys.argv[1] == "--session" else None
for message in sys.argv[2:]:
    result = Runner.run_sync(agent, message, session=session)
    print(f"> {message}\n< {result.final_output}")
```

`SQLiteSession("bia", "sessions.db")` stores the conversation under the id `bia` in a SQLite file. Two turns, without and with it:

```
ana@lab:~/agents$ python oa_session.py --none "Where is my order M-1042?" "Can I still return it?"
> Where is my order M-1042?
< Order M-1042 was delivered on 24 September 2026.
> Can I still return it?
< Which order do you mean? Please send me its number, such as M-1042.
ana@lab:~/agents$ python oa_session.py --session "Where is my order M-1042?" "Can I still return it?"
> Where is my order M-1042?
< Order M-1042 was delivered on 24 September 2026.
> Can I still return it?
< Yes. M-1042 was delivered on 24 September, and books can be returned within 30 days of delivery, so until 24 October.
```

Without a session, the second run started from nothing: *"Can I still return it?"* names no order, so the model (scripted by the course to behave sensibly) asked which one. With the session, the second run carried the first turn with it, the lookup of M-1042 included, and the answer used both. **The memory is the conversation itself, resent**, which is lesson 1's rule: the API keeps nothing, so whatever the model remembers travels in the request.

That has the consequences lesson 1 measured. Each turn is larger than the last, and a long session grows until it is expensive or no longer fits. The SDK offers ways to trim and compact a session's history; whichever you use, it is a decision about what the agent forgets, and it should be made on purpose.

A session is also stored personal data: `sessions.db` now holds Bia's messages and the details of order M-1042. It belongs in the same inventory as the trace (lesson 3 section 06): who can read it, how long it is kept, and how it is deleted when a customer asks. This repository's own rule for its tables applies to an agent's sessions too: **a store of personal data that the erase path cannot reach is a defect.**
