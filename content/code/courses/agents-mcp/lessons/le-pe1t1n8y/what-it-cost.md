---
title: What the split cost
version: 2
---

`tally.py` reads the recorder's `requests.jsonl` and adds up requests and tokens per agent, telling the agents apart by a phrase in each one's system prompt. The file was removed before each run.

```python
"""Requests and tokens since requests.jsonl was emptied, per agent, told apart by their system prompts."""
import json
from collections import defaultdict

WHO = {"orchestrator": "orchestrator", "orders specialist": "orders", "catalogue specialist": "catalogue",
       "triage agent": "triage", "working alone": "agent"}
rows = defaultdict(lambda: [0, 0, 0])
for line in open("requests.jsonl"):
    r = json.loads(line)
    who = next(name for key, name in WHO.items() if key in (r["request"].get("system") or ""))
    rows[who][0] += 1
    rows[who][1] += r["usage"]["input_tokens"]
    rows[who][2] += r["usage"]["output_tokens"]
for who, (n, i, o) in rows.items():
    print(f"{who:13} requests {n}   input {i:5}   output {o:4}")
print(f"{'total':13} requests {sum(v[0] for v in rows.values())}   input {sum(v[1] for v in rows.values()):5}   "
      f"output {sum(v[2] for v in rows.values()):4}")
```

For the orchestrated run of section 04:

```
ana@lab:~/agents$ python tally.py
orchestrator  requests 2   input   499   output   88
orders        requests 2   input   523   output   45
catalogue     requests 2   input   413   output   59
total         requests 6   input  1435   output  192
```

And for the same question answered by one agent with all three tools:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python multi.py "Did my order M-1043 ship yet? Also, can you suggest a science fiction book you have in stock?" --single
agent -> get_order({"order_id": "M-1043"})
agent -> find_books({"genre": "science fiction"})
agent: Your order M-1043 has shipped. The tracking number is BR5512340003. As for a science fiction book recommendation, I suggest "The Time Machine" by H. G. Wells, which is currently in stock.
ana@lab:~/agents$ python tally.py
agent         requests 2   input   714   output   79
total         requests 2   input   714   output   79
```

The single agent asked for both tools in one reply and answered in its second request: **2 requests and 714 input tokens, against 6 requests and 1435**. And it answered both questions, where the orchestrated run lost the book. On this question the split bought nothing and cost three times the requests; for it to earn that cost, its answers would have to be better, and here they were worse.

Where the extra cost comes from is visible in the table. Each specialist paid for its own system prompt and its own tool definitions twice, once per request. The orchestrator paid to send both questions and to read both answers. **None of that work answered the customer**; it is the price of the boundary.

## When the arithmetic turns around

For this question the split is pure overhead: two tools, two lookups, a short conversation. The balance changes as the work grows:

- When each part takes many steps, a specialist's conversation stays short while a single agent's grows with every part's results, and lesson 1 showed that each request resends the whole conversation. Ten steps of book research inside the single agent would be paid for again in every later order lookup; inside a specialist, they are paid for only there.
- When the parts can run at the same time and each takes a while, the orchestrator waits for the slowest specialist rather than for the sum.
- When the tools need different permissions, the split is not about cost at all (lesson 17).

Measure the task you have. A split chosen because it looks like a sensible organisation chart is a cost with no evidence behind it.
