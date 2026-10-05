---
title: How fast you may ask
version: 1
---

A provider limits how fast an account may send, and Anthropic's documentation says in what units
and how the limit refills:

```
ana@desk:~/desk$ sources quote claude-rate-limits "measured in requests per minute|token bucket algorithm|continuously replenished|Short bursts"
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-05
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
ana@desk:~/desk$ sources lines claude-rate-limits 686 687
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-05
 686| retry-after
 687| The number of seconds to wait until you can retry the request. Earlier retries will fail. Not sent with the spend-cap 429 (see
```

The lab sets the stand-in to 5 requests a minute, and `lab/burst.py` sorts eight cases with
retries turned off, printing what each response says about the limit:

```python
import calendar
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
    raw = None
    try:
        raw = client.messages.with_raw_response.create(
            model="standin-small", max_tokens=16, system=prompt,
            messages=[{"role": "user", "content": c["text"]}])
        h = raw.headers
        print(f"{time.monotonic() - start:5.1f}s {c['id']} {raw.parse().content[0].text:16} "
              f"remaining {h['anthropic-ratelimit-requests-remaining']}, full at {h['anthropic-ratelimit-requests-reset']}")
    except anthropic.RateLimitError as e:
        print(f"{time.monotonic() - start:5.1f}s {c['id']} 429, retry-after {e.response.headers['retry-after']}")
    if pace and raw is not None and raw.headers["anthropic-ratelimit-requests-remaining"] == "0":
        # out of requests: wait until the limit says it is full again
        reset = time.strptime(raw.headers["anthropic-ratelimit-requests-reset"], "%Y-%m-%dT%H:%M:%SZ")
        wait = max(0.0, calendar.timegm(reset) - time.time())
        print(f"       waiting {wait:.0f}s")
        time.sleep(wait)
```

```
ana@desk:~/desk$ python lab/burst.py
  0.2s c01 order-status     remaining 4, full at 2026-10-05T21:42:07Z
  0.4s c02 Refund           remaining 3, full at 2026-10-05T21:42:07Z
  0.6s c03 address-change   remaining 2, full at 2026-10-05T21:42:08Z
  0.8s c04 product-question remaining 1, full at 2026-10-05T21:42:08Z
  1.0s c05 other            remaining 0, full at 2026-10-05T21:42:08Z
  1.1s c06 429, retry-after 59
  1.1s c07 429, retry-after 59
  1.2s c08 429, retry-after 59
```

Five answers in a second, each saying how many are left, then three refusals. The remaining count
reached 0 on `c05` and the program sent three more anyway: **the information was in the response it
had just read.** With `--pace`, the program reads it:

```
ana@desk:~/desk$ python lab/burst.py --pace
  0.2s c01 order-status     remaining 4, full at 2026-10-05T21:42:09Z
  0.4s c02 Refund           remaining 3, full at 2026-10-05T21:42:09Z
  0.6s c03 address-change   remaining 2, full at 2026-10-05T21:42:10Z
  0.8s c04 product-question remaining 1, full at 2026-10-05T21:42:10Z
  1.0s c05 other            remaining 0, full at 2026-10-05T21:42:10Z
       waiting 60s
 61.4s c06 order-status     remaining 4, full at 2026-10-05T21:43:11Z
 61.6s c07 refund           remaining 3, full at 2026-10-05T21:43:11Z
 61.9s c08 address-change   remaining 2, full at 2026-10-05T21:43:11Z
```

Eight answers and no refusals, in about a minute. The stand-in's limit is a sliding minute, so
waiting for the time in the reset header is waiting for all five to come back; against a real token
bucket, capacity returns a little at a time and a pacer can send again sooner. Either way the
principle holds: **a program that reads the limit headers spreads its requests; one that ignores
them fails in bursts** and leans on retries, which lesson 17 showed also count against the limit.

For ana's overnight sorting of a few hundred e-mails, this is a matter of a few lines. For a desk
that grows, it is the reason to ask the provider for a higher tier before the busiest day, not on
it.
