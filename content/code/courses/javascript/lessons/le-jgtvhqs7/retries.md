---
title: Trying again, carefully
version: 2
---

Some failures are temporary: a server that is restarting, or busy, answers **`503 Service
Unavailable`** and expects to be asked again. `/api/flaky` in `api.mjs` fails its first two requests that
way:

```html
<!doctype html>
<script type="module">
  import { getJSON } from "./get-json.js";
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));

  async function withRetries(url, attempts = 4) {
    for (let i = 1; i <= attempts; i++) {
      try {
        return await getJSON(url);
      } catch (err) {
        console.log(`attempt ${i} failed: ${err.message}`);
        if (i === attempts) throw err;
        await wait(100 * 2 ** (i - 1));
      }
    }
  }

  const answer = await withRetries("/api/flaky?fails=2");
  console.log("answered on attempt", answer.attempt);
</script>
```

```
ana@dev:~/js$ page retry.html --wait 1500
[error] Failed to load resource: the server responded with a status of 503 (Service Unavailable)
attempt 1 failed: /api/flaky?fails=2: 503 busy, try again
[error] Failed to load resource: the server responded with a status of 503 (Service Unavailable)
attempt 2 failed: /api/flaky?fails=2: 503 busy, try again
answered on attempt 3
```

The third attempt was answered. Between attempts, `withRetries` waited **100 ms, then 200 ms**,
doubling each time. That is **exponential backoff**: a server in trouble gets more breathing room with
each retry, instead of a crowd of clients all retrying at once and keeping it in trouble. Real
clients often add a little randomness to the wait, called **jitter**, so that a thousand clients that
failed together do not all come back together.

## What is safe to retry

**Retry only requests that are safe to repeat.** Reading a book, a `GET`, can be asked for twice with
no harm. Creating a loan, a `POST`, might have succeeded on the server before the answer was lost, and
retrying it would create a second loan. That is the case the last section ended on: the client cannot
tell "it failed" from "it worked and I never heard".

So a retry loop needs three limits:

- **which failures**: a 503 or a lost connection, yes; a 404 or a 422, never, because asking again
  gets the same answer;
- **which requests**: reads freely; writes only when the API makes them safe to repeat, usually with
  an idempotency key the server uses to recognise a request it has already handled;
- **how many times**: `attempts = 4` here, and then the error goes to the user, who deserves to know.

`withRetries` has only the last of the three, which is enough for a `GET` against `api.mjs` and not for real
code, where the first two decide whether retrying helps or harms.
