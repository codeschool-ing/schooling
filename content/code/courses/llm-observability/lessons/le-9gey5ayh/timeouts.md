---
title: Timeouts, and choosing one
version: 2
---

A retry helps with a refusal. It does not help with a request that never comes back. For that the
client needs a **timeout**: a limit on how long it waits before giving up and, perhaps, trying again.
The OpenAI SDK's default is ten minutes, chosen for the longest answers a model can write, and far too
long for a customer waiting at a help box.

`timeout.py` sets two seconds and asks for an answer right after `ollama stop` has taken the model
out of memory, so that Ollama has to load it again before the first token. That is the wait lesson
1's first call included, 11.7 seconds of it:

```python
"""timeout.py: one call with a two-second timeout, to a model that has to be loaded first."""
import time

from openai import APITimeoutError, OpenAI

client = OpenAI(timeout=2.0, max_retries=0)
start = time.monotonic()
try:
    client.chat.completions.create(model="llama3.2:3b", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
    print(f"answered after {time.monotonic() - start:.1f} s")
except APITimeoutError as e:
    print(f"{type(e).__name__} after {time.monotonic() - start:.1f} s: {e}")
```

```
ana@dev:~/obs$ ollama stop llama3.2:3b
ana@dev:~/obs$ python timeout.py
APITimeoutError after 2.0 s: Request timed out.
```

Two seconds, an exception, and no answer. Whether that is the right outcome depends on what happens
next, and the week's percentiles are what a timeout is chosen from.

## Choosing one from the week

The `first token` row of the week's percentiles had a p95 of 1,431 ms, a p99 of 1,954 and a maximum
of 2,190. Three choices, three trades:

- **A timeout on the first token of 3 s** cuts off nothing in this week. It catches only the calls
  waiting for something other than the model's reading: a model being loaded, as in `timeout.py`, a
  machine that is busy elsewhere, a provider that has stopped answering. For a customer, a slow
  answer becomes a retry, or an apology, a few seconds sooner.
- **A timeout on the whole call of 3 s** would also cut off every answer longer than about 20
  tokens, which is more than half the week. It confuses a long answer with a stuck one.
- **No timeout of its own**, the SDK's ten minutes, means the slow starts are simply slow, and a
  provider that hangs holds a worker until somebody notices.

So the useful timeout for a streamed call is **on the first token, and between tokens**, not on the
whole call. The SDK's `timeout` is the HTTP client's: it bounds the connection and each read, which
for a stream means the wait for the first piece and the gap between pieces, and it is what fired
above. A limit on the whole call, if one is needed, belongs in the application's own code.

Every timeout belongs on the span when it fires, as an error with its type. The assistant's client
waits up to 60 seconds, which nothing in this week came near, and its retry loop treats a timeout
like any other `APIError`: one more attempt, after a backoff.