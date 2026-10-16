---
title: Testing the error path on purpose
version: 1
---

**Most tests check that things work, and most money is lost where things do not.** Think of the
paths where the payment is declined, the provider is down or the provider is slow. They run rarely in
development and daily in production, and nobody sees them until a customer does. They are also the
easiest to test once a stand-in can fail on demand, which is what lesson 11's stub is for.

Each error path needs the same three checks: the answer the client gets, its status and its body;
the state left behind, here the seats; and what the other service saw.

## A decline, and a provider that is down

Set the stub to declining and order all four seats of sh-103, then look at the seats:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d decline
{"mode":"decline"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":4}'
{"type":"about:blank","title":"Payment Required","status":402,"detail":"the payment was declined"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
4
```

`402`, and all four seats still free: the declined order did not hold any. The provider down, the same
order:

```
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8090/__mode -d down
{"mode":"down"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":4}'
{"type":"about:blank","title":"Bad Gateway","status":502,"detail":"the payment provider failed"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq .seats_left
4
```

`502`, *the payment provider failed*, in the same problem shape as every other error, and again four
seats. Both answers are right for a client. `402` tells it to ask the user for another card; `502`
tells it the fault is on the server's side and a retry may help.

## What a failed order leaves behind

boxoffice created an order before it charged, `ord-1003` for the provider that was down, and kept it
when the charge failed. Ask for it:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1003 -H "authorization: Bearer $TOKEN"
{"id":"ord-1003","show_id":"sh-103","seats":4,"total_cents":26000,"status":"failed"}
```

**An order with status `failed`, which the client was never told about**: the `502` carried no id.
That is a finding worth writing down rather than a defect with a fixed answer. The record is useful
to the theatre, which can see failed sales. But a client that wants to reconcile has no way to
connect it to the request that made it, and neither has a support person answering "was I charged?".
A tester raises it as a question: should a failed order's id be in the error, or should the order
not exist?

The end of boxoffice's terminal shows them from its side. The decline is an ordinary `402`. The
provider that was down left an extra line, the one boxoffice prints when it catches a failed charge:

```
POST /v1/orders 402
GET /v1/shows/sh-103 200
  payments: payments answered 500
POST /v1/orders 502
GET /v1/shows/sh-103 200
GET /v1/orders/ord-1003 200
```

## As tests

One file, with its own boxoffice and stub. The two error paths share one test body in a loop, because
they differ only in the mode, the status and the detail. The last test proves that after both
failures the four seats can still be sold. Save it as `tests/errors.test.mjs`:

```js
// tests/errors.test.mjs: what boxoffice does when the payment goes wrong.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8185';
const STUB = 'http://localhost:8195';
const stops = [];
let bearer;

const mode = (name) => fetch(`${STUB}/__mode`, { method: 'PUT', body: name });
const seatsLeft = async () => (await get(`${BASE}/v1/shows/sh-103`)).body.seats_left;

before(async () => {
  stops.push(await start('payments-stub.mjs', { PORT: '8195' }));
  stops.push(await start('boxoffice.mjs', { PORT: '8185', PAYMENTS_URL: STUB }));
  bearer = await token(BASE);
});
after(() => Promise.all(stops.map((stop) => stop())));

for (const [name, status, detail] of [
  ['decline', 402, 'the payment was declined'],
  ['down', 502, 'the payment provider failed'],
]) {
  test(`${name}: ${status}, and the seats are not held`, async () => {
    await mode(name);
    const before = await seatsLeft();
    const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
    assert.equal(placed.status, status);
    assert.equal(placed.body.detail, detail);
    assert.equal(placed.headers.get('content-type'), 'application/problem+json');
    assert.equal(await seatsLeft(), before);
  });
}

test('after the failures, all four seats can still be sold', async () => {
  await mode('approve');
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  assert.equal(placed.status, 201);
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/errors.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - decline: 402, and the seats are not held
ok 2 - down: 502, and the seats are not held
ok 3 - after the failures, all four seats can still be sold
# pass 3
# fail 0
# todo 0
```

**The seat checks are what catch a real class of defect**: an error path that forgets to release
what it reserved. boxoffice holds the seats while it charges and must give them back on every
failure. If one path missed that, its status would still be right. Only the seat count, or the sale
in the last test, would show a show losing seats it never sold.
