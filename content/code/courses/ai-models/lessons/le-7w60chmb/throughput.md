---
title: How fast it answers
version: 1
---

Fitting in memory says whether a model runs. **How fast it generates** comes from a second number
about the same memory: how many bytes per second the accelerator can read from it, its **memory
bandwidth**.

The reason is the way generation works. To produce each new token, the runtime multiplies the
current state by **every weight in the model**, once. For a single request, the arithmetic is quick
and the waiting is for the weights to arrive from memory. So a rough ceiling on speed, for one
conversation at a time, is:

**tokens per second ≈ bandwidth ÷ size of the weights**

`size.py` takes the bandwidth as an argument and prints that ceiling for the 4-bit weights. The
two figures below are **the course's assumptions**, chosen to show the shape, not specifications of
any product: 1,000 GB/s, and three times that.

```
ana@desk:~/desk$ python size.py 1000 | cut -c1-17,76-
model            at 4-bit
Llama-3.1-8B          249
Llama-3.1-70B          28
Llama-3.1-405B          5
ana@desk:~/desk$ python size.py 3000 | cut -c1-17,76-
model            at 4-bit
Llama-3.1-8B          747
Llama-3.1-70B          85
Llama-3.1-405B         15
```

The 8B at 4 bits could produce up to about 249 tokens a second with 1,000 GB/s; the 405B, about 5.
Real runtimes reach some fraction of these ceilings, and the cache from section 03 has to be read
too, which matters more as the context grows.

## What the numbers mean for a reader

Five tokens a second is slower than people read. A reply of 300 tokens takes a minute to appear.
For ana's sorting task, which answers in about two tokens, that would barely matter; for drafting a
reply a person is waiting on, it decides.

## Many requests at once

A server rarely handles one conversation. Runtimes built for serving **batch** requests together:
the weights are read once per step and used for every request in the batch, so total throughput
climbs well above the single-request figure while each request goes a little slower. This is how
an API provider makes the arithmetic work, and why self-hosting is cheapest per token when the
machine is **busy**. An idle accelerator costs the same per hour as a busy one, which is the
sentence section 06 turns into money.
