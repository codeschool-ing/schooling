---
title: One customer message, three programs
version: 2
---

Bia, a customer of Marginalia, writes: *"Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"* Here are three programs answering that message on the machine section 03 built, each doing the job the way its kind does it. The model is `llama3.2:3b`, and its words below are what it said on the day this lesson was captured. **Yours will be worded differently**, and now and then it will take a different path; that is the nature of the thing, and the end of this section comes back to it.

## Automation

```python
"""Automation: the programmer wrote the path, and the program follows it."""
import sys
from datetime import date, timedelta

import shop

RETURN_DAYS = 30

order = shop.get_order(sys.argv[1])
if order["status"] != "delivered":
    print(f"{order['id']}: not delivered yet ({order['status']}), nothing to return")
else:
    last = date.fromisoformat(order["delivered_on"]) + timedelta(days=RETURN_DAYS)
    if shop.TODAY <= last:
        print(f"{order['id']}: can be returned until {last}")
    else:
        print(f"{order['id']}: the return window closed on {last}")
```

Every decision in it was taken by whoever wrote it: the window is 30 days, an order that is not `delivered` has nothing to return, and the input is an order id. Given what it expects, it is fast, free and right every time:

```
ana@lab:~/agents$ python automation.py M-1042
M-1042: can be returned until 2026-10-24
ana@lab:~/agents$ python automation.py M-1044
M-1044: the return window closed on 2026-09-13
ana@lab:~/agents$ python automation.py M-1043
M-1043: not delivered yet (shipped), nothing to return
ana@lab:~/agents$ python automation.py "the book I bought last week"
Traceback (most recent call last):
  File "/home/ana/agents/automation.py", line 9, in <module>
    order = shop.get_order(sys.argv[1])
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/agents/shop.py", line 29, in get_order
    raise LookupError(f"no order {order_id}")
LookupError: no order the book I bought last week
```

The fourth run is the whole limitation in one traceback. Customers write sentences, and this one named its order by when it was bought. **Nothing in the program can decide to treat a sentence differently**, so the sentence went straight into `get_order` as if it were an id. A programmer can add a branch for that, and then another for the next surprise, and that is the life of an automation: correct inside its paths and helpless outside them.

## Assistant

```python
"""Assistant: one request. The model writes a draft, and a person decides what to send."""
import json
import sys

import anthropic

articles = [json.loads(line) for line in open("data/help.jsonl")]
handbook = "\n\n".join(f"# {a['title']}\n{a['body']}" for a in articles)

client = anthropic.Anthropic()
reply = client.messages.create(
    model="llama3.2:3b",
    max_tokens=1024,
    system="You draft replies for Marginalia's support team. The help centre follows.\n\n" + handbook,
    messages=[{"role": "user", "content": sys.argv[1]}],
)
print(reply.content[0].text)
```

One request. The program pastes all fourteen help-centre articles into the system prompt, sends Bia's message and prints what comes back:

```
ana@lab:~/agents$ python assistant.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
Hi Bia,

According to our help centre, you have 30 days from delivery to return a printed book. Since your order arrived on 24 September, that means you have until 24 October to return it.

Please go to the order in your account and follow the instructions for returning the book. Print the prepaid label and drop the parcel at any post office. Returns are free.

If you have any issues or concerns with the return process, feel free to reach out to us and we'll be happy to assist you.

Best,
[Your Support Team]
```

The draft is good: thirty days from delivery, so until 24 October, and how to send the parcel. **It took the delivery date on Bia's word**, because it cannot see orders, and nothing in the draft says so. That is the job of the person who sends it: they open the order, see `delivered_on` and decide. The model wrote; a human acts.

## Agent

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"Agent: the model chooses the next step, the program runs it, until the model answers.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "TOOLS = [\n    {\"name\": \"get_order\",\n     \"description\": \"Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"order_id\": {\"type\": \"string\"}}, \"required\": [\"order_id\"]}},\n    {\"name\": \"search_help\",\n     \"description\": \"Search Marginalia's help centre by meaning and return the three closest articles.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"query\": {\"type\": \"string\"}}, \"required\": [\"query\"]}},\n]\n",
      "note": "**Two tools, described in words and a schema.** The model never sees `shop.py`; it sees these names, descriptions and argument shapes, and nothing else."
    },
    {
      "code": "RUN = {\n    \"get_order\": lambda args: shop.get_order(args[\"order_id\"]),\n    \"search_help\": lambda args: [{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])],\n}\n",
      "note": "**What actually runs.** A table from a tool's name to the Python that carries it out. This is the program's half of the contract."
    },
    {
      "code": "SYSTEM = \"You answer Marginalia's customers. Use the tools to find facts, and never guess an order's details.\"\n\n",
      "note": "**One instruction**, and it matters: look facts up rather than guess them."
    },
    {
      "code": "client = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**The conversation starts with Bia's message**, and grows by one reply and one batch of results per step."
    },
    {
      "code": "for step in range(1, 6):\n    reply = client.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                   tools=TOOLS, messages=messages)\n    messages.append({\"role\": \"assistant\", \"content\": reply.content})\n    if reply.stop_reason != \"tool_use\":\n        print(f\"[{step}] answer: {reply.content[0].text}\")\n        break\n",
      "note": "**The loop.** Send everything so far, read the reply, and stop if the model did not ask for a tool. Five steps at most, whatever the model wants."
    },
    {
      "code": "    results = []\n    for block in reply.content:\n        if block.type == \"tool_use\":\n            print(f\"[{step}] {block.name}({json.dumps(block.input)})\")\n            output = RUN[block.name](block.input)\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": json.dumps(output)})\n    messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**Run what was asked**, and hand each result back, tied to its request by `tool_use_id`."
    }
  ]
}
```

```
ana@lab:~/agents$ python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] answer: Hello Bia,

According to the information provided, your order M-1042 was delivered on September 24, 2026. However, I don't have the exact date range during which returns are accepted.

I recommend checking the website of the seller or the delivery company that brought your order to see if they have any specific return windows. If you're still unsure, you can also reach out to their customer service for assistance.

Please note that even if you're able to return your order, it's always a good idea to contact the seller first to confirm their return policy and any potential restocking fees.
```

Two requests to the model. In the first, it asked for the order; in the second, with `delivered` and the date in front of it, it answered, and **the answer is wrong**. It says it does not know the return window and sends Bia to "the seller", when the window is thirty days and the help centre says so. It never searched the help centre. The date it quotes came from the database rather than from Bia, which is the one thing it did better than the assistant; everything after the date it made up.

Section 07 shows why this model stopped after one tool, and it is not a lack of intelligence: by the second request, the model could no longer see the tools. Hold on to the shape of the failure for now. **An agent that acts on facts it never looked up is worse than an assistant whose draft a person reads**, because nobody reads the agent's answer before Bia does.

Give the same program two other messages and it takes two other paths:

```
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] get_order({"order_id": "M-1043"})
[2] answer: Thank you for providing the order details. According to the tracking information, your order M-1043 was shipped on 2026-09-28, but it has not been delivered yet. The tracking number is BR5512340003. I recommend checking the tracking status periodically for updates on the delivery location and estimated arrival time. If you have any further concerns, please don't hesitate to contact us.
```

```
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "Payment methods"})
[2] answer: We accept Visa, Mastercard, and American Express, PayPal, Pix, and Marginalia gift cards. If you have a gift card, enter the 16-digit code at checkout to use it towards your order. Please note that gift cards can be used to pay for part of an order and the rest can be paid with a card, with no interest on orders over $120. Gift cards are valid for two years from purchase and cannot be exchanged for cash. If you experience any issues with your payment being charged twice, please contact us with your order number and a bank statement to resolve the issue.
```

**Nothing in `agent.py` mentions tracking, returns or payments.** For M-1043 the next step was the order, because the message named one; for the payment question no order was involved, so the step was a search, and the answer came from the article it found, with two slips of its own: a dollar sign the article does not have, and a sentence about double charges nobody asked about. The path was decided at run time, by the model, and neither of the other two programs could do that. Whether it decided well is the question the rest of this course keeps asking.
