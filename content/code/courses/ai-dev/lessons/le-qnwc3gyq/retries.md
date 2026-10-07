---
title: Retries the SDK makes for you
version: 2
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

## A server that is not there

The easiest failure to make on purpose is the server being away. ana stops Ollama and asks, with
`ANTHROPIC_LOG=info`, which makes the SDK say what it is doing:

```python
"""One request, with the SDK's default retries, and how long it took."""
import time

import anthropic

t0 = time.monotonic()
try:
    r = anthropic.Anthropic().messages.create(
        model="llama3.2:3b", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
    print(f"{r.content[0].text!r} after {time.monotonic() - t0:.1f} s")
except anthropic.APIError as e:
    print(f"{type(e).__name__} after {time.monotonic() - t0:.1f} s")
```

```
ana@dev:~/shop$ sudo pkill -x ollama; ANTHROPIC_LOG=info python once.py
[2026-10-07 16:30:00 - anthropic._base_client:1358 - INFO] Retrying request to /v1/messages in 0.380106 seconds
[2026-10-07 16:30:00 - anthropic._base_client:1358 - INFO] Retrying request to /v1/messages in 0.994649 seconds
APIConnectionError after 1.5 s
```

**Two retries, then the error.** The SDK waited about four tenths of a second, then about one second,
and after the third failed attempt raised `APIConnectionError` to the script, a second and a half after
it started. The waits grow each time and carry a random part, so two clients that failed together do
not retry together. That is called exponential backoff with jitter, and it is why the times differ a
little on every run.

The same command again, with Ollama started in another terminal a second after it:

```
ana@dev:~/shop$ ANTHROPIC_LOG=info python once.py
[2026-10-07 16:30:03 - anthropic._base_client:1358 - INFO] Retrying request to /v1/messages in 0.483649 seconds
[2026-10-07 16:30:09 - httpx2:1085 - INFO] HTTP Request: POST http://127.0.0.1:11434/v1/messages "HTTP/1.1 200 OK"
'Hello, how are you today?' after 6.5 s
```

**One retry, then a reply, and the script saw no error.** The first attempt found nobody, the SDK
waited half a second, and the second attempt reached the server, which then spent six seconds loading
the model before it answered. **The SDK's retries end where your policy begins**: one more failure
than it absorbs and the error reaches your code. The choices then are to fail and tell the person, to
queue the work for later, or to ask another provider, which lesson 10 section 08 builds.

A provider fails in more ways than a missing server: 429 when you are over your limit, 500 when it
breaks, 529 when it is overloaded. The SDKs retry all of those the same way. None of them can be made
here without a provider, and the one that matters most for your code comes back in section 08.

## What not to retry

A 400 is a request that is wrong and will be wrong again; a 401 is a key that will not start
working. **Retry only what time can fix**: connection errors, 429, and the 5xx family, which is
what the SDKs do. Ollama would have answered a wrong key without complaint, as section 03 showed, so
test that a 401 stops your program against a provider, not against your laptop. A retry loop of your own around the SDK's, catching everything, multiplies the
waits and retries the errors that should have stopped the program.
