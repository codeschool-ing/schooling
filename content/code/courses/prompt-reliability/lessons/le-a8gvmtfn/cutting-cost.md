---
title: Cutting cost
version: 2
---

A call has two token counts and a price for each, so there are only a few ways to make it cheaper:
send fewer tokens, have fewer written, pay less per token, or pay less per call by waiting. **Each
one changes what the model sees or does, so each one is a change to test**, which is the subject of
the next section.

## Fewer input tokens

Input is what the prompt carries on every call: instructions, examples and the message. The
message is the customer's, so the cuts come from the rest. Shorter instructions, fewer examples,
and, for the part that never changes, the cache of lesson 17.

`v4-only-json.txt` is the examples prompt with its three examples taken out and a line asking for
JSON alone put in:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ python3 cost.py runs/v4.jsonl
runs/v4.jsonl, 40 calls
  input       4846 tokens      121.2 a call
  output      1153 tokens       28.8 a call
  these calls      3.1833 cents
  a million calls  79582.5000 cents
```

Input fell from 248.2 tokens a call to 121.2, and the cost of a million calls from 120,420 cents to
79,582.5, a third less. Output barely moved, 28.8 tokens against 30.6. Whether the examples were
worth 40,837.5 cents a million is a question about what they did, and the next section answers it.

## Fewer output tokens

Output is dearer and slower, so it is the better lever, and there are two ways to pull it. The
first is to **ask for less**: a summary in under twelve words rather than a sentence, no
explanation nobody reads, short keys. Lesson 6 measured what asking does. The second is to cap it,
with `num_predict`, the maximum output length of lesson 6. A cap is not a way to ask for less, as a
cap set below the answer shows:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set num_predict=20 --out runs/cap.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/cap.jsonl
ana@lab:~/triage$ python3 stats.py runs/cap.jsonl
runs/cap.jsonl, 40 calls
  tokens in    mean  248.2   total   9926
  tokens out   mean   20.0   total    800   max 20
  seconds      p50   2.8   p95   3.1   total  115.7
ana@lab:~/triage$ pl check runs/cap.jsonl --failures | grep -c "cut off at num_predict"
40
ana@lab:~/triage$ pl check runs/v3.jsonl | tail -n 1
all          28    12
ana@lab:~/triage$ pl show runs/cap.jsonl t01
│ {"category": "billing", "urgency": "normal", "summary": "Wants a
stop: length, tokens in 250, out 20, 5.5 s
```

The p95 fell from 5.0 seconds to 3.1, and all forty replies were cut off, where uncapped the same
prompt passed 28. Every one of them was longer than twenty tokens, so every one was cut where it
stood, mid-string, and `stop: length` says so. **A cap is a ceiling for the answer that runs away,
set above the longest good answer**, which for this prompt was 38 tokens. It saves money only on
replies that were going wrong anyway.

## A cheaper model for the easy cases

Providers sell several models at different prices, and a smaller one is often good enough for the
plain messages: *"I can't log in"* does not need the most capable model there is. **Routing** sends
each message to the cheap model or the expensive one by a rule decided in advance, such as the
message's length, a keyword, or the cheap model's own confidence. The rule is part of the prompt
now, and it is measured like one: run the whole routed pipeline over the same test sets as the
single model, and compare them message by message.

This lab has the pieces for that and the first lesson measured them: `llama3.2:1b` passed 9 of 40 on
dev where `llama3.2:3b` passed 28, in two-thirds of the memory. A route that sent the easy messages
to the small model would be one more version, and `pl compare` against the single model would say
whether the saving cost any answers.

## Batching what can wait

Not every call has somebody waiting for it. Re-sorting last year's archive with a new prompt, or
running the test sets overnight, can take hours. Several providers sell a batch interface for
exactly that: you submit many requests at once, collect the results later, and pay less per token
than for the same requests one at a time. Anthropic's Message Batches API and OpenAI's Batch API
are two; their documentation gives the discount and how long a batch may take. **A batch is for
work nobody is watching**, never for the customer whose message is being sorted now.
