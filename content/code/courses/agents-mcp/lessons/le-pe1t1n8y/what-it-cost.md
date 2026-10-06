---
title: What the split cost
version: 1
---

`tally.py` reads labllm's log and adds up requests and tokens per agent, telling the agents apart by a phrase in each one's system prompt. The log was emptied before each run.

```python
"""Requests and tokens since the log was emptied, per agent, told apart by their system prompts."""
import json
from collections import defaultdict

WHO = {"orchestrator": "orchestrator", "orders specialist": "orders", "catalogue specialist": "catalogue",
       "triage agent": "triage", "working alone": "agent"}
rows = defaultdict(lambda: [0, 0, 0])
for line in open("/var/log/labllm/requests.jsonl"):
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
orchestrator  requests 2   input   434   output   82
orders        requests 2   input   549   output   34
catalogue     requests 2   input   402   output   42
total         requests 6   input  1385   output  158
```

And for the same question answered by one agent with all three tools:

```
ana@lab:~/agents$ python multi.py "Did my order M-1043 ship yet? Also, can you suggest a science fiction book you have in stock?" --single
agent -> get_order({"order_id": "M-1043"})
agent -> find_books({"genre": "science fiction"})
agent: Yes, order M-1043 has shipped; its tracking code is BR5512340003. For science fiction, we have The Time Machine (24.90) and The War of the Worlds (25.90), both by H. G. Wells, in stock.
ana@lab:~/agents$ python tally.py
agent         requests 2   input   897   output   73
total         requests 2   input   897   output   73
```

The single agent asked for both tools in one reply and answered in its second request: **2 requests and 897 input tokens, against 6 requests and 1385**. The answers are word for word the same, because the course scripted them that way; with a real model they could differ, and the split would have to earn its cost by being better, not just by being different.

Where the extra cost comes from is visible in the table. Each specialist paid for its own system prompt and its own tool definitions twice, once per request. The orchestrator paid to send both questions and to read both answers. **None of that work answered the customer**; it is the price of the boundary.

## When the arithmetic turns around

For this question the split is pure overhead: two tools, two lookups, a short conversation. The balance changes as the work grows:

- When each part takes many steps, a specialist's conversation stays short while a single agent's grows with every part's results, and lesson 1 showed that each request resends the whole conversation. Ten steps of book research inside the single agent would be paid for again in every later order lookup; inside a specialist, they are paid for only there.
- When the parts can run at the same time and each takes a while, the orchestrator waits for the slowest specialist rather than for the sum.
- When the tools need different permissions, the split is not about cost at all (lesson 17).

Measure the task you have. A split chosen because it looks like a sensible organisation chart is a cost with no evidence behind it.
