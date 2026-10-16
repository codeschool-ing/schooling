---
title: What a timeout tells you, and what it does not
version: 1
---

**A timeout is not a failure. It is the absence of an answer, and the request may well have
succeeded.** boxoffice waits two seconds for the provider, as its `charge` function says with
`AbortSignal.timeout(2000)`, and then gives up and answers `504`. Giving up is the right thing for a
server to do, because a client kept waiting forever is worse than a client told "not in time". But
giving up undoes nothing on the other side.

## A provider that answers too late

The stub's `slow` mode approves the charge after three seconds, one more than boxoffice waits. curl's
`-w` prints the status and the total time of the request:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d slow
{"mode":"slow"}
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":4}'
504 2.005139
```

`504` after a little over two seconds: boxoffice's own deadline, not the stub's. Now look at the other
side once the stub has finished:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"ord-1006","amount_cents":26000,"reference":"ord-1006"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
4
```

**The provider received the charge, and boxoffice released the seats.** The stub's log says how it
ended:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
POST /charges 201 (approve)
GET /__requests 200 (approve)
PUT /__mode 200 (decline)
POST /charges 201 (decline)
PUT /__mode 200 (down)
POST /charges 500 (down)
PUT /__mode 200 (approve)
DELETE /__requests 204 (approve)
POST /charges 201 (approve)
POST /charges 201 (approve)
GET /__requests 200 (approve)
DELETE /__requests 204 (approve)
PUT /__mode 200 (slow)
POST /charges the caller hung up first (slow)
GET /__requests 200 (slow)
```

`the caller hung up first`: the stub had recorded the charge when it arrived. It approved it a second
after boxoffice stopped listening. With a real provider, that is a customer who was charged for an
order the app reported as failed. **This is the most expensive failure in the lesson, and no status
code reveals it.** The only party that knew the outcome had already been hung up on.

## What a test should assert

A test of a timeout can check four things, and the fourth is the one that needs another service:

- the status, `504`, and its problem body;
- the duration, against a window around the server's deadline: at least 1.9 seconds, because a much
  faster `504` means the deadline is not what it claims, and under 3, because a much slower one means
  it is not enforced;
- the state: the seats are free again;
- the other side: the provider received a charge, so the order's true outcome is unknown, not failed.

The test needs its own deadline too. If boxoffice's timeout were broken, the request would hang, and a
test with no limit hangs with it. node's `{ timeout: 5000 }` option fails the test after five seconds
instead. Save it as `tests/timeout.test.mjs`:

```js
// tests/timeout.test.mjs: a provider that answers too late.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8187';
const STUB = 'http://localhost:8197';
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8197', MODE: 'slow' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8187', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

test('a slow provider is a 504 after about two seconds', { timeout: 5000 }, async () => {
  const started = performance.now();
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  const took = performance.now() - started;
  assert.equal(placed.status, 504);
  assert.ok(took >= 1900 && took < 3000, `took ${Math.round(took)} ms`);
  assert.equal((await get(`${BASE}/v1/shows/sh-103`)).body.seats_left, 4);
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.length, 1, 'the provider received the charge boxoffice gave up on');
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/timeout.test.mjs | grep -E '^(not )?ok|duration_ms|^# (pass|fail)'
ok 1 - a slow provider is a 504 after about two seconds
  duration_ms: 2225.285863
# pass 1
# fail 0
# duration_ms 2358.232913
```

`performance.now()` measures elapsed time with a clock that never jumps when the system's time is
adjusted, which `Date.now()` cannot promise.

## What a client should do with a 504

**Treat it as "unknown", never as "failed".** The safe moves follow from the rest of the lesson. One
is to retry the same request with the same idempotency key, so that if the first attempt went
through, the retry finds it. The other is to ask the server for the order's state before telling the
user anything. Both depend on the server keeping its promise. boxoffice remembers a key only after a
charge succeeds, so a retry after its `504` places a new order. It does pass the client's key on to
the provider, the one place that can recognise the repeat. The stub here does not. A real provider
that honours idempotency keys would answer the second charge with the first. That chain, client key
to server to provider, is what a tester follows end to end when the word *timeout* appears in a
report.
