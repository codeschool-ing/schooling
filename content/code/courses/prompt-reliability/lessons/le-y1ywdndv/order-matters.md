---
title: Order matters
version: 2
---

This prompt says exactly what `v8-guide.txt` says, in a different order: the message first and the
guide after it. Save it as `prompts/v17-message-first.txt`:

```
<message>
{{message|xml}}
</message>

You sort customer messages for Folio, an online bookshop, so that the right
person answers each one and the urgent ones are answered first.

Answer with only a JSON object with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

What the categories mean, because two people answer them:
- billing goes to the accounts desk: money taken, owed or charged wrongly.
- delivery goes to the warehouse: an order on its way, late or lost.
- returns also goes to the warehouse: a book coming back, or a refund for one.
- account goes to whoever runs the website: signing in, settings, personal data.
- other is for anything that needs neither.

Urgency is about harm, not tone. A customer out of pocket, or unable to
reach their account, is high however politely they ask. A question that
can wait a day is low.

The summary is read instead of the message by somebody choosing what to do
next, so it says what the customer needs, without their name.
```

The same five messages:

```
ana@lab:~/triage$ head -n 4 prompts/v17-message-first.txt
<message>
{{message|xml}}
</message>

ana@lab:~/triage$ python3 timing.py prompts/v17-message-first.txt cases/dev.jsonl 5
case  read tokens  read ms  wrote tokens  write ms
t01           287     4833            29      3113
t02           288     4627            34      3705
t03           288     4542            28      3066
t04           284     4530            33      3634
t05           285     4507            29      3137
```

**Every call read for about four and a half seconds.** This prompt starts with `<message>` and then the
customer's own words, so no two calls share more than that tag, and the cache can only reuse a
beginning. The guide behind the message is the same on every call, and the cache cannot reach a word of
it.

Over the forty dev messages:

```
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/static.jsonl
40 calls, prompt d0591569, llama3.2:3b, written to runs/static.jsonl
ana@lab:~/triage$ pl run prompts/v17-message-first.txt cases/dev.jsonl --out runs/first.jsonl
40 calls, prompt 327661b0, llama3.2:3b, written to runs/first.jsonl
ana@lab:~/triage$ python3 stats.py runs/static.jsonl runs/first.jsonl
runs/static.jsonl, 40 calls
  tokens in    mean  285.1   total  11406
  tokens out   mean   28.7   total   1148   max 38
  seconds      p50   3.8   p95   4.6   total  152.7
runs/first.jsonl, 40 calls
  tokens in    mean  285.1   total  11406
  tokens out   mean   30.1   total   1205   max 44
  seconds      p50   7.6   p95   8.4   total  286.0
```

The same tokens in, 285.1 a call, and nearly the same out. The median call took 3.8 seconds with the
guide first and 7.6 with the message first: **twice as long, for reading the same words in a
different order**. Over forty calls that is 152.7 seconds against 286.0, and on a busier day it is
the difference between a queue that keeps up and one that does not.

The cache does not forget a prompt the moment the next one arrives, though. Here are the same five
message-first calls again:

```
ana@lab:~/triage$ python3 timing.py prompts/v17-message-first.txt cases/dev.jsonl 5
case  read tokens  read ms  wrote tokens  write ms
t01           287      191            29      3250
t02           288      205            34      3666
t03           288      186            28      3049
t04           284      202            33      3306
t05           285      153            29      2780
```

Read in under a quarter of a second each. These five exact prompts had been read a few minutes
earlier, and the cache still held them, so the longest stored beginning was the whole prompt. **A
repeated prompt is nearly free to read; a new message at the front is never repeated.** In
production every message is new, which is why the first run is the honest one.

The rule follows directly: **put what is the same on every call at the start, and what varies at
the end**. Instructions, the guide, examples and any fixed reference text go first; the customer's
message, and anything else that changes per call, goes last.
