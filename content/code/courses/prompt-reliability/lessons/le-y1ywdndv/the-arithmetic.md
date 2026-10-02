---
title: The arithmetic
version: 1
---

The cache has two prices of its own in `prices.json`:

```
ana@lab:~/triage$ grep cache prices.json
  "cache_read": 30,
  "cache_write": 375,
```

Plain input costs 300 cents a million tokens. **Reading from the cache costs a tenth of that, and
writing to it costs a quarter more.** The ratios are the course's; the shape, a cheap read and a
dear write, is the one providers describe, and their documentation gives their own numbers.

## What the cache saved

To know what the cache saved you need the same prompt without it. `v17-static-first.txt` is
`v8-guide.txt` with a two-line header, which `diff` confirms by printing nothing but the `echo`:

```
ana@lab:~/triage$ diff <(tail -n +3 prompts/v17-static-first.txt) prompts/v8-guide.txt && echo same template
same template
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/plain.jsonl
40 calls, prompt d0591569, written to runs/plain.jsonl
ana@lab:~/triage$ pl cost runs/plain.jsonl
tokens          count   per call
input           10139      253.5
cache_read          0        0.0
cache_write         0        0.0
output           1536       38.4

cost of these 40 calls: 5.3457 cents
cost of a million calls like them: 133,643 cents
```

Without the cache, all 10139 input tokens were plain input. With it, the same 10139 were split
827, 8736 and 576: **the cache does not change how many tokens are read, only what each one
costs**. In millionths of a cent:

| | without the cache | with it |
|---|---|---|
| input | 10139 × 300 = 3,041,700 | 827 × 300 = 248,100 |
| cache read | | 8736 × 30 = 262,080 |
| cache write | | 576 × 375 = 216,000 |
| output | 1536 × 1500 = 2,304,000 | 1536 × 1500 = 2,304,000 |
| total | 5,345,700 | 3,030,180 |

Those are the 5.3457 and 3.0302 cents `pl cost` printed. The input side fell from 3,041,700 to
726,180, by more than three quarters, and the whole bill by 43%: 133,643 cents a million calls
against 75,755. The output did not move, because a cache only ever touches the prompt.

## When the cache costs more

`v17-message-first` paid 6.0216 cents, more than the same calls with no cache at all would have:
by the same arithmetic, (827 + 9312) × 300 + 1521 × 1500 = 5,323,200 millionths, or 5.3232 cents.
Its 9312 cached tokens were all writes, each 75 cents a million dearer than plain input, and not
one was read back: 9312 × 75 = 698,400 millionths of a cent spent on storing blocks nobody used.
**A prefix used once costs more cached than not cached.** With these prices a block written once
and read once costs 375 + 30 = 405 against 600 for reading it plain twice, so a block pays for
itself from its second use. A prefix that is the same for a handful of calls a day, and expires in
between, may never reach its second use.

## And the time

The stand-in's clock charges a cached token less too:

```
ana@lab:~/triage$ grep -n "^LATENCY" promptlab/model.py
23:LATENCY = {"per_call": 300, "per_input": 0.4, "per_cached": 0.04, "per_output": 20.0, "jitter": 150}
ana@lab:~/triage$ pl latency runs/plain.jsonl
calls 40
p50 1238 ms   p95 1450 ms   max 1503 ms
output tokens: mean 38.4, max 50
ana@lab:~/triage$ pl latency runs/static.jsonl
calls 40
p50 1157 ms   p95 1369 ms   max 1423 ms
output tokens: mean 38.4, max 50
```

A cached token costs 0.04 ms against 0.4, so the 218.4 tokens a call read from the cache saved
about 79 ms each, close to the 81 ms between the two medians. Next to the 20 ms per output token
of lesson 16 it is a modest gain, and the money is the larger reason to cache.
