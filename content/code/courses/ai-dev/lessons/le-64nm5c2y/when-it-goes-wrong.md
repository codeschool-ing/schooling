---
title: When the loop does not end
version: 1
---

An agent's failures are mostly loops: the model asks for the same thing again, or keeps exploring
without converging. The model does not notice, because each step is a fresh decision from a
conversation that looks like progress. **The host has to notice**, with guards that do not depend on
the model's judgement.

## The same call twice

```
ana@dev:~/shop$ python agent.py "Is there a lamp under 100.00?"
[1] call:   read_handbook({"name": "products"})
[1] result: # Products The shop sells mugs, glasses, lamps and small furniture. Mugs
[2] call:   read_handbook({"name": "products"})
[2] host:   the same call twice in one task; stopping
```

The model asked for the products page, got it, and asked for it again. The page does not list prices,
so a model that wants a price will keep asking. The repeat guard stopped it at step 2. Without it,
this would run until the step limit, paying for the same page each time.

## Exploring without converging

```
ana@dev:~/shop$ python agent.py "Which is the cheapest lamp you sell?"
[1] call:   read_handbook({"name": "products"})
[1] result: # Products The shop sells mugs, glasses, lamps and small furniture. Mugs
[2] call:   read_handbook({"name": "shipping"})
[2] result: # Shipping Orders ship within two working days from the warehouse in Cam
[3] call:   read_handbook({"name": "coupons"})
[3] result: # Coupons Two coupons are active. WELCOME10 takes 10% off and has no end
[4] call:   read_handbook({"name": "warranty"})
[4] result: # Warranty Every item has a 90-day warranty against manufacturing faults
[5] call:   read_handbook({"name": "returns"})
[5] result: # Returns and refunds A customer may return any item within 30 days of d
host: stopped after 5 steps without an answer
```

Every call is different, so the repeat guard does not fire. The model reads one page after another,
none of them has prices, and **the step limit is what ends it**, after five, with no answer. That is
the right outcome, since the handbook does not list prices, and the host says so instead of
pretending.

What it cost is in labllm's log, the input tokens of those five requests:

```
ana@dev:~/shop$ tail -n 5 /var/log/labllm/requests.jsonl | python -c 'import json, sys; u = [json.loads(l)["usage"]["input_tokens"] for l in sys.stdin]; print("input tokens per step:", u, "total", sum(u))'
input tokens per step: [259, 392, 541, 666, 807] total 2665
```

Each step carries the conversation so far, so each is bigger than the last, and the five add up to
2,665 tokens for a question with no answer. With real tool results, pages of documents or rows of
data, the same shape costs far more.

## The guards

- **A step limit**, enforced by the loop, with a message that says the task was not finished. Pick it
  from the longest legitimate task, measured.
- **A repeat check** on the same tool with the same arguments.
- **A budget** in tokens or money per task, the guard of lesson 2 section 09 applied to the whole
  loop rather than one request.
- **A time limit**, for tools that can hang.
- **A record of every step**, so a stopped run can be read afterwards and the case added to an
  evaluation (lesson 5 section 09) of tasks the agent should be able to finish.

Most runaway agents in production are not malicious or broken. They are a model doing the likely
next thing, correctly, forever, with nothing in the host to say stop.
