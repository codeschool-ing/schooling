---
title: Rate limits
version: 2
---

Every provider limits how much one account can ask for: requests per minute, tokens per minute, and
often tokens per day. The numbers depend on the account's tier and the model, and they are on the
provider's console. **What matters to the code is what happens at the limit**: the provider answers
429, and says when to try again.

A 429 needs an account, and this lesson spends nothing, so it is described here rather than shown.
**A provider's reply carries the count before the limit is reached**: Anthropic's headers include
`anthropic-ratelimit-requests-remaining` and `anthropic-ratelimit-tokens-remaining`, and the request
that goes over gets 429 with a `retry-after` header, the number of seconds to wait. The other
providers send the same information under their own names. The SDK raises the 429 as
`RateLimitError`, after its own retries, which section 05 measures.

Your own machine has a limit too, and it is not a count per minute. Five questions sent at the same
moment:

```python
"""Five requests at the same moment, and when each one is answered."""
import time
from concurrent.futures import ThreadPoolExecutor

import anthropic

model = anthropic.Anthropic()
t0 = time.monotonic()


def ask(n):
    model.messages.create(model="llama3.2:3b", max_tokens=20,
                          messages=[{"role": "user", "content": "Say hello in five words."}])
    return n, time.monotonic() - t0


with ThreadPoolExecutor(5) as pool:
    for n, seconds in pool.map(ask, range(1, 6)):
        print(f"request {n}: answered after {seconds:.1f} s")
```

```
ana@dev:~/shop$ python burst.py
request 1: answered after 3.7 s
request 2: answered after 1.2 s
request 3: answered after 1.9 s
request 4: answered after 2.7 s
request 5: answered after 4.3 s
```

**Five answers, about eight tenths of a second apart**, in an order nobody chose: the second request
was answered first and the fifth last. Ollama answers one question at a time on this machine, and the
others wait their turn. The model never runs faster for being asked more often; a queue forms, and
the last person in it waits for everybody else's reply. A provider's limit and your machine's are
both reasons to put a queue of your own in front of the model, where you decide who waits.

## What to do with a 429

- **Wait as long as `retry-after` says**, not less. Retrying sooner only collects another 429.
- **Read the remaining count before you hit zero.** A batch job that sees `remaining: 1` can slow
  down instead of failing.
- **Share the limit deliberately.** One key serves every user of the application. A queue in front
  of the model, with a limit per user, stops one user's burst from spending everyone's minute.
- **Ask for more when the numbers say so.** Limits rise with use and with a request to the provider.
  A design that only works at a higher tier should know which tier and how to get there.
