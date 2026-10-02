---
title: Cutting cost
version: 1
---

A call has two token counts and a price for each, so there are only a few ways to make it cheaper:
send fewer tokens, have fewer written, pay less per token, or pay less per call by waiting. **Each
one changes what the model sees or does, so each one is a change to test**, which is the subject of
the next section.

## Fewer input tokens

Input is what the prompt carries on every call: instructions, examples and the message. The
message is the customer's, so the cuts come from the rest. Shorter instructions, fewer examples,
and, for the part that never changes, the cache of lesson 17.

`v4-only-json.txt` is the examples prompt with its three examples taken out and nothing else
changed:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl cost runs/v4.jsonl
tokens          count   per call
input            3739       93.5
cache_read          0        0.0
cache_write         0        0.0
output           1520       38.0

cost of these 40 calls: 3.4017 cents
cost of a million calls like them: 85,043 cents
```

Input fell from 238.5 tokens a call to 93.5, and the cost of a million calls from 127,680 cents to
85,043, a third less. Output barely moved, 38.0 tokens against 37.4. Whether the examples were
worth 42,637 cents a million is a question about what they did, and the next section answers it.

## Fewer output tokens

Output is dearer and slower, so it is the better lever, and there are two ways to pull it. The
first is to **ask for less**: a summary in under twelve words rather than a sentence, no
explanation nobody reads, short keys. The second is to cap it, with the maximum output length of
lesson 6. A cap is not a way to ask for less, as a cap set below the answer shows:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set max_tokens=30 --out runs/cap.jsonl
40 calls, prompt 1d9c6ec4, written to runs/cap.jsonl
ana@lab:~/triage$ pl latency runs/cap.jsonl
calls 40
p50 1068 ms   p95 1138 ms   max 1143 ms
output tokens: mean 30.0, max 30
ana@lab:~/triage$ pl check runs/cap.jsonl | tail -n 1
all           1    39
ana@lab:~/triage$ pl show runs/cap.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "They were charged twice for order 4471.
stop: max_tokens, tokens in 238, out 30
```

The p95 fell from 1341 ms to 1138, and the score from 36 to 1. Every reply longer than thirty tokens
was cut where it stood, mid-string, and `stop: max_tokens` says so. **A cap is a ceiling for the
answer that runs away, set above the longest good answer**, which for this prompt was 46 tokens.
It saves money only on replies that were going wrong anyway.

## A cheaper model for the easy cases

Providers sell several models at different prices, and a smaller one is often good enough for
the plain messages: *"I can't log in"* does not need the most capable model there is. **Routing**
sends each message to the cheap model or the expensive one by a rule decided in advance, such as
the message's length, a keyword, or the cheap model's own confidence. The rule is part of the
prompt now, and it is measured like one: run the whole routed pipeline over the same test sets as
the single model, and compare them message by message.

The lab cannot show this. The stand-in is one model with one price, so there is nothing to route
between, and any number here would be invented. What carries over is the method: the routed
pipeline is one version, the single model is another, and `pl compare` between them is what says
whether the saving cost any answers.

## Batching what can wait

Not every call has somebody waiting for it. Re-sorting last year's archive with a new prompt,
or running the test sets overnight, can take hours. Several providers sell a batch interface for
exactly that: you submit many requests at once, collect the results later, and pay less per token
than for the same requests one at a time. Anthropic's Message Batches API and OpenAI's Batch API
are two; their documentation gives the discount and how long a batch may take. **A batch is for
work nobody is watching**, never for the customer whose message is being sorted now.
