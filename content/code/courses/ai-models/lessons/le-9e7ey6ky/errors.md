---
title: The two retries you did not write
version: 1
---

A shared service is sometimes too busy to answer. Anthropic's API says so with its own status code,
and its documentation says what the library does about it:

```
# https://platform.claude.com/docs/en/api/errors, read 2026-10-07
 247: overloaded_error
 250: 529 errors can occur when the API experiences high traffic across all users.
 252: The official SDK automatically retries transient failures (such as connection errors,
      rate limits, and 5xx server errors) with exponential backoff, twice by default, honoring
      the
```

`retries.py` sorts one case with a given number of retries and times it. Ollama is never too busy
in that way, so the relay plays the busy API: stop it in the second terminal with Ctrl-C and start
it again with `--fail`, which answers the next two requests with a 529 instead of passing them on:

```
ana@desk:~/desk$ python relay.py --fail 529:2
relay on 127.0.0.1:8500, to Ollama on 11434, writing wire.jsonl
```

```python
import json
import sys
import time

import anthropic

client = anthropic.Anthropic(max_retries=int(sys.argv[1]))
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

start = time.monotonic()
try:
    r = client.messages.create(model="llama3.2:3b", max_tokens=16, system=prompt,
                               messages=[{"role": "user", "content": case["text"]}])
    print(f"{r.content[0].text} after {time.monotonic() - start:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - start:.1f} s")
```

```
ana@desk:~/desk$ python retries.py 2
other. after 1.7 s
```

```
ana@desk:~/desk$ python relay.py show --count 3
POST /v1/messages -> 529 llama3.2:3b
POST /v1/messages -> 529 llama3.2:3b
POST /v1/messages -> 200 llama3.2:3b
```

The program made one call and got an answer. The relay received **three requests**, and failed two
of them. The library absorbed the failures, waited between attempts, and returned the third as if
it were the first; the only trace in ana's program is the time. With retries off, the same overload
is an exception at once. Restart the relay with one failure to hand out:

```
ana@desk:~/desk$ python relay.py --fail 529:1
relay on 127.0.0.1:8500, to Ollama on 11434, writing wire.jsonl
```

```
ana@desk:~/desk$ python retries.py 0
OverloadedError 529 after 0.0 s
```

Both are reasonable defaults, and the point is to know which one is running:

- **The retries count against the rate limit.** Lesson 21 sets a limit on requests per minute, and
  a program that makes 50 calls in a busy minute may send 150.
- **The time goes into the latency.** Lesson 4 section 06's measurements of time to first token
  include whatever retries happened, unless the harness logs them.
- **A batch job wants them; a screen may not.** For ana's overnight sorting, waiting and retrying is
  right. For a page where somebody waits for a draft, a quick failure with a message may be better
  than a silent ten seconds.

`max_retries` is a setting of the client, and the decision belongs in the code beside it, where the
next person can read it. Restart the relay without `--fail` before the next section.
