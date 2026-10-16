---
title: Idempotency keys
version: 1
---

**A `POST` sent twice does the thing twice, and the client cannot always tell whether the first one
arrived.** Lesson 1 said that `POST` is neither safe nor idempotent. On a phone that loses its
signal halfway through *Buy*, the app sees no answer and has two bad choices: send again and maybe buy
two tickets, or give up and maybe buy none while telling the user it failed. An idempotency key
removes the dilemma. The client makes up a key for one intention, "buy these two seats", and sends it
with every attempt at that intention; the server does the work the first time and, for the same key,
answers every later attempt with a copy of the first answer.

boxoffice supports it through the `Idempotency-Key` header, the name an IETF draft standardises and
Stripe, among other payment providers, uses. The key is the client's to choose; a random UUID is the
usual choice, and any string nobody else will use works.

## A replay

Start the stub and boxoffice as in lesson 12, in terminals of their own, and get a token:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

Then the same order twice, with the same key. The second time, `-i` shows the headers too:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: buy-7f3a' -d '{"show_id":"sh-101","seats":2}'
{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-1"}
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: buy-7f3a' -d '{"show_id":"sh-101","seats":2}'
HTTP/1.1 201 Created
content-type: application/json
location: /v1/orders/ord-1001
idempotent-replayed: true
Date: Fri, 16 Oct 2026 01:14:20 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-1"}
```

**The same order, `ord-1001`, both times**, and in the second answer one header more than an ordinary
`201` carries: `idempotent-replayed: true`, which says this answer is a copy. No second order was
created. A key stands for one intention, so boxoffice also checks that a replay really is the same
request:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -H 'idempotency-key: buy-7f3a' -d '{"show_id":"sh-101","seats":3}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"this Idempotency-Key was used with a different body"}
```

`422`: a key reused for a different order is a client defect, and silently replaying the old answer
would tell the client it bought three seats when it bought two. The stub shows the other half of the
promise, **one charge for the key**:

```
ana@laptop:~/boxoffice$ curl -s localhost:8090/__requests | jq -c '.[]'
{"idempotency_key":"buy-7f3a","amount_cents":16000,"reference":"ord-1001"}
```

## As a test

A test of idempotency has to look at both sides, as lesson 12's integration test did: boxoffice's
answers, and the number of charges. It starts its own boxoffice and its own stub, on ports nobody
else uses, so the counts belong to it. Save it as `tests/idempotency.test.mjs`:

```js
// tests/idempotency.test.mjs: the same Idempotency-Key, sent again.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8184';
const STUB = 'http://localhost:8194';
const stops = [];
let bearer;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8194' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8184', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

test('a replay gets the first answer, and nothing is charged twice', async () => {
  const key = { 'idempotency-key': 'replay-1' };
  const first = await order(BASE, bearer, { show_id: 'sh-101', seats: 2 }, key);
  const again = await order(BASE, bearer, { show_id: 'sh-101', seats: 2 }, key);
  assert.equal(first.status, 201);
  assert.equal(again.status, 201);
  assert.deepEqual(again.body, first.body);
  assert.equal(again.headers.get('idempotent-replayed'), 'true');
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.filter((c) => c.idempotency_key === 'replay-1').length, 1);
});

test('the same key with a different body is refused', async () => {
  const key = { 'idempotency-key': 'replay-2' };
  await order(BASE, bearer, { show_id: 'sh-101', seats: 1 }, key);
  const other = await order(BASE, bearer, { show_id: 'sh-101', seats: 3 }, key);
  assert.equal(other.status, 422);
  assert.equal(other.body.detail, 'this Idempotency-Key was used with a different body');
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/idempotency.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - a replay gets the first answer, and nothing is charged twice
ok 2 - the same key with a different body is refused
# pass 2
# fail 0
# todo 0
```

What a tester checks about an idempotency key, beyond these two tests: that the replay carries the
same status and headers, not only the same body; that keys belong to one client, so another client
sending the same key gets an order of its own and never yours (boxoffice keys them by the token's
`sub`); and how long keys are
remembered. boxoffice remembers them until it restarts, and a real service documents a period, often
a day, after which the same key makes a new order.
