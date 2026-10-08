---
title: Two calls in one reply
version: 2
---

A model may ask for several tools in one reply when the calls do not depend on each other. Asked about two orders, there is no reason to look up the first, wait, and then look up the second, and `llama3.2:3b` did not:

```
ana@lab:~/agents$ python agent.py "What is the status of my orders M-1043 and M-1048?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: The current status of your orders are as follows:

- Order M-1043: Shipped on 2026-09-28. The book details are as follows:
  - Book ID: b13
  - Quantity: 1
  - Price in cents: 2490
  - Total price in cents: 2490
  - Book ID: b14
  - Quantity: 1
  - Price in cents: 2590
  - Total price in cents: 2590
  - Book ID: b26
  - Quantity: 1
  - Price in cents: 5990
  - Total price in cents: 5990
  - Total price for order M-1043: 11070 cents

- Order M-1048: Cancelled on 2026-09-30. There is no tracking information available.
```

Both calls carry step number `[1]`: one reply, two `tool_use` blocks, two results sent back together in one message. The run took two requests instead of three. With tools that take seconds each, such as a web fetch or a slow database, running them concurrently in the host saves the slower one's time too. `agent.py` runs them one after the other, which is correct and simple; lesson 18 measures what concurrency buys. (The answer then recites every line of M-1043 in cents, which nobody asked for: the observation carried them, and section 07 of lesson 3 is about what to leave out of one.)

## Every call gets its result

Anthropic's API requires every `tool_use` in a reply to be answered by a `tool_result` with its id in the very next message, and refuses the request with a `400` naming the call when one is missing. `--drop-one` sends only the first result back, the bug a host has when it stops processing a reply's blocks after the first one, or when one tool raises and the loop skips the rest. A model that asks for two things at once on every run makes the bug easy to see, so this part uses the stand-in, with two calls written into one reply. Save it as `~/agents/parallel.json`:

```json
{"M-1043 and M-1048": [
  [{"tool": "get_order", "input": {"order_id": "M-1043"}},
   {"tool": "get_order", "input": {"order_id": "M-1048"}}],
  {"text": "M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive."}
 ]
}
```

```
ana@lab:~/agents$ python standin.py parallel.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python agent.py "What is the status of my orders M-1043 and M-1048?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive.
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python agent.py "What is the status of my orders M-1043 and M-1048?" --drop-one
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive.
```

The two runs print the same, and that is the problem. In the second, the host ran both lookups, sent back only M-1043's result, and the answer still states M-1048's status. **Nothing refused it.** Neither Ollama nor the stand-in checks the rule Anthropic's API enforces; the stand-in's answer was written in advance, and a real model in the same place has two choices, both bad: say it cannot find M-1048, or guess. That refusal is worth having, and a host that talks to a model which does not enforce it has to enforce it itself. **Never drop a call silently.** If a tool cannot run, send a result anyway, marked as an error, saying why (*"not run: the previous call failed"*). The model then knows what happened to every request it made.

## When not to run calls together

Independent reads can run together safely. Calls that depend on each other, or that write, should not, even if a model asks for them in one reply. A refund and the lookup that justifies it belong in that order, and two refunds for the same order in one reply are more likely a mistake than a plan. A host can run reads concurrently and writes one at a time, or refuse a reply that asks for more than one write.
