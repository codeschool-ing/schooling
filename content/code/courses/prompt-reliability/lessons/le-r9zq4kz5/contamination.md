---
title: When the test leaks into the prompt
version: 2
---

Lesson 1 warned that an example which is also a test case is answered by copying. This prompt does
it on purpose: it is `v3-examples.txt` with its three examples replaced by three dev cases, word for
word, and they are three that `v3` got wrong. Save it as `prompts/v11-contaminated.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

<example>
Message: Can I pay with a gift card and a credit card on the same order?
Output: {"category": "billing", "urgency": "low", "summary": "Asks whether two payment methods can be combined."}
</example>

<example>
Message: Your app keeps logging me out every few minutes.
Output: {"category": "account", "urgency": "normal", "summary": "The app keeps signing the customer out."}
</example>

<example>
Message: I'd like to cancel my subscription to the monthly box before the next payment.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants to cancel the monthly box before the next charge."}
</example>

Message: {{message}}
```

```
ana@lab:~/triage$ grep -n "Message:" prompts/v11-contaminated.txt
9:Message: Can I pay with a gift card and a credit card on the same order?
14:Message: Your app keeps logging me out every few minutes.
19:Message: I'd like to cancel my subscription to the monthly box before the next payment.
23:Message: {{message}}
ana@lab:~/triage$ grep -E "\"t(22|25|26)\"" cases/dev.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "t25", "message": "Your app keeps logging me out every few minutes.", "expect": {"category": "account", "urgency": "normal"}}
{"id": "t26", "message": "I'd like to cancel my subscription to the monthly box before the next payment.", "expect": {"category": "billing", "urgency": "normal"}}
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/dev.jsonl --out runs/v11.jsonl
40 calls, prompt 9c3b6425, llama3.2:3b, written to runs/v11.jsonl
ana@lab:~/triage$ pl compare runs/v3.jsonl runs/v11.jsonl
runs/v3.jsonl            passes 28/40
runs/v11.jsonl           passes 28/40
fixed 4, broken 4
broken: t03 t16 t18 t38
sign test on the 8 that changed: p = 1.000
```

The same 28 of 40, and four messages moved each way. The four fixed are `t01`, `t22`, `t25` and
`t26`, and three of those are the examples. **Those three cases cannot fail their category any
more**: the prompt contains their answers. Look at the checks rather than the total:

```
ana@lab:~/triage$ pl check runs/v11.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     39     1
urgency      28    12
all          28    12

t02    urgency   high, expected normal
t03    urgency   low, expected normal
t07    urgency   low, expected normal
t09    urgency   high, expected normal
t16    urgency   low, expected normal
t18    urgency   low, expected normal
t24    urgency   high, expected normal
t32    urgency   high, expected normal
t33    urgency   high, expected normal
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    urgency   low, expected normal
```

Thirty-nine categories right of forty, against thirty-five for `v3`. Anybody reading this table
after somebody "improved the examples" would say the categories were nearly solved and the work
left was urgency. Three of the four categories it gained were copied, and the urgencies moved on
their own: `t03`, `t16` and `t18` went from passing to `low`, so the total stayed where it was.

Take the three out and compare like with like. On the 37 messages it was not shown, `v11` passes
25; on the same 37, `v3` passes 28. The holdout says the same thing more loudly:

```
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/holdout.jsonl --out runs/v11-holdout.jsonl
30 calls, prompt 9c3b6425, llama3.2:3b, written to runs/v11-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v3-holdout.jsonl runs/v11-holdout.jsonl
runs/v3-holdout.jsonl    passes 14/30
runs/v11-holdout.jsonl   passes 9/30
fixed 2, broken 7
broken: h04 h12 h13 h25 h26 h28 h30
sign test on the 9 that changed: p = 0.180
```

Fourteen to nine, seven broken and two fixed. Its categories on the holdout:

```
ana@lab:~/triage$ pl check runs/v11-holdout.jsonl
check      pass  fail
json         30     0
fields       30     0
labels       30     0
category     17    13
urgency       9    21
all           9    21
```

Seventeen right, against eighteen for `v3`, and the urgencies fell from fourteen to nine. A sign test
of 0.180 does not call the drop more than chance, and nothing here looks like a gain. **On
everything the contaminated prompt had not seen, it was no better, and probably worse**: three
examples chosen because they were failing dev cases taught it the answers to three dev cases.

## Why it hides

**The size of the inflation depends on how many cases leaked and how many of them were failing**,
and here it hid inside a total that did not move: three copied answers gained, three urgencies lost.
Contamination does not announce itself with a jump. It arrives as a better line somewhere in the
table after somebody improved the examples, which looks exactly like progress, and a set where ten
of forty are pasted into the prompt is measuring thirty while reporting forty.

It happens innocently. The best examples are hard boundary cases, and so are the best test cases,
so the same message is the obvious choice for both. The guard is mechanical: keep examples and
cases in separate files, and before any run, check that no example message appears in a case file.
That check is a single search, and it is cheaper than finding out from a holdout.
