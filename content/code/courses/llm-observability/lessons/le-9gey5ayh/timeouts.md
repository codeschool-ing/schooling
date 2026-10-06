---
title: Timeouts, and choosing one
version: 1
---

A retry helps with a refusal. It does not help with a request that never comes back. For that the
client needs a **timeout**: a limit on how long it waits before giving up and, perhaps, trying again.
The OpenAI SDK's default is ten minutes, chosen for the longest answers a model can write, and far too
long for a customer waiting at a help box.

`timeout.py` sets two seconds and asks labobs, told to make every request a cold start, for an
answer:

```python
"""timeout.py: one call with a two-second timeout, to a provider that is about to take four."""
import time

from openai import APITimeoutError, OpenAI

client = OpenAI(timeout=2.0, max_retries=0)
start = time.monotonic()
try:
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
    print(f"answered after {time.monotonic() - start:.1f} s")
except APITimeoutError as e:
    print(f"{type(e).__name__} after {time.monotonic() - start:.1f} s: {e}")
```

```
ana@lab:~/obs$ python timeout.py
APITimeoutError after 2.0 s: Request timed out.
```

Two seconds, an exception, and no answer. Whether that is the right outcome depends on what happens
next, and the week's percentiles are what a timeout is chosen from.

## Choosing one from the week

The `first token` row of the week's percentiles had a p95 of 444 ms and a p99 of 4,257. Three
choices, three trades:

- **A timeout on the first token of 1 s** cuts off the cold starts, 16 calls of the week's 1,108, and
  nothing else. The retry that follows has a 99% chance of being an ordinary call. For a customer, a
  slow answer becomes a slightly less slow one.
- **A timeout on the whole call of 1 s** would also cut off every answer longer than about 30 tokens,
  which is more than half the week. It confuses a long answer with a stuck one.
- **No timeout of its own**, the SDK's ten minutes, means the cold starts are simply slow, and a
  provider that hangs holds a worker until somebody notices.

So the useful timeout for a streamed call is **on the first token, and between tokens**, not on the
whole call. The SDK's `timeout` is the HTTP client's: it bounds the connection and each read, which
for a stream means the wait for the first piece and the gap between pieces, and it is what fired
above. A limit on the whole call, if one is needed, belongs in the application's own code.

Every timeout belongs on the span when it fires, as an error with its type. The assistant's client
waits up to 20 seconds, which nothing in this week came near, and its retry loop treats a timeout like
any other `APIError`: one more attempt, after a backoff.
