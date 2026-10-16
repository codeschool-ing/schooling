---
title: A test that goes through two services
version: 1
---

**An integration test checks that two programs agree, so it has to look at both of them.** A test of
an order that reads only boxoffice's answer proves that boxoffice said `201`. It does not prove that
the charge was made, made once, or made for the right amount, and each of those is a way the two
programs can disagree while boxoffice's answer looks perfect. The payments stub of lesson 11 records
every charge it receives, so a test can read the other side as well.

## The test file

It needs both servers running and talks to both. Save it as `tests/payments.test.mjs`:

```js
// tests/payments.test.mjs: boxoffice and the payments stub, together.
// Needs both running: the stub on STUB, and boxoffice on BASE with
// PAYMENTS_URL pointing at it.
import { test, before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, STUB, token, order, get } from './lib.mjs';

const mode = (name) => fetch(`${STUB}/__mode`, { method: 'PUT', body: name });
let bearer;

before(async () => { bearer = await token(); });
beforeEach(async () => {
  await fetch(`${STUB}/__requests`, { method: 'DELETE' });
  await mode('approve');
});
after(() => mode('approve'));

test('an order is charged once, for its total', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-102', seats: 1 });
  assert.equal(placed.status, 201);
  const { body: charges } = await get(`${STUB}/__requests`);
  assert.equal(charges.length, 1);
  assert.equal(charges[0].amount_cents, 8000);
  assert.equal(charges[0].reference, placed.body.id);
});

test('a declined charge is a 402, and the order is refused', async () => {
  await mode('decline');
  const placed = await order(BASE, bearer, { show_id: 'sh-102', seats: 1 });
  assert.equal(placed.status, 402);
  assert.equal(placed.body.detail, 'the payment was declined');
});
```

Three hooks keep its tests apart, and each is there for a reason the tests would otherwise show by
failing:

| hook | runs | why |
|---|---|---|
| `before` | once, before the first test | one token is enough for the whole file |
| `beforeEach` | before every test | each test starts with an empty record and the stub approving, whatever the test before it did |
| `after` | once, after the last test | the stub is left approving for whoever uses it next |

The first test is the one a screen could never run: **one charge, of 8000 cents, whose reference is
the order's id.** The second sets the stub to decline and checks boxoffice's side of it. A test that
switched the stub's mode and did not put it back would leave the next test, in this file or another,
running against a provider that declines everything.

## Running it

Start the stub in a terminal of its own, then restart boxoffice with `PAYMENTS_URL` set, as in lesson
11:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Then run the file; `grep` keeps the result lines and the summary:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/payments.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - an order is charged once, for its total
ok 2 - a declined charge is a 402, and the order is refused
# pass 2
# fail 0
# todo 0
```

The stub's terminal shows the conversation from the other side, in order:

```
ana@laptop:~/boxoffice$ node payments-stub.mjs
payments stub listening on http://localhost:8090, mode approve
DELETE /__requests 204 (approve)
PUT /__mode 200 (approve)
POST /charges 201 (approve)
GET /__requests 200 (approve)
DELETE /__requests 204 (approve)
PUT /__mode 200 (approve)
PUT /__mode 200 (decline)
POST /charges 201 (decline)
PUT /__mode 200 (approve)
```

Read it against the hooks: the `DELETE` and the `PUT` before each test, the charge, the read of the
record by the first test, and the `PUT` back to `approve` at the end. When an integration test fails
and its own message is not enough, **the logs of both services, side by side**, are where the answer
is.
