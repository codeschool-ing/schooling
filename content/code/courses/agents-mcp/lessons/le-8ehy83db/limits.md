---
title: Limits
version: 1
---

Every provider enforces limits, and each one comes back to the program differently. `limits.py` meets four:

```python
"""Four limits a provider enforces, met one at a time."""
import json
import sys
import time
import urllib.request

import anthropic

client = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Say hello to a customer."}]


def lab_config(**settings):
    """labllm's own switch for simulated failures (lab only; a real provider has no such thing)."""
    req = urllib.request.Request("http://127.0.0.1:8600/lab/config", data=json.dumps(settings).encode(),
                                 headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req).read()


what = sys.argv[1]
t0 = time.perf_counter()
try:
    if what == "max-tokens":
        r = client.messages.create(model="scripted-1", max_tokens=8, system="You answer Marginalia's customers in the cost lesson.", messages=ASK)
        print(r.stop_reason, repr(r.content[0].text))
    if what == "window":
        huge = "word " * 210_000
        client.messages.create(model="scripted-1", max_tokens=1024, messages=[{"role": "user", "content": huge}])
    if what in ("overloaded", "overloaded-3"):
        lab_config(fail_next=529, fail_count=2 if what == "overloaded" else 3)
        r = client.messages.create(model="scripted-1", max_tokens=64, system="You answer Marginalia's customers in the cost lesson.", messages=ASK)
        print("answered:", r.content[0].text)
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code}: {e.message[:120]}")
print(f"{(time.perf_counter() - t0) * 1000:.0f} ms")
```

**The output limit.** `max_tokens` is a ceiling on what the model may write in one reply:

```
ana@lab:~/agents$ python limits.py max-tokens
max_tokens "Hello! Marginalia's support team"
563 ms
```

The reply stopped mid-sentence after 8 tokens, and `stop_reason` was `max_tokens`. This is not an error: the request succeeded, and a program that does not check `stop_reason` will hand a customer half a sentence. An agent loop has to treat `max_tokens` as its own outcome: raise the limit, ask for a shorter answer, or stop and report.

**The context window.** Input plus `max_tokens` must fit the model's window, 200,000 tokens in labllm:

```
ana@lab:~/agents$ python limits.py window
BadRequestError 400: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'prompt is too long: 210004 to
57 ms
```

A `400` before any work was done, naming the count. An agent whose conversation grows without bound reaches this on a long enough run, which is why lesson 1 measured growth and the SDKs offer ways to trim history (lesson 8).

**An overloaded provider.** labllm's `/lab/config` makes the next requests fail with `529`, the status Anthropic's API uses for overload. Two failures, then three:

```
ana@lab:~/agents$ python limits.py overloaded; python -c 'import json; print(" ".join(str(json.loads(l)["status"]) for l in open("/var/log/labllm/requests.jsonl")))'
answered: Hello! Marginalia's support team here. How can we help you today?
2345 ms
529 529 200
ana@lab:~/agents$ python limits.py overloaded-3; python -c 'import json; print(" ".join(str(json.loads(l)["status"]) for l in open("/var/log/labllm/requests.jsonl")))'
OverloadedError 529: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}, 'request_id': 'req_l
1250 ms
529 529 529
```

With two failures the call **succeeded**, after 2,345 ms: the log shows `529 529 200`. The anthropic SDK retried by itself, twice, with a pause between attempts; that is its default (`max_retries=2`), and it does the same for `429` (rate limited) and other server errors. With three failures the third answer was the last the SDK would try, and the program got `OverloadedError`.

Two lessons from the retries. **They are invisible unless you look**: the first run succeeded and took four times as long as an ordinary reply, and nothing in the result said why. And **a retry is a new request**: it is counted against the rate limit, and if the first attempt actually did work before failing, it may be done twice. For tool calls that change something, that is the argument for making them safe to repeat: an idempotency key, or a check that the action was not already done.
