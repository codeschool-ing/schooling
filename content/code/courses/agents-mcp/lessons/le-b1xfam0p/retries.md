---
title: When the provider fails
version: 1
---

Model APIs fail in ordinary ways: a rate limit (HTTP 429), an internal error (500), a server too busy to answer (Anthropic's 529, *overloaded*). Most of these pass in a second or two, and the right response is to wait and try again. **The question for an agent is who does the retrying**, because there are three candidates: the SDK, the adapter and the loop.

labllm can fail on request. `/lab/config` takes the status to return and how many times, and it answers only from the machine itself. Here it fails twice, then three times:

```
ana@lab:~/agents$ curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_next\": 529, \"fail_count\": 2}"; echo
{"rpm": 50, "fail_next": 529, "fail_count": 2}
ana@lab:~/agents$ python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." | head -n 1
answered after 4 steps, 2401 tokens
ana@lab:~/agents$ tail -n 6 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(*[json.loads(l)["status"] for l in sys.stdin])'
529 529 200 200 200 200
ana@lab:~/agents$ curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_next\": 529, \"fail_count\": 3}"; echo
{"rpm": 50, "fail_next": 529, "fail_count": 3}
ana@lab:~/agents$ python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." 2>&1 | tail -n 1
anthropic.OverloadedError: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}, 'request_id': 'req_lab_0023'}
```

With two failures, the run answered as if nothing had happened: `answered after 4 steps, 2401 tokens`, the same as without failures. labllm's log shows what happened underneath: `529 529 200`, and then the three other requests of the run. **The anthropic SDK retried twice, by itself, and told nobody.** Its default is `max_retries=2`, with an exponential backoff starting at half a second, and it retries 408, 409, 429 and every 5xx status. With three failures the retries ran out, and the run ended with `anthropic.OverloadedError`, a 529.

## Decide which layer retries

**The SDK's retries are usually the right first layer**: they handle a short outage on one request, honour `retry-after` headers, and keep the loop simple. Know that they are there, and know their limits. Two retries with backoff cover a second or two of trouble, not a minute.

**The loop should not retry a request blindly on top of the SDK.** Two layers of three attempts each are nine requests, and an outage long enough to exhaust the SDK's retries is long enough that a customer is better served by a stopped outcome than by a run that hangs. `minagent` passes `max_retries` to the SDK and leaves the exception to propagate, which is lesson 4's rule: an outage is not something the model can fix, so it is not a tool result.

**Where a retry at the run level makes sense, it should be idempotent.** Retrying a whole run after a crash replays every tool call, which is harmless for reads and dangerous for writes, and is exactly what lesson 4's idempotency keys exist for.

**Rate limits deserve their own handling.** A 429 says you are sending too fast, and retrying faster makes it worse. In a system running many agents, the fix is a limit on concurrent runs or requests per minute, enforced before the request is sent, rather than a retry after it fails.
