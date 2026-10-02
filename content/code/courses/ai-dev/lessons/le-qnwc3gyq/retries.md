---
title: Retries the SDK makes for you
version: 1
---

Not every failure is yours. A provider can be overloaded, a connection can drop, a server can fail
for a second. **The SDKs retry those on their own**, and it is worth knowing how many times and for
how long before relying on it.

```
ana@dev:~/shop$ python -c 'import anthropic, openai; a = anthropic.Anthropic(); o = openai.OpenAI(); print("anthropic:", a.max_retries, a.timeout); print("openai:   ", o.max_retries, o.timeout)'
anthropic: 2 Timeout(connect=5.0, read=600, write=600, pool=600)
openai:    2 Timeout(connect=5.0, read=600, write=600, pool=600)
```

Both SDKs retry twice and wait up to 600 seconds for a reply to be read. **Ten minutes is a long
time for a person to look at a spinner.** An interactive feature wants a much shorter timeout; a
batch job may want more retries. Both are arguments when the client is made:
`anthropic.Anthropic(max_retries=4, timeout=30)`.

## Two failures, then a success

labllm can be told to answer 529, "overloaded", to the next few requests. With two of them:

```python
"""One request, with the SDK's default retries, and how long it took."""
import time

import anthropic

t0 = time.monotonic()
try:
    r = anthropic.Anthropic().messages.create(
        model="scripted-1", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
    print(f"{r.content[0].text!r} after {time.monotonic() - t0:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - t0:.1f} s")
```

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 2}' >/dev/null; python once.py
"Hello from the shop's assistant." after 1.6 s
ana@dev:~/shop$ tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["status"], r.get("error", "")) for r in map(json.loads, sys.stdin)]'
529 Overloaded
529 Overloaded
200 
```

**The script saw no error.** The SDK got 529, waited, got 529 again, waited longer, and the third
attempt succeeded; the log shows all three. The waits grow each time and carry a random part, so
two clients that failed together do not retry together. That is called exponential backoff with
jitter, and it is why the time differs a little on every run.

## Three failures

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 3}' >/dev/null; python once.py
OverloadedError 529 after 1.4 s
```

One more failure than the SDK will absorb, and the error reaches your code: `OverloadedError`, 529.
**The SDK's retries end where your policy begins.** The choices are to fail and tell the person, to
queue the work for later, or to ask another provider, which lesson 10 section 08 builds.

## What not to retry

A 400 is a request that is wrong and will be wrong again; a 401 is a key that will not start
working. **Retry only what time can fix**: connection errors, 429, and the 5xx family, which is
what the SDKs do. A retry loop of your own around the SDK's, catching everything, multiplies the
waits and retries the errors that should have stopped the program.
