---
title: Asking a person
version: 2
---

In the `default` mode a call that is not allowed goes to `can_use_tool`, a function you provide. The SDK passes the tool's name and the exact arguments the model chose; the function returns allow or deny, and a deny carries a message for the model.

```schooling-example
{
  "language": "python",
  "file": "cs_refund.py",
  "parts": [
    {
      "code": "async def ask_a_person(tool_name, tool_input, context):\n",
      "note": "**The callback**: tool name, arguments, and a context object."
    },
    {
      "code": "    print(f\"approve?   {tool_name} {tool_input} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    if answer == \"y\":\n",
      "note": "**The person sees exactly what would run**, arguments included."
    },
    {
      "code": "        return PermissionResultAllow()\n",
      "note": "**Allow**: the call runs as the model asked."
    },
    {
      "code": "    return PermissionResultDeny(message=\"Not approved by staff. A colleague will review this refund.\")",
      "note": "**Deny, with a message** that becomes the tool's result."
    }
  ]
}
```

The answers `n` and then `y` were typed by a person and fed on standard input:

```
ana@lab:~/agents$ echo n | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."
/home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1047'}
user       tool_result {"id": "M-1047", "customer_id": "c-106", "placed_on": "2026-09-15", "status": "delivered",
assistant  The order ID M-1047 shows that a copy of the book was delivered to the customer on September 18, 2026. Since the book arrived damaged, I will now proceed with the refund.

I'll now call the `mcp__shop__refund` function with the order_id, the total amount in cents (7780), and a refund reason of "Damaged goods".

Let's execute the refund process.

assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 7780, 'reason': 'Damaged goods'}
approve?   mcp__shop__refund {'order_id': 'M-1047', 'cents': 7780, 'reason': 'Damaged goods'} [y/n] n
user       tool_result (error) Not approved by staff. A colleague will review this refund.
assistant  The refund request has been flagged by staff as needing manual review. Until a human reviewer approves the refund, I am unable to proceed with the refund operation.

I will now call the `mcp__shop__search_help` function to find any relevant articles in Marginalia's help center, which might provide additional information or guidance regarding this situation.

Let's search for relevant articles.

assistant  tool_use mcp__shop__search_help {'query': 'Damaged goods refund'}
approve?   mcp__shop__search_help {'query': 'Damaged goods refund'} [y/n] 
user       tool_result (error) Not approved by staff. A colleague will review this refund.
assistant  It seems that the refund request is still pending manual approval by staff. 

While I cannot complete the refund at this time, I will provide the necessary details to someone who can approve it. If you have any further questions or need assistance with anything else, please let me know.

I will now call the `mcp__shop__search_help` function to look for articles that might assist with this refund request.

Let's search for relevant articles.

result     success turns=4 55730 ms cost_usd=0.0165 session=dd8cc632
ana@lab:~/agents$ echo y | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."
/home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1047'}
user       tool_result {"id": "M-1047", "customer_id": "c-106", "placed_on": "2026-09-15", "status": "delivered",
assistant  The order M-1047 was delivered successfully on 2026-09-18. It includes two copies of the book with the book ID "b19". 

I will now proceed to refund this order in its entirety. Please provide the refund reason so that we can accurately record the refund. 

Could you please specify the reason for the refund?
result     success turns=2 10712 ms cost_usd=0.0024 session=aafae9a0
ana@lab:~/agents$ python -c 'import sqlite3; print(sqlite3.connect("data/shop.db").execute("SELECT order_id, cents, approved_by FROM refunds").fetchall())'
[]
```

Declined, the refund did not run and the model read *"Not approved by staff. A colleague will review this refund."* as an error result. It had asked for 7780 cents, the whole order, for one damaged copy of two: a person reading the question was the only thing between that number and the customer's card, which is the point of asking. Then it tried to search the help centre. `search_help` is not in `allowed_tools` either, so `ask_a_person` asked about it too, found standard input already empty, and refused it with the same sentence about a refund. **A callback written for one tool gets every call that is not allowed**, and its answer has to make sense for each of them.

The `y` run went differently, because the model did: it looked the order up, then asked the customer for a reason instead of calling `refund`, and the run ended with no question for the person at all. The refunds table, read by the last command, is empty. Same program, same input, two different paths: a model's next step is not something a test of the host can fix in advance, and the approval code has to be right for both.

The warning above each run is the SDK's, and it is worth reading: `can_use_tool` will not be invoked for `get_order`, because an `allowed_tools` entry approves the whole tool before the callback is consulted. That is what this program intends (looking up an order needs nobody's approval), and it is also the shape of a real mistake: allow a tool "for now" and the person who was supposed to see each call never sees one. Lesson 8's approval was attached to the tool; here it is the absence of the tool from a list, and a list is easy to extend.

One difference from lesson 8 matters in production. `can_use_tool` is called while the run waits, inside the same process, as lesson 7's `confirm` was. There is no state to save and resume later; a person who answers tomorrow needs a different design, such as a refund tool that only files a request.
