---
title: The telephone game
version: 1
---

The customer asks whether both orders, M-1043 and M-1048, are on their way. The orchestrator asks the orders specialist; the specialist looks up both. **The course scripted the specialist to summarise carelessly**, the way a real model sometimes compresses two results into one reassuring sentence, to show what happens next. Everything the host does is real.

```
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?"
orchestrator -> ask_orders({"question": "Are orders M-1043 and M-1048 on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: Both orders are in the system and I found no problems with either.
orchestrator: Yes, both of your orders are on their way.
```

The specialist read `shipped` for M-1043 and `cancelled` for M-1048, then answered *"Both orders are in the system and I found no problems with either."* Every word of that is defensible: both orders exist, and a cancellation is not a fault. The orchestrator, which saw only that sentence, answered the question it was asked: yes, both are on their way. **Each agent behaved reasonably, and the customer was told something false**, and will wait for a parcel that is never coming.

That is the telephone game: information degrades at every retelling, and in a chain of agents nobody downstream can tell. The orchestrator had no way to know that "no problems" was hiding a cancellation, because the only thing that crossed the boundary was the retelling.

## Attaching the evidence

The fix is not a better-worded prompt asking the specialist to be careful. It is to send the facts across the boundary along with the summary. With `--evidence`, `ask()` appends every call the specialist made and the start of each result to its answer, and the host does it, so the specialist cannot leave anything out:

```
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?" --evidence
orchestrator -> ask_orders({"question": "Are orders M-1043 and M-1048 on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: Both orders are in the system and I found no problems with either.
orchestrator: Only one of them. M-1043 has shipped (tracking BR5512340003), but M-1048 was cancelled, so nothing from it is on its way.
ana@lab:~/agents$ grep -h l06-tel-orch-2 /var/log/labllm/requests.jsonl | tail -n 1 | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["request"]["messages"][-1]["content"][0]["content"])'
Both orders are in the system and I found no problems with either.
Evidence:
get_order {"order_id": "M-1043"} -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "delivered_on": null,
get_order {"order_id": "M-1048"} -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "status": "cancelled", "delivered_on": nul
```

The last command prints exactly what the orchestrator received as the tool's result. The careless sentence is still there, word for word, and under it are the two results it was supposed to summarise, with `"status": "cancelled"` in plain view. The orchestrator, scripted to read the evidence when it is present, answered correctly: only one order is on its way.

**The specialist did not improve; the boundary did.** Evidence costs tokens, two lines of results here, and it should be trimmed to the fields that matter (lesson 3's advice on observations applies again). What it buys is that the agent writing the final answer is working from the facts rather than from another model's impression of them, and that whoever reads the trace afterwards can see both the summary and what it summarised.
