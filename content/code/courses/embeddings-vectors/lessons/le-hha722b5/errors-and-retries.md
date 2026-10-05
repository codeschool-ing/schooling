---
title: Errors and retries
version: 1
---

An API is a service somebody else runs, and some of its refusals are about the moment rather than
the request. The commonest is **429, Too Many Requests**: the account has sent more requests or
tokens per minute than its limit allows. Nothing is wrong with the request; it will succeed if it
is sent again a little later.

The wrong idea is to wrap every call in a retry loop of your own. The `openai` SDK already retries,
and a second loop around it multiplies the attempts: three of yours times three of its is nine
requests for one text, all landing on a provider that just said it was busy.

## Watching the SDK retry

labembed has a switch the real service does not: `POST /lab/config` with `{"fail": 2}` makes it
refuse the next two requests with 429, so a rate limit can be produced on demand.

```schooling-example
{
  "language": "python",
  "file": "retry.py",
  "parts": [
    {
      "code": "import time\nimport httpx\nimport openai\nfrom openai import OpenAI\n\nclient = OpenAI()\nprint(\"max_retries\", client.max_retries, \" timeout\", client.timeout)\n\n\ndef fail_next(n):  # the lab's switch, not OpenAI's\n    httpx.post(\"http://127.0.0.1:8500/lab/config\", json={\"fail\": n, \"status\": 429})",
      "note": "The client's defaults, and a helper that tells labembed to answer the next requests with 429, as a provider does when you send too much too fast."
    },
    {
      "code": "fail_next(2)\nstart = time.monotonic()\nr = client.embeddings.create(model=\"lab-minilm\", input=\"When your refund arrives\")\nprint(f\"answered after {time.monotonic() - start:.1f} s with {len(r.data[0].embedding)} numbers\")",
      "note": "Two failures, then an answer. The SDK retries on its own; the program only sees the success, a little late."
    },
    {
      "code": "fail_next(3)\nstart = time.monotonic()\ntry:\n    client.embeddings.create(model=\"lab-minilm\", input=\"When your refund arrives\")\nexcept openai.RateLimitError as e:\n    print(f\"gave up after {time.monotonic() - start:.1f} s:\", type(e).__name__, e.status_code)",
      "note": "Three failures: the first attempt and both retries are refused, and the SDK raises `RateLimitError`."
    },
    {
      "code": "try:\n    client.embeddings.create(model=\"lab-minilm\", input=\"\")\nexcept openai.BadRequestError as e:\n    print(\"not retried:\", type(e).__name__, e.status_code)",
      "note": "An empty string is a 400. Asking again cannot fix the request, so the SDK raises at once."
    }
  ]
}
```

```
ana@lab:~/emb$ python retry.py
max_retries 2  timeout Timeout(connect=5.0, read=600, write=600, pool=600)
answered after 2.2 s with 384 numbers
gave up after 2.0 s: RateLimitError 429
not retried: BadRequestError 400
ana@lab:~/emb$ jq -c '{at, status}' /var/log/labembed/requests.jsonl | tail -n 7
{"at":"2026-10-05T14:19:34-03:00","status":429}
{"at":"2026-10-05T14:19:35-03:00","status":429}
{"at":"2026-10-05T14:19:36-03:00","status":200}
{"at":"2026-10-05T14:19:36-03:00","status":429}
{"at":"2026-10-05T14:19:37-03:00","status":429}
{"at":"2026-10-05T14:19:38-03:00","status":429}
{"at":"2026-10-05T14:19:38-03:00","status":400}
```

The first line is the client's defaults: **`max_retries` 2**, and a timeout of 600 seconds for
reading the answer and 5 for connecting.

With two failures queued, the call **returned normally**. The program never saw the 429s; it only
took longer, because the SDK waited between attempts. labembed sends a `retry-after: 1` header
with each 429, as providers do, and the SDK waited about that long each time. The log shows the
three requests behind one call.

With three failures queued, the first attempt and both retries were refused, and only then did the
SDK give up and raise **`RateLimitError`**. That exception is the one to handle in your own code,
and handling it means slowing down: wait, send less per minute, or queue the work for later, not
an immediate fourth attempt.

The empty string was refused with 400 and raised at once, after a single request. OpenAI's SDK
documents which failures it retries: connection errors, 408, 409, 429 and any 5xx. A 400, 401 or
404 says the request itself is wrong, and sending it again would get the same answer.

## Settings worth choosing

Both defaults can be changed per client or per call, with `OpenAI(max_retries=5, timeout=30)` or
`client.with_options(...)`. Two cases where you would:

- **A background job** that embeds a corpus overnight can afford more retries and longer waits;
  failing at three in the morning because of a brief rate limit wastes the whole run.
- **A search box** cannot. A user is waiting for the query's vector, and ten minutes of read
  timeout is not a wait anybody makes. A short timeout and few retries, with a message to the
  user, is better than a page that hangs.

## Safe to repeat

Retrying is only safe when sending a request twice does no harm. For embeddings it does none:
the request changes nothing on the server, and lesson 1 showed that the same text through the
same model gives the same vector. A retried embedding call that succeeds twice, because the first
answer was lost on the way back, costs its tokens twice and nothing else. That is not true of every
API, and it is why the SDK's habit of retrying on its own is harmless here.
