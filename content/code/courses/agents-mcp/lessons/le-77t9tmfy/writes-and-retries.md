---
title: A retry must not pay twice
version: 1
---

Reads can be repeated freely. Writes cannot, and agents repeat things: a request times out and the host retries it, a model asks for the same refund in two steps, a run is restarted from its trace after a crash. **A tool that changes something must be safe to call twice with the same intent.** That property is called idempotency, and the standard way to get it is a key.

`issue_refund` requires an `idempotency_key`. The first call with a key does the work and records the result under the key; any later call with the same key returns the recorded result and does nothing:

```
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-refund\"}))"
('{"order_id": "M-1042", "refunded": 3480, "left": 0}', False)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-refund\"}))"
('{"order_id": "M-1042", "refunded": 3480, "left": 0, "note": "already processed with this key; nothing refunded now"}', False)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-again\"}))"
('ValueError: cannot refund 3480 cents on M-1042: 0 left to refund', True)
```

The first call refunded 3480 cents on M-1042, all of it. The second, with the same key, returned the same result plus a note, and refunded nothing. The third used a new key, so it was treated as a new refund, and `shop.refund` refused it because nothing was left to refund: `0 left to refund`. **Two independent defences, and each catches something the other does not**: the key stops a retry of the same intent, and the balance check stops a second intent that would overdraw the order.

## Where the key comes from

The key must identify the intent, not the attempt. A good key is something that exists before the agent runs, such as the support ticket the refund belongs to (`ticket-5521-refund`). A key the model invents on each call protects nothing, because each retry invents a new one. So in a production design the host supplies the key, derived from the task, and the model never sees it; this lesson leaves it in the schema so the mechanism is visible.

The same idea runs through payment providers' APIs, which accept an idempotency key header for exactly this reason. An agent's write tool should either use the provider's mechanism or implement its own, as `issue_refund` does with a small JSON file.

## And the refund is still unguarded

`issue_refund` checks its arguments, refuses to overdraw and survives retries. It does not ask anybody whether the refund should happen, and the model can call it whenever the conversation makes it seem right. That is lesson 17's subject. Until then, no agent in this course is given `issue_refund` as a tool; this lesson called it directly.
