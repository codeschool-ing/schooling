---
title: The race in boxoffice's idempotency
version: 1
---

**An idempotency key protects against a request sent again later. Whether it protects against the
same request sent twice at once is a separate question, and the answer is often no.** A double tap on
a slow phone sends two identical requests a few milliseconds apart. So does a retry that fires while
the first attempt is still in flight. Section 02 showed boxoffice replaying correctly when the second
request came after the first had finished. This section sends them together.

## Two at once

In bash, `&` puts a command in the background. A loop that ends each `curl` with `&` starts both
before either finishes, and `wait` waits for both. The stub was switched back to approving and its
record emptied first:

```
ana@laptop:~/boxoffice$ for i in 1 2; do curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: tap-tap' -d '{"show_id":"sh-102","seats":1}' & done; wait
{"id":"ord-1004","show_id":"sh-102","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-3"}
{"id":"ord-1005","show_id":"sh-102","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-4"}
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"tap-tap","amount_cents":8000,"reference":"ord-1004"}
{"idempotency_key":"tap-tap","amount_cents":8000,"reference":"ord-1005"}
```

**Two orders, two ids, and two charges with the same idempotency key.** The key was supposed to make
the second request a replay, and it did nothing. A customer who double-tapped *Buy* paid twice.

## Why it happens

boxoffice's code shows it in `createOrder`: the reply is remembered with `replies.set(...)` only
after the charge has returned. Until then, a second request with the same key finds nothing
remembered and does all the work again:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 262\" role=\"img\" aria-label=\"Two requests with the same key, side by side, B starting a moment after A. Each asks whether the key is remembered and gets no, creates an order, ord-1001 for A and ord-1002 for B, charges the provider, and only then remembers the key. A bar marks the window, from A checking the key to A remembering it, while the charge is in flight; B checked inside it.\"><defs><marker id=\"f13race-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"200\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">request A</text><text x=\"500\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">request B, same key</text><rect x=\"110\" y=\"38\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">key remembered? no</text><line x1=\"200\" y1=\"74\" x2=\"200\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"110\" y=\"90\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">creates an order</text><text x=\"200\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ord-1001</text><line x1=\"200\" y1=\"126\" x2=\"200\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"110\" y=\"142\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">charges the provider</text><line x1=\"200\" y1=\"178\" x2=\"200\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"110\" y=\"194\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">remembers the key</text><rect x=\"410\" y=\"64\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">key remembered? no</text><line x1=\"500\" y1=\"100\" x2=\"500\" y2=\"114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"410\" y=\"116\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">creates an order</text><text x=\"500\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ord-1002</text><line x1=\"500\" y1=\"152\" x2=\"500\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"410\" y=\"168\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">charges the provider</text><line x1=\"500\" y1=\"204\" x2=\"500\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><rect x=\"410\" y=\"220\" width=\"180\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">remembers the key</text><line x1=\"40\" y1=\"30\" x2=\"40\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f13race-ah)\"></line><text x=\"48\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text><rect x=\"318\" y=\"38\" width=\"6\" height=\"192\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"324\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">the window: the charge in flight</text></svg>", "caption": "Both requests check the key before either has remembered it, so both do all the work."}
```

The window is the time the charge takes. That is a few milliseconds against a local stub and much
longer against a real provider, so **the defect grows worse in production than in any test**.
Section 02's replay test passed because its two requests were sequential. No amount of sequential
testing would have found this.

## The test that keeps it in sight

`Promise.all` starts both requests before awaiting either, which is the double tap in code. The test
asserts what should be true, one charge and one order. It carries the `todo` option of lesson 12,
because the defect is known and unfixed. Save it as `tests/race.test.mjs`:

```js
// tests/race.test.mjs: two requests with one key, at the same moment.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8186';
const STUB = 'http://localhost:8196';
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8196' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8186', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

test('two requests with one key make one order', { todo: 'boxoffice makes two: the race of lesson 13' }, async () => {
  const key = { 'idempotency-key': 'double-tap' };
  const body = { show_id: 'sh-102', seats: 1 };
  const [a, b] = await Promise.all([order(BASE, bearer, body, key), order(BASE, bearer, body, key)]);
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.length, 1, `charged ${charges.length} times`);
  assert.equal(a.body.id, b.body.id);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/race.test.mjs
TAP version 13
# Subtest: two requests with one key make one order
not ok 1 - two requests with one key make one order # TODO boxoffice makes two: the race of lesson 13
  ---
  duration_ms: 196.281567
  type: 'test'
  location: '/home/ana/boxoffice/tests/race.test.mjs:19:1'
  failureType: 'testCodeFailure'
  error: |-
    charged 2 times
    
    2 !== 1
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 1
  actual: 2
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/boxoffice/tests/race.test.mjs:24:10)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async Test.run (node:internal/test_runner/test:1054:7)
    async startSubtestAfterBootstrap (node:internal/test_runner/harness:296:3)
  ...
1..1
# tests 1
# suites 0
# pass 0
# fail 0
# cancelled 0
# skipped 0
# todo 1
# duration_ms 315.525839
```

`not ok … # TODO`, with the evidence in the failure: `charged 2 times`. The run passes, so the suite
stays usable, and the report says on every run that the defect is still there.

## The report

| | |
|---|---|
| **title** | Two concurrent orders with the same Idempotency-Key both succeed and both charge |
| **steps** | send two identical `POST /v1/orders` with the same `Idempotency-Key`, the second before the first has answered |
| **expected** | one order; the second request answers with the first's result, or with `409` while the first is in progress |
| **actual** | two orders with different ids, both confirmed; the provider receives two charges with the same key |
| **evidence** | the transcript above, and `tests/race.test.mjs` |
| **impact** | a customer who taps twice pays twice; the window grows with the provider's response time |

**The fix is to claim the key before doing the work.** On the first request, record the key as "in
progress" in the same step that checks it. A second request with that key then finds it taken. It
either waits for the first answer or is told `409 Conflict` to try again shortly, which is what the
IETF draft on idempotency keys suggests. In boxoffice that is a few lines. In a service with several
copies running, the claim has to be atomic in a shared store, such as an insert into a table where
the key is unique. Either way, the test above is how the fix will be checked: the day it passes, take
the `todo` away.
