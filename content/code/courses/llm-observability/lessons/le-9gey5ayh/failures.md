---
title: Failures, and the retries that hide them
version: 1
---

A provider refuses requests. It is overloaded (503, or Anthropic's 529), it is rate limiting this key
(429), or something on its side broke (500). Most of these clear up in a second, which is why every SDK
retries them, and why a failure to the provider is usually not a failure to the customer. The
question for monitoring is whether anybody can still see it.

labobs can be told to refuse a share of requests at random. With 30% refused:

```
ana@lab:~/obs$ curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_rate\": 0.3}"; echo
{"fail": 0, "status": 429, "seed": 7, "slow_rate": 0.01, "fail_rate": 0.3, "fail_status": 503, "cut_after": null}
ana@lab:~/obs$ rm -f spans.jsonl; python ten.py
4115d849  ok      You have 30 days from delivery to return a printed book in t
6baa11fa  ok      Express delivery is not free at any order value. [1]
6f924a7e  ok      We refund within three working days of the return reaching o
959c4df5  ok      Express delivery is not free at any order value. [1]
d91cac9c  ok      You can use the same account on up to six devices at a time.
6436fc01  ok      A gift card is valid for two years from the day it was bough
331a29ae  ok      Kindle readers cannot open our e-books, because Amazon's dev
90c747d8  ok      I could not find that in our documents.
3111c5fa  ok      A standard parcel whose tracking has not changed for 10 work
9ff6b156  ok      I could not find that in our documents.
```

Ten questions, ten answers. Nothing the customer saw failed. `errors.py` reads the spans:

```python
"""errors.py: the model attempts in spans.jsonl, and what became of the requests that made them."""
import json
from collections import Counter

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ")]
asks = [s for s in spans if s["name"] == "ask"]
gens = [s for s in spans if s["name"] == "generate"]
print(f"attempts {len(chats)}, failed {sum(s['status'] == 'ERROR' for s in chats)}")
print("requests by attempts needed:", dict(sorted(Counter(s["attributes"]["app.attempts"] for s in gens).items())))
print(f"requests {len(asks)}, failed {sum(s['status'] == 'ERROR' for s in asks)}")
```

```
ana@lab:~/obs$ python errors.py
attempts 10, failed 2
requests by attempts needed: {1: 6, 2: 2}
requests 10, failed 0
```

**Two of the ten attempts failed, and none of the ten requests did.** Six requests needed one attempt,
two needed two, and two refused before any model call. One of the retried traces:

```
ana@lab:~/obs$ python tree.py 6baa11fa
trace 6baa11fae7dec0ff4b543047a8106bf2   start(ms) took(ms)
      0   1,185 ms  ask
      0      47 ms    embed
     48       3 ms    search
     51   1,134 ms    generate
     51      48 ms      chat extract-1  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'The server is overloaded', 'type': 'overloaded_error', 'code': None}}
    599     585 ms      chat extract-1
  1,185       0 ms    check_citations
ana@lab:~/obs$ python tree.py --attrs 6baa11fa | grep -E "ERROR|attempts"
                       app.attempts = 2
     51      48 ms      chat extract-1  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'The server is overloaded', 'type': 'overloaded_error', 'code': None}}
```

The first attempt was refused with a 503 in 48 ms. The assistant waited half a second, its first
backoff, and asked again; the second attempt answered. The request took 1,185 ms, half a second of it
spent waiting to retry, and the customer saw only a slower answer.

## Two error rates

The week needs both, and they mean different things:

- **The attempt error rate**, failed model calls over all model calls: 2 in 10 here. It is the
  provider's health. When it rises, the provider is having a bad day, and the retries are absorbing it.
- **The request error rate**, requests that reached the customer as an error: 0 in 10. It is the
  customer's experience. When it rises, the retries have run out.

An alert on the second alone fires only when it is already too late. An alert on the first alone
fires on every provider hiccup that the retries absorbed and nobody noticed. **A rising attempt
error rate with a flat request error rate is a warning; both rising is an incident.** Lesson 16 turns
that into rules.

## A retry the trace cannot see

The assistant retries in its own code so that each attempt is a span. Most code leaves it to the SDK,
whose default is two retries. `sdk_retry.py` makes one call that way, with a span around it, while
labobs refuses the next two requests:

```python
"""sdk_retry.py: the SDK retrying inside one span, where the trace cannot see it."""
from openai import OpenAI

import telemetry

telemetry.setup()
client = OpenAI(max_retries=2)
with telemetry.span("chat extract-1", **{"gen_ai.request.model": "extract-1"}):
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
```

```
ana@lab:~/obs$ rm -f spans.jsonl; python sdk_retry.py; python tree.py
trace d1ed988996915d550df75b7bf41c8866   start(ms) took(ms)
      0   1,835 ms  chat extract-1
ana@lab:~/obs$ tail -3 /var/log/labgen/requests.jsonl | python -c "import json, sys; [print(json.loads(l)[\"n\"], json.loads(l)[\"status\"]) for l in sys.stdin]"
2362 503
2363 503
2364 200
```

The trace shows **one span of 1,835 ms, and no error**. labobs' log shows what happened: requests
2362 and 2363 were refused with 503, and 2364 answered. The SDK waited, retried twice, and returned
success, and from inside the application none of that is visible. The span is not wrong, the call did
succeed, but a week of these would show a provider getting slower when it was in fact failing a third
of the time.

Two ways out. Retry in your own code, as `assistant.py` does, with `max_retries=0` on the client. Or
keep the SDK's retries and instrument underneath them: an HTTP-level instrumentation sees each request
the SDK sends, retries included, as a span of its own. Either way, **the provider's failures have to be
counted somewhere, or the first sign of them will be a customer**.
