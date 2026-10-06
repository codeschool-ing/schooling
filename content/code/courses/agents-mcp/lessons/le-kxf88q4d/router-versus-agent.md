---
title: The same three messages, a router and an agent
version: 1
---

Here is a routing workflow for Marginalia's messages. One model call reads the message and returns one word; code does the rest. **The labels it returns were written by the course** as rules for the lab's stand-in model; the code, the lookups and the counts are real.

```schooling-example
{
  "language": "python",
  "file": "router.py",
  "parts": [
    {
      "code": "\"\"\"A workflow with routing: the model picks a branch once, and the code does the rest.\"\"\"\nimport re\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "client = anthropic.Anthropic()\nmessage = sys.argv[1]\nlabel = client.messages.create(\n    model=\"scripted-1\",\n    max_tokens=5,\n    system=\"Classify the customer's message with one word: order, policy or other.\",\n    messages=[{\"role\": \"user\", \"content\": message}],\n).content[0].text.strip()\n\n",
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

`tally.py` reads labllm's log and adds up what the runs cost. The log was emptied before each batch:

```python
"""What the runs since the log was emptied cost: requests, tokens and model time."""
import json

rows = [json.loads(line) for line in open("/var/log/labllm/requests.jsonl")]
tokens_in = sum(r["usage"]["input_tokens"] for r in rows)
tokens_out = sum(r["usage"]["output_tokens"] for r in rows)
seconds = sum(r["ms"] for r in rows) / 1000
print(f"requests {len(rows)}   input tokens {tokens_in}   output tokens {tokens_out}   model time {seconds:.1f} s")
```

The router, on lesson 1's three messages and one more:

```
ana@lab:~/agents$ python router.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[order] M-1042 is delivered, delivered on 2026-09-24
ana@lab:~/agents$ python router.py "My order M-1043 has not arrived yet. Where is it?"
[order] M-1043 is shipped
ana@lab:~/agents$ python router.py "Which ways can I pay?"
[policy] Payment methods we accept: We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery.
ana@lab:~/agents$ python router.py "The courier was rude to me at the door yesterday."
[other] passed to a person
ana@lab:~/agents$ python tally.py
requests 4   input tokens 130   output tokens 4   model time 1.0 s
```

And lesson 1's agent, unchanged, on the same three:

```
ana@lab:~/agents$ python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] search_help({"query": "return a book"})
[3] answer: Yes, Bia. Order M-1042 was delivered on 24 September 2026, and printed books can be returned within 30 days of delivery, so you have until 24 October. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free.
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] get_order({"order_id": "M-1043"})
[2] search_help({"query": "tracking a parcel"})
[3] answer: Order M-1043 is on its way: it has shipped and has not been delivered yet. The carrier's tracking code is BR5512340003, and the tracking link in your shipping email updates at each step of the journey.
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "payment methods"})
[2] answer: We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery.
ana@lab:~/agents$ python tally.py
requests 8   input tokens 2551   output tokens 208   model time 9.9 s
```

## Reading the two tallies

| | router, 4 messages | agent, 3 messages |
|---|---|---|
| requests to the model | 4 | 8 |
| input tokens | 130 | 2551 |
| output tokens | 4 | 208 |
| model time | 1.0 s | 9.9 s |

The model time is labllm's rule, 200 ms before the first token and 40 ms a token after it, so the ratio is the lab's and not a provider's. What carries over to any provider is the shape: **the router sent one short request per message, while the agent sent two or three growing ones**, and wrote its answers token by token.

Now read the answers, because the numbers are only half of it. For M-1043 and the payment question the router's output is as useful as the agent's. For Bia it printed `M-1042 is delivered, delivered on 2026-09-24`, which is true and does not answer the question in the message, whether the book can still go back. **The router has no branch for "a return question about a specific order"**, so it answered the half it had a branch for. The agent combined the order and the returns article because it chose to look up both.

That is the trade, measured. A team that wants the router to answer Bia writes one more branch: look up the order, compute the window, print it. It costs an afternoon and no extra requests. A team that keeps meeting messages no branch covers has the evidence section 03's first question asks for, and the courier complaint routed to a person is what that evidence looks like when it is collected rather than guessed.
