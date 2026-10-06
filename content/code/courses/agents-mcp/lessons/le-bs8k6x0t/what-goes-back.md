---
title: What goes back to the model
version: 1
---

The observation is the only way the world reaches the model, so what a tool returns shapes every step after it. It also travels in every later request, which makes its size a cost paid again at each step.

```
ana@lab:~/agents$ python -c 'import json, shop, tiktoken; enc = tiktoken.get_encoding("o200k_base"); o = shop.get_order("M-1047"); small = {k: o[k] for k in ("status", "delivered_on", "total")}; print(len(enc.encode(json.dumps(o))), len(enc.encode(json.dumps(small))))'
105 27
ana@lab:~/agents$ python -c 'import json, shop, tiktoken; enc = tiktoken.get_encoding("o200k_base"); print(len(enc.encode(json.dumps(shop.search_help("refund after a return")))))'
228
```

The whole of M-1047, as `get_order` returns it, is 105 tokens. The three fields the refund question needs (`status`, `delivered_on`, `total`) are 27. The three help articles `search_help` returns are 228. In a three-step run, an observation returned at step 1 is sent at steps 2 and 3 as well, so trimming it saves its tokens twice; in a twenty-step run, nineteen times. **Return what the model needs to decide the next step, and nothing it has to wade through.**

Trimming has a cost of its own: a field left out is a field the model cannot use. `customer_id` looks irrelevant to a refund question, and is exactly what lesson 17 needs to check that the person asking owns the order. The usual compromise is a tool per purpose (an order summary for the agent, the full record for code that needs it) rather than one tool that returns everything.

## Four rules for observations

- **Structured, and labelled.** `{"status": "delivered", "delivered_on": "2026-09-18"}` beats `delivered 2026-09-18`, because the model does not have to guess which date is which.
- **Units in the field name or the value.** `get_order` returns cents, and the model in section 03 had to turn 7780 into 77.80. `total_cents` would have said so; a tool that returns money with no unit invites a refund a hundred times too large.
- **Errors are observations too.** A failed lookup should come back as a short, specific message (*"no order M-9999"*) marked as an error, so the model can correct the id or ask the customer. Lesson 4 builds that, and it is what keeps a typo from becoming a crash.
- **Bounded.** A search that could return a thousand rows returns the top few and says how many there were. An observation that does not fit in the context window ends the run, and one that nearly fits leaves no room for the answer.

## Observations are not instructions

Everything a tool returns is text the model reads, and some of it was written by people who are not the user: a help article, a product review, a customer's earlier message. **A model can mistake text inside an observation for an instruction**, and that is how indirect prompt injection works (`prompt-engineering` lesson 7). Lesson 17 builds the defence in the host, where it belongs; for now the habit to form is to treat an observation as data that arrived from outside, whatever it says.
