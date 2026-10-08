---
title: Limits
version: 2
---

Every model server enforces limits, and each one comes back to the program differently. `limits.py` meets three:

```python
"""Three limits, met one at a time: the reply's length, the context window, and a server too busy to answer."""
import sys
import time

import anthropic

client = anthropic.Anthropic()
SYSTEM = "You answer Marginalia's customers in the cost lesson."
ASK = [{"role": "user", "content": "Say hello to a customer."}]

what = sys.argv[1]
t0 = time.perf_counter()
try:
    if what == "max-tokens":
        r = client.messages.create(model="llama3.2:3b", max_tokens=8, system=SYSTEM, messages=ASK)
        print(r.stop_reason, repr(r.content[0].text))
    if what == "window":                      # about six times the 8192 tokens Ollama was given
        huge = "word " * 50_000 + "\nWhat is the last line of this message?"
        r = client.messages.create(model="llama3.2:3b", max_tokens=32, messages=[{"role": "user", "content": huge}])
        print(r.stop_reason, "input_tokens:", r.usage.input_tokens, repr(r.content[0].text))
    if what == "overloaded":                  # run with ANTHROPIC_BASE_URL at lesson 7's flaky.py
        r = client.messages.create(model="llama3.2:3b", max_tokens=64, system=SYSTEM, messages=ASK)
        print("answered:", r.content[0].text)
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code}: {e.message[:120]}")
print(f"{(time.perf_counter() - t0) * 1000:.0f} ms")
```

**The output limit.** `max_tokens` is a ceiling on what the model may write in one reply:

```
ana@lab:~/agents$ python limits.py max-tokens
max_tokens 'Hello! Welcome to the Cost Lesson.'
1331 ms
```

The reply stopped after 8 tokens, and `stop_reason` was `max_tokens`. This is not an error: the request succeeded, and a program that does not check `stop_reason` will hand a customer a cut sentence. An agent loop has to treat `max_tokens` as its own outcome: raise the limit, ask for a shorter answer, or stop and report.

**The context window.** Lesson 1 gave Ollama a context of 8,192 tokens. `window` sends about fifty thousand words, with a question at the end:

```
ana@lab:~/agents$ python limits.py window
max_tokens input_tokens: 4094 'The last line of this message is: \n\nword word word word word word word word word word word word word word word word word word word word word word word'
53358 ms
```

No error. The request succeeded after 53 seconds, and `input_tokens` says the model read **4,094** tokens of a prompt about twelve times that size. Ollama cut the prompt to fit, keeping its first few tokens and its end, and said so only in its own log, a line `truncating input prompt` with the limit and the prompt's real size (on Linux, `journalctl -u ollama` shows it); the program got an ordinary reply. The model then answered a question about a message it had mostly not read. Anthropic's API refuses the same request with a `400` that names the count, before any work is done, which is the better failure. Either way, an agent whose conversation grows without bound reaches the window on a long enough run, which is why lesson 1 measured growth and the SDKs offer ways to trim history (lesson 8). With a local model, **compare `input_tokens` with what you sent**: it is the only sign the client gets.

**An overloaded server.** Lesson 7's `flaky.py` answers its first requests with `529`, the status Anthropic's API uses for overload, and passes the rest to Ollama. Two failures, then three:

```
ana@lab:~/agents$ python flaky.py 2 > flaky.log & sleep 1; ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python limits.py overloaded; kill $!; echo $(cat flaky.log)
answered: Hello! Welcome to the Cost Lesson. I'm your instructor today. How can I assist you in understanding the world of costs?
5841 ms
529 529 200
ana@lab:~/agents$ python flaky.py 3 > flaky.log & sleep 1; ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python limits.py overloaded; kill $!; echo $(cat flaky.log)
OverloadedError 529: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}}
1423 ms
529 529 529
```

With two failures the call **succeeded**, after 5,841 ms: `flaky.log` shows `529 529 200`. The anthropic SDK retried by itself, twice, with a pause between attempts; that is its default (`max_retries=2`), and it does the same for `429` (rate limited) and other server errors. With three failures the third answer was the last the SDK would try, and the program got `OverloadedError`.

Two lessons from the retries. **They are invisible unless you look**: the first run succeeded, and nothing in the result said that two requests had failed before it. And **a retry is a new request**: it is counted against the rate limit, and if the first attempt actually did work before failing, it may be done twice. For tool calls that change something, that is the argument for making them safe to repeat: an idempotency key, or a check that the action was not already done.
