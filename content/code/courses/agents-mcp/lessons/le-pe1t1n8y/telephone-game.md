---
title: The telephone game
version: 2
---

Information degrades at every retelling, and in a chain of agents nobody downstream can tell: the agent writing the final answer knows only what reached it across a boundary. Section 04 already showed one form of it, an orchestrator that dropped half of what its specialists found. Here is another question, whether both orders, M-1043 and M-1048, are on their way:

```
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?"
orchestrator -> ask_orders({"question": "Are both of my orders, M-1043 and M-1048, on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: Order M-1043 is on its way and has a tracking number BR5512340003. Order M-1048 was cancelled, so it is not on its way.
orchestrator: To answer the user's question about their orders, I will use the output from the tool call to format the response.

"Hello, I'm happy to help you with your orders. Order M-1043 is currently on its way and you can track its progress with the tracking number BR5512340003. Unfortunately, Order M-1048 was cancelled, so it will not be arriving. If you have any further questions or concerns, please don't hesitate to ask. Is there anything else I can assist you with today?"
```

The specialist did well: it looked up both orders and said, correctly, that one is on its way and the other was cancelled. The orchestrator then began its reply with *"To answer the user's question about their orders, I will use the output from the tool call to format the response"*, which is the instruction line from `llama3.2:3b`'s own chat template (lesson 1's section 07 printed it), repeated as if it were part of the answer, and put the real answer in quotation marks after it. The facts survived this time and the form did not; a customer would read the model's notes to itself.

A model compresses, drops and rewords at every hop, and a careless summary is the case to design for: two results squeezed into one reassuring sentence, *"I found no problems with either"*, when one of them is a cancellation. An orchestrator that sees only that sentence has no way to know what it hides.

## Attaching the evidence

The fix is not a better-worded prompt asking the specialist to be careful. It is to send the facts across the boundary along with the summary. With `--evidence`, `ask()` appends every call the specialist made and the start of each result to its answer, and the host does it, so the specialist cannot leave anything out:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?" --evidence
orchestrator -> ask_orders({"question": "Are both of my orders, M-1043 and M-1048, on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: M-1043 is on its way, but M-1048 was cancelled.
orchestrator: I apologize for the inconvenience, but your order M-1048 has been cancelled. On the other hand, your order M-1043 is currently on its way and should be delivered soon. I'll make sure to keep you updated on the status of your orders. Is there anything else I can assist you with?
ana@lab:~/agents$ python -c 'import json; r = [json.loads(l)["request"] for l in open("requests.jsonl")]; o = [x for x in r if "orchestrator" in x["system"]][-1]; [print(b["content"]) for b in o["messages"][-1]["content"]]'
M-1043 is on its way, but M-1048 was cancelled.
Evidence:
get_order {"order_id": "M-1043"} -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "delivered_on": null,
get_order {"order_id": "M-1048"} -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "status": "cancelled", "delivered_on": nul
```

The last command reads the recorder's file and prints exactly what the orchestrator received as the tool's result: the specialist's sentence, and under it the two results it was supposed to summarise, with `"status": "cancelled"` in plain view. The host appended them, not the specialist, so they arrive whatever the sentence above them says. This specialist's sentence was accurate; a careless one would have been checked against the lines below it.

**The boundary is what improved, not the specialist.** Evidence costs tokens, two lines of results here, and it should be trimmed to the fields that matter (lesson 3's advice on observations applies again). What it buys is that the agent writing the final answer is working from the facts rather than from another model's impression of them, and that whoever reads the trace afterwards can see both the summary and what it summarised.
