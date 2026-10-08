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
measured many times and reported as a **distribution**: the median (p50), what a typical
request sees, and the 95th percentile (p95), what one request in twenty sees or worse. The p95
is the number an annoyed user remembers.

`latency.py` streams the same drafting request twenty times to each of the two models lesson 1
installed, and times both moments:

```python
import statistics
import sys
import time

import anthropic

client = anthropic.Anthropic()  # Ollama, through desk.env
email = "Hello, where is my parcel? LB-20488"
print(f"{'model':14} {'first token p50':>16} {'p95':>6} {'whole reply p50':>16} {'p95':>6}")
for model in ("llama3.2:3b", "llama3.2:1b"):
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
ana@desk:~/desk$ python latency.py 20
model           first token p50    p95  whole reply p50    p95
llama3.2:3b               0.24s  0.38s            9.94s 16.63s
llama3.2:1b               0.16s 10.35s            5.45s 15.15s
```

**These timings are one machine's**: four processors, no graphics card, and both models on
Ollama. Yours will differ, and the shape is what to read. Before the run the 1b model was unloaded,
so its first request had to load it from disk, as the first request of the morning does.

**The first token is quick for both**, a quarter of a second or less at the median. The **p95** is
where they part: 0.38 seconds for the 3b and **10.35 for the 1b**, and the 1b's is the one request
that waited for its model to load. One request in twenty is exactly what a p95 is about, and the
median does not move at all.

**The whole reply is a different number.** The 3b took about ten seconds at the median to write
its draft and the 1b about five and a half: on a processor with no graphics card, a model three
times the size writes more slowly. The p95s, 16.63 and 15.15 seconds, are the longest drafts, and
a model's reply length varies from one request to the next even when the e-mail does not.

## What matters for ana

- **Sorting** happens in the background, and nobody watches it: latency hardly matters, which
  makes it a candidate for batch prices (section 05).
- **Drafting** has a person waiting. Streaming makes the first-token number the one they feel,
  and the p95 the one that decides whether they trust the tool. Her ceiling, written in section 03
  as a rank with a limit, becomes a number here: **first token under two seconds at p95**. On
  the run above the 3b meets it and the 1b misses it on the cold start alone, which keeping the
  model loaded fixes (lesson 14).

Measure it on the real candidates, from where the program will run, at the hour it will run. A
latency measured from a laptop at night is a different measurement from one taken from the shop's
server on a Monday morning.
