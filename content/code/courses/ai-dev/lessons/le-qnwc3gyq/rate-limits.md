---
title: Rate limits
version: 1
---

Every provider limits how much one account can ask for: requests per minute, tokens per minute, and
often tokens per day. The numbers depend on the account's tier and the model, and they are on the
provider's console. **What matters to the code is what happens at the limit**: the provider answers
429, and says when to try again.

labllm can be told to allow three requests a minute, so the limit can be seen at work:

```python
"""Five requests in a row, with the SDK's retries off, to see the limit as it is."""
import anthropic

model = anthropic.Anthropic(max_retries=0)
for n in range(1, 6):
    try:
        raw = model.messages.with_raw_response.create(
            model="scripted-1", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
        print(n, raw.http_response.status_code, "remaining:", raw.headers["anthropic-ratelimit-requests-remaining"])
    except anthropic.RateLimitError as e:
        print(n, e.status_code, "retry-after:", e.response.headers["retry-after"], "|", e.message)
```

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"rpm": 3, "clear": true}' >/dev/null; python burst.py
1 200 remaining: 2
2 200 remaining: 1
3 200 remaining: 0
4 429 retry-after: 60 | Error code: 429 - {'type': 'error', 'error': {'type': 'rate_limit_error', 'message': 'This request would exceed the rate limit of 3 requests per minute.'}, 'request_id': 'req_lab_0009'}
5 429 retry-after: 60 | Error code: 429 - {'type': 'error', 'error': {'type': 'rate_limit_error', 'message': 'This request would exceed the rate limit of 3 requests per minute.'}, 'request_id': 'req_lab_0010'}
```

**The headers count down before the limit is reached.** Each successful reply says how many
requests are left in the window: 2, 1, 0. The fourth gets 429 and `retry-after: 60`, the number of
seconds until the oldest request leaves the window. Anthropic's real headers have these names; the
other providers send the same information under their own.

## What to do with a 429

- **Wait as long as `retry-after` says**, not less. Retrying sooner only collects another 429.
- **Read the remaining count before you hit zero.** A batch job that sees `remaining: 1` can slow
  down instead of failing.
- **Share the limit deliberately.** One key serves every user of the application. A queue in front
  of the model, with a limit per user, stops one user's burst from spending everyone's minute.
- **Ask for more when the numbers say so.** Limits rise with use and with a request to the provider.
  A design that only works at a higher tier should know which tier and how to get there.
