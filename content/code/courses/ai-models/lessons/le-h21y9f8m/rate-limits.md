---
title: How fast you may ask
version: 1
---

A provider limits how fast an account may send, and Anthropic's documentation says in what units
and how the limit refills:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 217: You might hit rate limits over shorter time intervals. For instance, a rate of 60
      requests per minute (RPM) might be enforced as 1 request per second. Short bursts of
      requests can exceed the limit and trigger rate limit errors.
 222: token bucket algorithm
 223: to do rate limiting. This means that your capacity is continuously replenished up to
      your maximum limit, rather than being reset at fixed intervals.
 322: The rate limits for the Messages API are measured in requests per minute (RPM), input
      tokens per minute (ITPM), and output tokens per minute (OTPM) for each model class.
```

Three limits, any of which can be the one that stops a request: requests, tokens read and tokens
written, each per minute. And **a bucket, not a calendar**: capacity comes back continuously, so a
burst can hit the limit even when the minute's total would have fit. When it does, the answer is a
429, and one header says how long to wait:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 689: The number of seconds to wait until you can retry the request. Earlier retries will
      fail. Not sent with the spend-cap 429 (see
```

Ollama has no limit at all, so the relay from lesson 9 section 03 plays one. Stop it in the second
terminal and start it with `--rpm 5`, five requests a minute; past that it answers 429 with a
`retry-after`, as the documentation describes:

```
ana@desk:~/desk$ python relay.py --rpm 5
relay on 127.0.0.1:8500, to Ollama on 11434, writing wire.jsonl
```

In the terminal you work in, send both libraries to the relay, as lessons 16 and 17 did:

```
ana@desk:~/desk$ export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500
```

`burst.py` sorts eight cases with retries turned off. With `--pace`, a 429 makes it wait as long as
`retry-after` says and send the same case again:

```python
import json
import sys
import time

import anthropic

client = anthropic.Anthropic(max_retries=0)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][:8]
pace = sys.argv[1:] == ["--pace"]

start = time.monotonic()
for c in cases:
    while True:
        try:
            r = client.messages.create(model="llama3.2:3b", max_tokens=16, system=prompt,
                                       messages=[{"role": "user", "content": c["text"]}])
            print(f"{time.monotonic() - start:5.1f}s {c['id']} {r.content[0].text}")
            break
        except anthropic.RateLimitError as e:
            wait = int(e.response.headers["retry-after"])
            print(f"{time.monotonic() - start:5.1f}s {c['id']} 429, retry-after {wait}")
            if not pace:
                break
            time.sleep(wait)   # the header says how long; an earlier retry would fail
```

```
ana@desk:~/desk$ python burst.py
  1.4s c01 order-status, product-question.
  2.6s c02 order-status, refund
  3.6s c03 address-change
  4.5s c04 order-status
  5.2s c05 order-status
  5.2s c06 429, retry-after 55
  5.2s c07 429, retry-after 55
  5.3s c08 429, retry-after 55
```

Five answers, then three refusals, each saying how long to wait, and the program sent the next one
anyway: **the information was in the response it had just read.** Your labels and times will
differ; the five and the three will not. Restart the relay with `--rpm 5` so the minute starts
empty, and run it again with `--pace`:

```
ana@desk:~/desk$ python burst.py --pace
  1.0s c01 order-status
  2.2s c02 order-status, refund
  3.3s c03 address-change
  4.1s c04 order-status
  5.2s c05 order-status, refund.
  5.2s c06 429, retry-after 55
 61.1s c06 order-status
 62.0s c07 refund
 62.0s c08 429, retry-after 1
 63.9s c08 address-change
```

Eight answers in about a minute, and two refusals, each followed by the wait it asked for. The
second shows how the relay counts: a sliding minute, so the five earlier requests leave it one at a
time, a minute after each arrived, and the eighth found it still full for one more second. Against
Anthropic's token bucket, capacity returns a little at a time instead. Either way the
principle holds: **a program that reads what the limit tells it spreads its requests; one that
ignores it fails in bursts** and leans on retries, which lesson 17 showed also count against the
limit. Anthropic also sends headers that say how much is left before the limit is reached:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 694: anthropic-ratelimit-requests-remaining
 695: The number of requests remaining before being rate limited.
```

so a program can slow down before the first 429 rather than after it. Ollama and the relay send
none.

For ana's overnight sorting of a few hundred e-mails, this is a matter of a few lines. For a desk
that grows, it is the reason to ask the provider for a higher tier before the busiest day, not on
it.
