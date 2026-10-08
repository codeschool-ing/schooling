---
title: Flaky results
version: 2
---

At temperature 0 the same prompt gives the same replies on one machine, as lesson 8 showed, with
the exceptions it also showed. Above 0 the model samples. Here is the same prompt run twice at
temperature 1, changing nothing but the seed:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --out runs/hot-a.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/hot-a.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --set seed=7 --out runs/hot-b.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/hot-b.jsonl
ana@lab:~/triage$ pl compare runs/hot-a.jsonl runs/hot-b.jsonl
runs/hot-a.jsonl         passes 27/40
runs/hot-b.jsonl         passes 28/40
fixed 1, broken 0
sign test on the 1 that changed: p = 1.000
```

27 and 28, and one message changed. That is less than you might fear, and it fits lesson 8: on this
prompt most of `llama3.2:3b`'s answers are confident ones, and a draw rarely leaves them. But one run
each is all most comparisons ever get, and **one message is the size of difference two prompts are
compared on all the time**. Had those been two prompts, the second would look one case better.

A test that passes and fails the same input on different calls is what programmers call flaky.
Here the flakiness is not a defect in the test; it is the thing being measured.

## A rate over samples

So report a rate. `--samples 5` calls the model five times per message, each with its own seed:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/hot.jsonl
200 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/hot.jsonl
ana@lab:~/triage$ pl check runs/hot.jsonl
check      pass  fail
json        197     3
fields      197     3
labels      197     3
category    178    22
urgency     129    71
all         129    71
```

129 of 200 calls passed, a rate of 0.645, against 28 of 40, 0.70, at temperature 0. **The
per-case view says more than the total**:

```
ana@lab:~/triage$ pl check runs/hot.jsonl --failures | grep -E "^t(07|22|25|36)[ #]"
t07    urgency   high, expected normal
t07#1  urgency   low, expected normal
t07#2  urgency   high, expected normal
t07#3  urgency   low, expected normal
t07#4  urgency   low, expected normal
t22    category  other, expected billing
t22#1  category  other, expected billing
t22#4  category  other, expected billing
t25    category  other, expected account
t25#1  category  other, expected account
t25#2  category  other, expected account
t25#3  category  other, expected account
t25#4  category  other, expected account
t36    urgency   normal, expected high
t36#1  urgency   normal, expected high
t36#2  urgency   normal, expected high
t36#3  urgency   normal, expected high
t36#4  urgency   low, expected high
```

Four messages, four different findings:

- **`t25` failed five calls of five**, the same way each time, and it fails at temperature 0 too.
  That is not flaky at all: it is a stable disagreement about what an app that logs you out is,
  and one run finds it.
- **`t07` failed five of five, two different ways**: `high` three times and `low` twice, where a
  person said `normal`. A count of failures calls it stable; the answers say the model has no
  settled view of it.
- **`t22` failed three of five.** It fails at temperature 0, so here sampling rescued it twice: the
  right answer was in the model's distribution, just not at the top. That is a rate, and only
  samples find it.
- **`t36` passes at temperature 0 and failed all five calls at temperature 1.** The setting is part
  of the prompt.

A case that fails every call is a defect in the prompt, or in the label, and one run finds it. A case
that fails some calls is a rate, and only samples find it. A case that passes at temperature 0 and
fails above it says the setting is part of what you are testing.

## What it costs

Five samples is five times the calls: 200 instead of 40, and lesson 16 measures what each one
costs. It is still the cheaper mistake. Even at temperature 0, lesson 8 showed replies differing
from one call to the next and from one machine to the next, so the habit protects you there too.
**Never report a comparison between two prompts from one run of each** when either was sampled;
report the rates, and the number of samples beside them.
