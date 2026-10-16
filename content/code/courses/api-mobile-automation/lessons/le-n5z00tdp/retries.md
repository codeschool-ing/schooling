---
title: Which failures to retry, and how
version: 1
---

**A retry is a bet that the same request will get a different answer, and for most failures that bet
is lost before it is placed.** The common belief is that a client should retry whatever failed. A
`422` for seven seats will be a `422` for seven seats on the hundredth try; a `401` stays a `401`
until the token changes. Retrying them wastes time. Against a server that counts failures, it can get
the client locked out. The status code from lesson 1 already says which side should act, and that is
the whole rule:

| failure | retry? | why |
|---|---|---|
| `400`, `401`, `403`, `404`, `409`, `415`, `422` | **no** | the request is wrong, or the state forbids it; it will fail the same way |
| `402` declined | no | the bank said no; asking again is the user's decision, not the client's |
| `429` too many requests | yes, later | the server asked the client to slow down, often with a `Retry-After` header |
| `502`, `503`, `504` | yes | a server behind this one failed, is overloaded or was too slow, and may not be in a moment |
| no answer at all: refused, reset, timed out | yes | nothing came back, so nothing says the request was wrong |
| `500` | it depends | a bug answers `500` every time; a crash under load may not. Most clients do not retry it |

**Retrying is only safe where repeating is safe.** A `GET` can be sent again freely. A `POST` that
creates an order can be retried only with an idempotency key, the same one each time. Without one, a
`504` followed by a retry is how a customer buys two tickets.

## Waiting between tries

How long to wait matters as much as whether. Retrying at once hits a struggling server again before
it recovers. Retrying at fixed intervals makes every client that failed together come back together,
and the second wave knocks the server over again. The answer that has become standard has two parts:

- *exponential backoff*: the ceiling on the wait doubles with each try, 100 ms, 200, 400, up to a
  cap;
- *jitter*: the actual wait is a random time between zero and that ceiling, so the clients spread
  out. Choosing uniformly from zero to the ceiling is called *full jitter*.

A helper that does both, small enough to read whole. Save it as `tests/retry.mjs`:

```js
// tests/retry.mjs: send a request again when the failure is worth retrying.

// The answers that say "not now" rather than "not this": a server or a
// gateway in trouble, or a request to slow down.
const RETRYABLE = new Set([429, 502, 503, 504]);

// Call send() until it gives an answer that should not be retried, at most
// `attempts` times. Between tries wait a random time up to a ceiling that
// doubles each time (full jitter), so many clients that failed together do
// not come back together. A network error, where no answer arrived at all,
// is retried too. Returns the last answer, or throws the last network error.
export async function withRetry(send, {
  attempts = 4, base = 100, cap = 2000,
  sleep = (ms) => new Promise((wake) => setTimeout(wake, ms)), random = Math.random,
} = {}) {
  for (let i = 1; ; i++) {
    let res;
    try {
      res = await send();
    } catch (err) {
      if (i >= attempts) throw err;
    }
    if (res && (!RETRYABLE.has(res.status) || i >= attempts)) return res;
    await sleep(Math.floor(random() * Math.min(cap, base * 2 ** (i - 1))));
  }
}
```

`sleep` and `random` are parameters with real defaults, and that design decision makes it testable.
A test passes a `sleep` that only records the wait, and a `random` that always answers 1. The waits
are then the ceilings themselves, and the test takes no time at all.

## Testing it without a server

A retry helper is logic about answers, so its tests need answers and nothing else. A fake `send` hands
out a list of made-up statuses, one per call, and counts the calls. Save it as `tests/retry.test.mjs`:

```js
// tests/retry.test.mjs: withRetry, against answers made up on the spot.
// No server is involved, so these tests run in milliseconds.
import test from 'node:test';
import assert from 'node:assert/strict';
import { withRetry } from './retry.mjs';

// A fake send(): hands out the given answers in turn and counts the calls.
// An Error in the list is thrown, the way fetch throws when nothing answers.
function answers(...list) {
  const send = async () => {
    send.calls++;
    const next = list.shift();
    if (next instanceof Error) throw next;
    return { status: next };
  };
  send.calls = 0;
  return send;
}
const waits = [];
const opts = { sleep: async (ms) => { waits.push(ms); }, random: () => 1 };

test('a 503 is retried until the answer is good', async () => {
  const send = answers(503, 503, 201);
  assert.equal((await withRetry(send, opts)).status, 201);
  assert.equal(send.calls, 3);
});

test('a 422 is not retried: the same request would fail the same way', async () => {
  const send = answers(422, 201);
  assert.equal((await withRetry(send, opts)).status, 422);
  assert.equal(send.calls, 1);
});

test('a network error is retried', async () => {
  const send = answers(new TypeError('fetch failed'), 201);
  assert.equal((await withRetry(send, opts)).status, 201);
});

test('it gives up after the last attempt and returns that answer', async () => {
  const send = answers(502, 502, 502, 502, 201);
  assert.equal((await withRetry(send, opts)).status, 502);
  assert.equal(send.calls, 4);
});

test('the waits double and stop at the cap', async () => {
  waits.length = 0;
  await withRetry(answers(503, 503, 503, 503, 503), { ...opts, attempts: 6, base: 100, cap: 500 });
  assert.deepEqual(waits, [100, 200, 400, 500, 500]);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/retry.test.mjs | grep -E '^(not )?ok|^# (tests|pass|fail|duration_ms)'
ok 1 - a 503 is retried until the answer is good
ok 2 - a 422 is not retried: the same request would fail the same way
ok 3 - a network error is retried
ok 4 - it gives up after the last attempt and returns that answer
ok 5 - the waits double and stop at the cap
# tests 5
# pass 5
# fail 0
# duration_ms 71.693718
```

Five tests in under a tenth of a second, process start included. Each one pins a rule from the table
above. **The one about 422 matters most**: people break that rule by accident, when a helper retries
on "anything that is not 2xx". The last test shows the shape of the backoff: 100, 200, 400, then the
cap of 500 twice.
