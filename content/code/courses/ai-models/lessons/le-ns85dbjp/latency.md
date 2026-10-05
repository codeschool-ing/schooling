---
title: Latency is two numbers
version: 1
---

"How fast is it" has two answers, and a person feels them differently.

- **Time to first token**: from sending the request to the first piece of the reply. With
  streaming, this is how long the screen stays blank.
- **Time to the whole reply**: until the last token. This is what a program waits for when it needs
  the complete answer before doing anything, and what a person waits for when the reply is short.

The first depends on the provider's queue, the length of the prompt, and how much a reasoning model
thinks before answering. The second adds the generation speed of lesson 3 section 05 times the
length of the reply.

## Measuring it, and why a single run says nothing

Latency varies from one request to the next: queues, other customers, the network. So it is
measured many times and reported as a **distribution**: the **median** (p50), what a typical
request sees, and the **95th percentile** (p95), what one request in twenty sees or worse. The p95
is the number an annoyed user remembers.

`lab/latency.py` streams the same drafting request twenty times to each of the stand-in's models
and times both moments:

```python
import statistics
import sys
import time

import anthropic

client = anthropic.Anthropic()
email = "Hello, where is my parcel? LB-20488"
print(f"{'model':14} {'first token p50':>16} {'p95':>6} {'whole reply p50':>16} {'p95':>6}")
for model in ("standin-large", "standin-small", "standin-local"):
    first, whole = [], []
    for _ in range(int(sys.argv[1])):
        start = time.perf_counter()
        with client.messages.stream(model=model, max_tokens=300,
                                    messages=[{"role": "user", "content": "Draft a reply: " + email}]) as s:
            for i, _text in enumerate(s.text_stream):
                if i == 0:
                    first.append(time.perf_counter() - start)
        whole.append(time.perf_counter() - start)
    q = lambda xs, p: statistics.quantiles(xs, n=20)[p] if len(xs) > 1 else xs[0]  # noqa: E731
    print(f"{model:14} {statistics.median(first):>15.2f}s {q(first, 18):>5.2f}s "
          f"{statistics.median(whole):>15.2f}s {q(whole, 18):>5.2f}s")
```

```
ana@desk:~/desk$ python lab/latency.py 20
model           first token p50    p95  whole reply p50    p95
standin-large             0.85s  1.84s            3.69s  4.68s
standin-small             0.23s  0.39s            1.17s  1.32s
standin-local             1.28s  3.01s            6.92s  8.66s
```

**These timings measure the stand-in, not any real model.** The course set each stand-in's delay
before the first token and per token after it, and told it to stretch the first token by a random
factor with a long tail, the way a shared service does. What is real is the method: the stream,
the clock, the percentiles.

Read it as a pattern. **standin-small** answers before the others have started and finishes first.
**standin-local**, the one playing a self-hosted model on modest hardware, has the slowest first
token and the slowest generation, and its p95 is more than twice its median for the first token.
The gap between the two columns is the reply's length: about 3 seconds of writing for
standin-large, almost 6 for standin-local.

## What matters for ana

- **Sorting** happens in the background, and nobody watches it: latency hardly matters, which
  makes it a candidate for batch prices (section 05).
- **Drafting** has a person waiting. Streaming makes the first-token number the one they feel,
  and the p95 the one that decides whether they trust the tool. Her ceiling, written in section 03
  as a rank with a limit, becomes a number here: **first token under two seconds at p95**.

Measure it on the real candidates, from where the program will run, at the hour it will run. A
latency measured from a laptop at night is a different measurement from one taken from the shop's
server on a Monday morning.
