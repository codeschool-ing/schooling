---
title: Asking a person
version: 1
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
/opt/agents/lib/python3.11/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'}
approve?   mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'} [y/n] n
user       tool_result (error) Not approved by staff. A colleague will review this refund.
assistant  I could not issue this refund myself; a colleague will review order M-1047 and reply to you by email.
result     success turns=2 1776 ms cost_usd=0.0045 session=04b52ee3
ana@lab:~/agents$ echo y | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."
/opt/agents/lib/python3.11/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'}
approve?   mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'} [y/n] y
user       tool_result {"order_id": "M-1047", "refunded": 3890, "left": 3890}
assistant  Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
result     success turns=2 1782 ms cost_usd=0.0045 session=aabdccdd
ana@lab:~/agents$ python -c 'import sqlite3; print(sqlite3.connect("data/shop.db").execute("SELECT order_id, cents, approved_by FROM refunds").fetchall())'
[('M-1047', 3890, 'ana')]
```

Declined, the refund did not run and the model read *"Not approved by staff. A colleague will review this refund."* as an error result. Approved, it ran: the second command reads the refunds table, and there is one row, 3890 cents on M-1047, approved by ana. **The answers to the customer were written by the course.**

The warning above each run is the SDK's, and it is worth reading: `can_use_tool` will not be invoked for `get_order`, because an `allowed_tools` entry approves the whole tool before the callback is consulted. That is what this program intends (looking up an order needs nobody's approval), and it is also the shape of a real mistake: allow a tool "for now" and the person who was supposed to see each call never sees one. Lesson 8's approval was attached to the tool; here it is the absence of the tool from a list, and a list is easy to extend.

One difference from lesson 8 matters in production. `can_use_tool` is called while the run waits, inside the same process, as lesson 7's `confirm` was. There is no state to save and resume later; a person who answers tomorrow needs a different design, such as a refund tool that only files a request.
