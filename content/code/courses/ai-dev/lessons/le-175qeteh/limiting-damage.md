---
title: Making the worst case small
version: 2
---

The model cannot be relied on to ignore instructions in the data. **The host can be relied on to
limit what any instruction achieves**, because the host is code. Three changes, each of which would
have stopped lesson 11 section 05's refund on its own.

## Give a task only the tools it needs

Drafting a reply reads orders. It does not pay anybody:

```
ana@dev:~/shop$ git diff support.py
diff --git a/support.py b/support.py
index b7e3e49..2266c8f 100644
--- a/support.py
+++ b/support.py
@@ -1,4 +1,4 @@
-"""Draft a reply to a customer's email, with the shop's tools. Version 1: every tool, no checks."""
+"""Draft a reply to a customer's email. Drafting reads; it never changes anything."""
 import json
 import sys
 from pathlib import Path
@@ -26,7 +26,7 @@ def issue_refund(order_id, cents):
     return f"refunded {cents} cents on order {order_id}"
 
 
-FUNCTIONS = {"get_order": get_order, "issue_refund": issue_refund}
+FUNCTIONS = {"get_order": get_order}  # a draft needs to read, not to pay
 tools = [t for t in TOOLS if t["name"] in FUNCTIONS]
 messages = [{"role": "user", "content": Path(sys.argv[1]).read_text()}]
 for step in range(5):
```

```
ana@dev:~/shop$ rm data/refunds.log; python support.py data/emails/4.txt > draft-2.txt; cat draft-2.txt
call:  get_order({"order_id": "1042"})
draft: Dear Marta,

Unfortunately, I don't see a mug in order 1042. The order details show that we delivered a mug, but it's not included in the order. Could you please provide more information about the order, such as the date you received it or any other details you may have? I'll be happy to assist you further.

Best regards,
[Your Name]
ana@dev:~/shop$ cat data/refunds.log
cat: data/refunds.log: No such file or directory
```

**No refund this time, because there was nothing to call.** The same email, the same model, and
`refunds.log` does not exist. The model looked the order up instead, which is what a draft needs. The
model cannot use a tool the host did not offer, and the host offers per task, not per application.

The draft is still poor, in a new way: it says there is no mug in an order of two mugs. That is the
model misreading a tool result, not the email steering it, and a person reading the draft would see
it; which is the third defence, below.

## Check what the draft claims

The first draft was worse than wrong: it told the customer a refund had been processed. **An injection
can move from the tools into the text**, and text that reaches a customer is an action too. A check
that knows what the conversation did can catch it:

```python
"""Hold a draft that promises what no tool result in the conversation did."""
import re
import sys

DONE = r"(processed|issued|done|sent|emailed)"
PROMISES = {"refund": re.compile(rf"(?is)\brefund(ed)?\b.*\b{DONE}\b|\b{DONE}\b.*\brefund"),
            "return label": re.compile(rf"(?is)\blabel\b.*\b{DONE}\b|\b{DONE}\b.*\blabel\b")}

draft = sys.stdin.read()
held = [what for what, pattern in PROMISES.items() if pattern.search(draft)]
print(f"HOLD for a person: the draft promises a {', '.join(held)}" if held else "ok to send")
```

```
ana@dev:~/shop$ python check_draft.py < draft-1.txt; python check_draft.py < draft-2.txt
HOLD for a person: the draft promises a refund
ok to send
```

**The first draft is held for a person; the second goes.** The check does not understand a draft; it
looks for promises that only a tool result could back, in either order, *refund processed* or
*processed your refund*, and it errs towards holding, which costs a person a minute and costs the shop
nothing. It passed the second draft, which promises nothing and is still wrong about the mugs. **A
check for one kind of mistake is silent about every other kind**, which is why the next defence is a
person.

## Keep a person on anything that moves money

Lesson 7's host asked for approval before `issue_refund`. **That is the third defence and the
strongest**, because the person sees the exact call, `"100000"` cents on order 1042, next to an
email that asked to return one mug.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"Three defences between an instruction hidden in an email and its effect. First, the task is offered only the tools it needs, so a refund tool is not there to call. Second, the draft is checked for promises no tool result backs, and held for a person. Third, any call that moves money waits for a person&#x27;s approval.\"><defs><marker id=\"dl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">an instruction in the email</text><path d=\"M60 62 L60 100 L118 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dl-ah)\"></path><rect x=\"120\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tools for the task</text><text x=\"210.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no refund tool to call</text><rect x=\"320\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">check the draft</text><text x=\"410.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">promises without a result: held</text><rect x=\"520\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a person approves</text><text x=\"610.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">anything that moves money</text><path d=\"M302 100 L318 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dl-ah)\"></path><path d=\"M502 100 L518 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dl-ah)\"></path></svg>", "caption": "None of the three asks the model to behave. Each one limits what happens when it does not."}
```

## What the three have in common

None of them asks the model to behave. **Each one bounds what happens if it does not**: a tool that
is not offered, a draft that is not sent, a call that is not approved. Those hold however the
email is worded, which is the property an instruction in a system prompt does not have.
