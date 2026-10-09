---
title: Handing the conversation over
version: 2
---

The customer of M-1046 writes that the order has not shipped and asks what they can do. This is entirely an orders question, so there is nothing to combine: the right design is to give the conversation to the agent that owns orders and get out of the way.

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python multi.py "My order M-1046 still has not shipped. What can I do?" --handoff
triage hands the conversation to orders
orders -> search_help({"query": "unshipped order M-1046"})
orders: If your order M-1046 still hasn't shipped after it says "Received", you can try cancelling it and placing a new one. If you're expecting the parcel but it hasn't arrived, you can open a claim with us and we'll work with the carrier to send a replacement or provide a refund.
ana@lab:~/agents$ python tally.py
triage        requests 1   input   210   output   14
orders        requests 2   input   598   output   84
total         requests 3   input   808   output   98
```

The triage agent made one request, with two tools that take no arguments, `transfer_to_orders` and `transfer_to_catalogue`, and called the first. **Its whole output was 14 tokens**, an empty `{}` and the call's name around it, because the decision is the tool's name and there is nothing else to say. The host then ran the orders specialist on the customer's message, and the specialist answered the customer itself. It searched the help centre without looking the order up, and its answer is half right: the article on changing an order says an order that still says Received can be cancelled and placed again. The claim it offers next belongs to a parcel marked delivered that never arrived, which is not this customer's problem. `get_order` would have shown `received`.

Nothing came back to the triage agent. That is the defining property of a handoff, and it is both its strength and its risk. **The strength**: the specialist sees the customer's own words rather than a paraphrase, and the conversation pays for no orchestrator reading answers. **The risk**: if the customer's next message is about books, the orders specialist has no tool for it. A handoff design therefore needs a way back: a `transfer_to_triage` tool on every specialist, or a host that sends each new message through triage again.

## What moved

`triage()` passes the specialist a new conversation containing the customer's message. In a longer conversation the choice is real: pass every earlier turn, including earlier agents' tool calls and results, or pass only what the customer said. Passing everything preserves context and carries other agents' data (and cost) into an agent that may not need it. Passing only the customer's turns is cheaper and cleaner and loses what earlier agents found. **Whichever you choose, choose it in code**, and know what the receiving agent can see.
