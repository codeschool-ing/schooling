---
title: Two calls in one reply
version: 1
---

A model may ask for several tools in one reply when the calls do not depend on each other. Asked about two orders, there is no reason to look up the first, wait, and then look up the second. **The course scripted the stand-in to ask for both at once**, as current models do:

```
ana@lab:~/agents$ python agent.py "What is the status of my orders M-1043 and M-1048?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive.
```

Both calls carry step number `[1]`: one reply, two `tool_use` blocks, two results sent back together in one message. The run took two requests instead of three. With the lab's timing rule that saves one request's worth of time; with tools that take seconds each, such as a web fetch or a slow database, running them concurrently in the host saves the slower one's time too. `agent.py` runs them one after the other, which is correct and simple; lesson 18 measures what concurrency buys.

## Every call gets its result

The API requires every `tool_use` in a reply to be answered by a `tool_result` with its id in the very next message. `--drop-one` sends only the first result back, the bug a host has when it stops processing a reply's blocks after the first one, or when one tool raises and the loop skips the rest:

```
ana@lab:~/agents$ python agent.py "What is the status of my orders M-1043 and M-1048?" --drop-one 2>&1 | tail -n 1
anthropic.BadRequestError: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: tool_use ids were found without tool_result blocks immediately after: toolu_lab_0012_2'}, 'request_id': 'req_lab_0013'}
```

labllm refuses the conversation the way Anthropic's API does: `messages.2` (the third message, counting from zero) has a call whose id never got a result. **The fix is never to drop a call silently.** If a tool cannot run, send a result anyway, marked as an error, saying why (*"not run: the previous call failed"*). The model then knows what happened to every request it made.

## When not to run calls together

Independent reads can run together safely. Calls that depend on each other, or that write, should not, even if a model asks for them in one reply. A refund and the lookup that justifies it belong in that order, and two refunds for the same order in one reply are more likely a mistake than a plan. A host can run reads concurrently and writes one at a time, or refuse a reply that asks for more than one write.
