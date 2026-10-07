---
title: One customer message, three programs
version: 1
---

Bia, a customer of Marginalia, writes: *"Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"* Here are three programs answering that message in the lab, each doing the job the way its kind does it. **The model's words in this section were written by the course**, as section 07 explains; the programs, the data and the search are real.

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

One request. The program pastes all forty help-centre articles into the system prompt, sends Bia's message and prints what comes back:

```
ana@lab:~/agents$ python assistant.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
Draft reply: Hi Bia, printed books can be returned within 30 days of delivery, free of charge: start the return from the order in your account, print the prepaid label and drop the parcel at any post office. If M-1042 arrived on 24 September, you have until 24 October. [For the support team: I cannot see orders. Check the delivery date before sending this.]
```

The draft is good, and it is careful about the one thing it could not know. **It took the delivery date on Bia's word**, because it cannot see orders, and it says so to the person who will send it. That person is the check: they open the order, see `delivered_on` and decide. The model wrote; a human acts.

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
[2] search_help({"query": "return a book"})
[3] answer: Yes, Bia. Order M-1042 was delivered on 24 September 2026, and printed books can be returned within 30 days of delivery, so you have until 24 October. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free.
```

Three requests to the model. In the first, it asked for the order; in the second, with `delivered` and the date in front of it, it asked for the returns article; in the third, it answered. **The date in the answer came from the database, not from Bia**, which is the difference from the assistant's draft.

Give the same program two other messages and it takes two other paths:

```
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] get_order({"order_id": "M-1043"})
[2] search_help({"query": "tracking a parcel"})
[3] answer: Order M-1043 is on its way: it has shipped and has not been delivered yet. The carrier's tracking code is BR5512340003, and the tracking link in your shipping email updates at each step of the journey.
```

```
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "payment methods"})
[2] answer: We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery.
```

**Nothing in `agent.py` mentions tracking, returns or payments.** For M-1043 the order came back `shipped`, and the next step became a search for tracking; for the payment question no order was involved, so there was no lookup at all, and two requests were enough. The path was decided at run time, by the model, one step after another, and neither of the other two programs could do that.
