---
title: Sessions: a conversation that outlives a run
version: 2
---

Every agent so far forgot everything at the end of a run: the conversation was a local variable. A customer who writes a second message expects the agent to remember the first. The SDK's **sessions** keep the history between runs and send it with each new one.

```python
"""Two turns of one conversation, with and without the SDK's session memory."""
import sys

from agents import Agent, Runner, SQLiteSession, set_tracing_disabled

from oa_tools import get_order, search_help

set_tracing_disabled(True)

agent = Agent(name="Support", model="llama3.2:3b", tools=[get_order, search_help],
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
< Your order M-1042 has been delivered on September 24, 2026. The tracking number for your order is BR5512340002. You can track the status of your order by visiting the tracking page for this number. The total cost of your order, including taxes and shipping, was $3,480. The order includes the book with ID b39. There is no outstanding refund for your order.
> Can I still return it?
< Unfortunately, I'm not sure which specific return policy you're referring to, but it seems that you can still return items that have been shipped, especially if you've received them in the condition they were sent. However, the exact process and time frame for return vary depending on the product, store, and location.

To get more accurate information, I would recommend checking the specific return policy for the item you're trying to return, either on the store's website or by contacting their customer service directly. They should be able to provide you with more detailed instructions and any necessary forms or labels for returning the item.
ana@lab:~/agents$ python oa_session.py --session "Where is my order M-1042?" "Can I still return it?"
> Where is my order M-1042?
< Your order M-1042 was successfully processed. According to our records, the order was placed on September 20, 2026, and was delivered on September 24, 2026. The tracking number for your order is BR5512340002. Your order includes a book with the ID b39, which was shipped to you for a total of $34,80. Please note that the order has been delivered and there are no outstanding refunds.
> Can I still return it?
< You are eligible for a return within 30 days of delivery. Since your order was delivered on September 24, 2026, you have until October 24, 2026, to initiate a return. To initiate a return, please contact our customer service team and they will guide you through the return process. Please note that the book is in good condition and you will receive a full refund of the original purchase price, minus any shipping costs. Additionally, you will need to arrange for the return of the book at your own expense.
```

Without a session, the second run started from nothing: *"Can I still return it?"* names no order, so the model talked about return policies in general and sent the customer to "the store's website". With the session, the second run carried the first turn with it, the lookup of M-1042 included, and the answer used it: delivered on 24 September, so returns until 24 October. **The memory is the conversation itself, resent**, which is lesson 1's rule: the API keeps nothing, so whatever the model remembers travels in the request.

That has the consequences lesson 1 measured. Each turn is larger than the last, and a long session grows until it is expensive or no longer fits. The SDK offers ways to trim and compact a session's history; whichever you use, it is a decision about what the agent forgets, and it should be made on purpose.

A session is also stored personal data: `sessions.db` now holds Bia's messages and the details of order M-1042. It belongs in the same inventory as the trace (lesson 3 section 06): who can read it, how long it is kept, and how it is deleted when a customer asks. This repository's own rule for its tables applies to an agent's sessions too: **a store of personal data that the erase path cannot reach is a defect.**
