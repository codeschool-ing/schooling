---
title: The two retries you did not write
version: 1
---

A shared service is sometimes too busy to answer. Anthropic's API says so with its own status code,
and its documentation says what the library does about it:

```
ana@desk:~/desk$ sources quote claude-errors "overloaded_error|529 errors can occur|automatically retries"
# https://platform.claude.com/docs/en/api/errors, read 2026-10-05
 247: overloaded_error
 250: 529 errors can occur when the API experiences high traffic across all users.
 252: The official SDK automatically retries transient failures (such as connection errors,
      rate limits, and 5xx server errors) with exponential backoff, twice by default, honoring
      the
```

`lab/retries.py` sorts one case with a given number of retries and times it. The lab tells the
stand-in to answer the next two requests with a 529, which in the world would be the API being busy:

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
    r = client.messages.create(model="standin-large", max_tokens=16, system=prompt,
                               messages=[{"role": "user", "content": case["text"]}])
    print(f"{r.content[0].text} after {time.monotonic() - start:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - start:.1f} s")
```

```
ana@desk:~/desk$ python lab/retries.py 2
other after 2.0 s
```

```
ana@desk:~/desk$ wire --count 3
POST /v1/messages -> 529 anthropic 
POST /v1/messages -> 529 anthropic 
POST /v1/messages -> 200 anthropic standin-large
```

The program made one call and got an answer. The stand-in received **three requests**, two of which
failed. The library absorbed the failures, waited between attempts, and returned the third as if it
were the first; the only trace in ana's program is the two seconds. With retries off, the same
overload is an exception at once:

```
ana@desk:~/desk$ python lab/retries.py 0
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
next person can read it.
