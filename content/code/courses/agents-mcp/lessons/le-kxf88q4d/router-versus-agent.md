---
title: The same three messages, a router and an agent
version: 2
---

Here is a routing workflow for Marginalia's messages. One model call reads the message and returns one word; code does the rest. Two details in it come from meeting `llama3.2:3b`: the instruction says *exactly* one word, because asked for "one word" it sometimes began a sentence instead, and the code strips a full stop and lowers the case before comparing, because a label is still text. It would set `temperature` to zero as well, for the steadiest label, but the version of the `anthropic` library pinned in lesson 1 no longer accepts that argument.

```schooling-example
{
  "language": "python",
  "file": "router.py",
  "parts": [
    {
      "code": "\"\"\"A workflow with routing: the model picks a branch once, and the code does the rest.\"\"\"\nimport re\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "client = anthropic.Anthropic()\nmessage = sys.argv[1]\nlabel = client.messages.create(\n    model=\"llama3.2:3b\",\n    max_tokens=5,\n    system=\"Classify the customer's message. Answer with exactly one word: order, policy or other.\",\n    messages=[{\"role\": \"user\", \"content\": message}],\n).content[0].text.strip().strip(\".\").lower()\n\n",
      "note": "**One request, five tokens out at most.** The model's whole job is to choose one of three words."
    },
    {
      "code": "if label == \"order\":\n    order = shop.get_order(re.search(r\"M-\\d{4}\", message).group())\n    print(f\"[order] {order['id']} is {order['status']}\"\n          + (f\", delivered on {order['delivered_on']}\" if order[\"delivered_on\"] else \"\"))\n",
      "note": "**Every branch is code.** The order id is found with a regular expression, not by the model; the reply is a template."
    },
    {
      "code": "elif label == \"policy\":\n    best = shop.search_help(message, k=1)[0]\n    print(f\"[policy] {best['title']}: {best['body']}\")\n",
      "note": "**The policy branch searches the help centre** and prints the best article as it stands."
    },
    {
      "code": "else:\n    print(\"[other] passed to a person\")",
      "note": "**Anything else goes to a person**, which is a decision the programmer made in advance."
    }
  ]
}
```

`tally.py` reads the recorder's `requests.jsonl` from lesson 1 and adds up what the runs cost. With the recorder started and `ANTHROPIC_BASE_URL` exported to point at it, every program in this terminal goes through it; `rm requests.jsonl` starts a new count.

```python
"""What the runs since requests.jsonl was emptied cost: requests, tokens and model time."""
import json

rows = [json.loads(line) for line in open("requests.jsonl")]
tokens_in = sum(r["usage"]["input_tokens"] for r in rows)
tokens_out = sum(r["usage"]["output_tokens"] for r in rows)
seconds = sum(r["ms"] for r in rows) / 1000
print(f"requests {len(rows)}   input tokens {tokens_in}   output tokens {tokens_out}   model time {seconds:.1f} s")
```

The router, on lesson 1's three messages and one more:

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435
ana@lab:~/agents$ python router.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[order] M-1042 is delivered, delivered on 2026-09-24
ana@lab:~/agents$ python router.py "My order M-1043 has not arrived yet. Where is it?"
[order] M-1043 is shipped
ana@lab:~/agents$ python router.py "Which ways can I pay?"
[other] passed to a person
ana@lab:~/agents$ python router.py "The courier was rude to me at the door yesterday."
[other] passed to a person
ana@lab:~/agents$ python tally.py
requests 4   input tokens 234   output tokens 8   model time 2.0 s
```

And lesson 1's agent, unchanged, on the same three:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] answer: Unfortunately, since your order was delivered on September 24th, you will no longer be able to return it. According to our return policy, items that have been delivered to the customer cannot be returned. However, I can help you with any other concerns or issues you may have with your order.
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] search_help({"query": "M-1043"})
[2] answer: It's possible that the tracking information for your order M-1043 is not yet available, as it can take 12 hours for the carrier to scan the parcel after it leaves the warehouse. You can check the tracking link provided by the carrier to see if there are any updates. If you haven't received an update after 12 hours, you can try contacting our customer service team to assist you further. We can also help you check if the parcel has been delivered to your neighbors or around the building, as it's common for carriers to leave parcels in a safe place. If the parcel still hasn't arrived after 48 hours, we can open a claim with the carrier and send a replacement or a refund, whichever you prefer.
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "ways to pay"})
[2] answer: We accept the following payment methods: 

* Visa
* Mastercard
* American Express
* PayPal
* Pix
* Marginalia gift cards

Please note that we do not accept cash on delivery.
ana@lab:~/agents$ python tally.py
requests 6   input tokens 1641   output tokens 302   model time 37.4 s
```

## Reading the two tallies

| | router, 4 messages | agent, 3 messages |
|---|---|---|
| requests to the model | 4 | 6 |
| input tokens | 234 | 1641 |
| output tokens | 8 | 302 |
| model time | 2.0 s | 37.4 s |

These are a small model on four processors and no graphics chip, so the seconds are this machine's and not a provider's; a paid API answers faster, and yours may too. What carries over to any model is the shape: **the router sent one short request per message and read two tokens back, while the agent sent two growing requests per message** and wrote its answers token by token. On this machine the difference is eighteen times the waiting.

Now read the answers, because the numbers are only half of it. The router answered M-1043 with the order's status, which is the useful half of an answer. For Bia it printed `M-1042 is delivered, delivered on 2026-09-24`, which is true and does not answer the question in the message, whether the book can still go back: **the router has no branch for "a return question about a specific order"**, so it answered the half it had a branch for. And it sent the payment question to a person, because the model labelled it `other`. That is a wrong label, but it failed safe: a person gets the message, and nobody was told anything false.

The agent's failures are of another kind. It told Bia that delivered books cannot be returned, which is false and which it said to the customer directly. For M-1043 it searched the help centre for the order's id instead of looking the order up, then answered from a general article about tracking. It got the payment question right. **The router's mistakes ended at a person; the agent's ended at the customer.**

That is the trade, measured. A team that wants the router to answer Bia writes one more branch: look up the order, compute the window, print it. It costs an afternoon and no extra requests, and its answer is right every time. A team that keeps meeting messages no branch covers has the evidence section 03's first question asks for, and the courier complaint routed to a person is what that evidence looks like when it is collected rather than guessed.
