---
title: Asking for a shorter answer
version: 2
---

The way to get a shorter answer is to ask for it in the prompt, where the model reads it. This is
`v4-only-json.txt` with one line changed. Save it as `prompts/v4-words.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": what the customer needs, in under 12 words

Reply with only the JSON object: no code fence and no other text.

Message: {{message}}
```

```
ana@lab:~/triage$ diff prompts/v4-only-json.txt prompts/v4-words.txt
6c6
< - "summary": one sentence saying what the customer needs
---
> - "summary": what the customer needs, in under 12 words
ana@lab:~/triage$ pl run prompts/v4-words.txt cases/dev.jsonl --out runs/words.jsonl
40 calls, prompt d6ee7191, llama3.2:3b, written to runs/words.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t37
│ {"category": "delivery", "urgency": "high", "summary": "Order status discrepancy for awaiting dispatch book"}
stop: stop, tokens in 130, out 26, 3.2 s
ana@lab:~/triage$ pl show runs/words.jsonl t37
│ {"category": "delivery", "urgency": "high", "summary": "Order status discrepancy after a week"}
stop: stop, tokens in 133, out 25, 3.1 s
```

The model wrote a shorter summary rather than chopping the long one: *Order status discrepancy after
a week*, a different sentence. A request is read; a cap is not. **A length you ask for is a length
you check**, though, the same way you check a label, because nothing obliges a model to count words
correctly.

## How much shorter

```
ana@lab:~/triage$ python3 stats.py runs/v4.jsonl runs/words.jsonl
runs/v4.jsonl, 40 calls
  tokens in    mean  121.2   total   4846
  tokens out   mean   28.8   total   1153   max 38
  seconds      p50   3.5   p95   4.4   total  143.1
runs/words.jsonl, 40 calls
  tokens in    mean  124.2   total   4966
  tokens out   mean   25.3   total   1013   max 31
  seconds      p50   3.0   p95   3.5   total  122.2
ana@lab:~/triage$ pl check runs/words.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     32     8
urgency      21    19
all          21    19
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/words.jsonl --answers
40 cases, same answer 36, different answer 4
  t10    account -> other
  t26    returns -> account
  t38    None -> returns
  t39    account -> delivery
```

The mean reply went from 28.8 tokens to 25.3 and the longest from 38 to 31, and every reply is
still JSON. The request changed what was written, and the closing brace was part of what was
written. **Asking shapes the answer; the cap only cuts it.**

It changed something else too. The one reply that did not parse under `v4-only-json.txt`, `t38`,
parses now: asked for fewer words, the model wrote a summary of the ebook that did not need *won't*,
and the apostrophe that broke the object in lesson 3 never came up. And `--answers` shows the
request moved four categories, in both directions. **A line about length is still a line**, and it
changes what else the model writes; measure it like any other change.

## You need both

A request does not replace the cap. Here is the shorter prompt under the same cap of 25:

```
ana@lab:~/triage$ pl run prompts/v4-words.txt cases/dev.jsonl --set num_predict=25 --out runs/words25.jsonl
40 calls, prompt d6ee7191, llama3.2:3b, written to runs/words25.jsonl
ana@lab:~/triage$ pl check runs/words25.jsonl
check      pass  fail
json         31     9
fields       31     9
labels       31     9
category     26    14
urgency      16    24
all          16    24
```

Nine replies are still not JSON. A summary under twelve words inside its frame can still come to
more than 25 tokens, and a reply that obeys the request exactly is still cut by a cap set below it.
**Ask for the length you want, then set the cap well above it.** The request decides how long the
answer is; the cap exists for the reply that ignores the request.
