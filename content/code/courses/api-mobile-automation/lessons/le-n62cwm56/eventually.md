---
title: Results that arrive later
version: 1
---

**Some answers are right only after a while, and a test has to wait for them without guessing how
long.** boxoffice's sales report is one. It is rebuilt in the background, `REPORT_DELAY` milliseconds
after an order changes, 500 unless the variable says otherwise, which is how many real systems
behave: a search index, a cache, a dashboard fed by a queue. The name for it is *eventual
consistency*: the report will agree with the orders, just not at the instant they change.

## Seeing the lag

Restart boxoffice so the report starts from zero, get a token, then place an order and ask for the
report on the same line, so the second request follows the first at once:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":3}'; curl -s localhost:8080/v1/reports/sales -H 'x-api-key: lab-only-staff-key'
201
{"orders":0,"seats":0,"revenue_cents":0}
ana@laptop:~/boxoffice$ sleep 1; curl -s localhost:8080/v1/reports/sales -H 'x-api-key: lab-only-staff-key'
{"orders":1,"seats":3,"revenue_cents":24000}
```

The order was created and the report still said nothing had been sold. A second later it had caught
up. **A test that reads the report straight after the order fails, though nothing is wrong** with
boxoffice; it is the test that misread the promise.

## Two wrong fixes

The first one everybody writes is a sleep: wait a second, then read. It fails twice over. It is slow
on every run, a full second where half of one would do, multiplied by every test that does it. And it
still fails on the day the machine is busy and the rebuild takes longer than the second, so the suite
goes red at random on a loaded CI runner, which is the worst kind of red.

The second is to stop checking: drop the assertion about the report because it "flakes". That turns
a real promise of boxoffice's into something no test holds.

## Asking again, until a deadline

The right shape is to ask, and if the answer is not yet right, wait a little and ask again, up to a
deadline; then fail with what was still wrong. Write that as a helper, and save it as `tests/eventually.mjs`:

```js
// tests/eventually.mjs: wait for something that becomes true later.

// Run check() until it stops throwing, every `every` ms, for at most
// `timeout` ms. Then throw the last error, so a failure still says what was
// wrong, and not only that time ran out.
export async function eventually(check, { timeout = 3000, every = 100 } = {}) {
  const deadline = Date.now() + timeout;
  for (;;) {
    try {
      return await check();
    } catch (err) {
      if (Date.now() + every > deadline) throw err;
      await new Promise((wake) => setTimeout(wake, every));
    }
  }
}
```

Three choices in it are deliberate. **It returns as soon as the check passes**, so a fast machine
waits 500 ms and not a fixed second. Its deadline, three seconds by default, is generous, because it
only costs time when something is broken. And **it throws the last real error**, not "timed out", so a
failure says which field was wrong and what it held.

The test uses it around the assertion that needs time. It starts its own boxoffice, as section 04
taught, so no other test's orders reach its report. Save it as `tests/report.test.mjs`:

```js
// tests/report.test.mjs: the sales report catches up with the orders.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order } from './lib.mjs';
import { start } from './start.mjs';
import { eventually } from './eventually.mjs';

const BASE = 'http://localhost:8183';
const report = async () => (await fetch(`${BASE}/v1/reports/sales`,
  { headers: { 'x-api-key': 'lab-only-staff-key' } })).json();
let stop, bearer;

before(async () => {
  stop = await start('boxoffice.mjs', { PORT: '8183' });
  bearer = await token(BASE);
});
after(() => stop());

test('an order shows up in the sales report', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-101', seats: 3 });
  assert.equal(placed.status, 201);
  await eventually(async () => {
    assert.deepEqual(await report(), { orders: 1, seats: 3, revenue_cents: 24000 });
  });
});
```

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/report.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - an order shows up in the sales report
# pass 1
# fail 0
# todo 0
```

It passed. Now make the rebuild slower than the deadline. The
spawned boxoffice inherits the test's environment, so `REPORT_DELAY` on the command line reaches it:

```
ana@laptop:~/boxoffice$ REPORT_DELAY=5000 node --test --test-reporter=tap tests/report.test.mjs > slow.tap
ana@laptop:~/boxoffice$ echo $?
1
ana@laptop:~/boxoffice$ head -30 slow.tap
TAP version 13
# Subtest: an order shows up in the sales report
not ok 1 - an order shows up in the sales report
  ---
  duration_ms: 3132.656154
  type: 'test'
  location: '/home/ana/boxoffice/tests/report.test.mjs:19:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly deep-equal:
    + actual - expected
    
      {
    +   orders: 0,
    +   revenue_cents: 0,
    +   seats: 0
    -   orders: 1,
    -   revenue_cents: 24000,
    -   seats: 3
      }
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected:
    orders: 1
    seats: 3
    revenue_cents: 24000
  actual:
    orders: 0
    seats: 0
```

**The failure is the one you want to read**: exit code 1, the report still held zeros when three
seconds ran out, and the diff shows the fields that were expected. A test that slept would have said the same thing
with no deadline to blame, and a test that waited forever would have said nothing at all.
