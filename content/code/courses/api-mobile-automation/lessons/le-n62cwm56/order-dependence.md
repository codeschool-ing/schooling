---
title: Tests that depend on their order
version: 1
---

**A test that passes alone and fails beside another test has a hidden input: what ran before it.**
The usual belief is that a failure like that is bad luck, a "flaky" test to re-run until it goes
green. It is not luck. Two tests share some state, here the seats of a show, and the result depends on
who touched it first. Re-running hides the cause and keeps it.

## Two tests that share four seats

sh-103 has four seats, which makes it easy to show.
The first test buys two of them; save it as `tests/seats.test.mjs`:

```js
// tests/seats.test.mjs: buying seats takes them off the show.
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, token, order, get } from './lib.mjs';

let bearer;
before(async () => { bearer = await token(); });

test('two seats of sh-103 leave two', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 2 });
  assert.equal(placed.status, 201);
  const { body } = await get(`${BASE}/v1/shows/sh-103`);
  assert.equal(body.seats_left, 2);
});
```

The second buys all four; save it as `tests/sellout.test.mjs`:

```js
// tests/sellout.test.mjs: a show with no seats left refuses the next order.
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, token, order } from './lib.mjs';

let bearer;
before(async () => { bearer = await token(); });

test('sh-103 sells out at four seats', async () => {
  const all = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  assert.equal(all.status, 201);
  const one = await order(BASE, bearer, { show_id: 'sh-103', seats: 1 });
  assert.equal(one.status, 409);
  assert.equal(one.body.detail, 'only 0 seats left');
});
```

Both use the boxoffice on `BASE`, the one running in your other terminal, and both are correct about
a boxoffice that has just started. Restart boxoffice with Ctrl-C and the same command, so it holds a
fresh sh-103, and run the second one:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - sh-103 sells out at four seats
# pass 1
# fail 0
# todo 0
```

Restart boxoffice again and run the first:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
# pass 1
# fail 0
# todo 0
```

Both pass alone. **Now run the first one a second time, without restarting:**

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs
TAP version 13
# Subtest: two seats of sh-103 leave two
not ok 1 - two seats of sh-103 leave two
  ---
  duration_ms: 26.370324
  type: 'test'
  location: '/home/ana/boxoffice/tests/seats.test.mjs:9:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    
    0 !== 2
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 2
  actual: 0
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/boxoffice/tests/seats.test.mjs:13:10)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async Test.run (node:internal/test_runner/test:1054:7)
    async startSubtestAfterBootstrap (node:internal/test_runner/harness:296:3)
  ...
1..1
# tests 1
# suites 0
# pass 0
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 201.28103
```

`0 !== 2`: the first run sold two seats, the second sold the other two, and the test expected two to
be left, because it was written as if it were the only thing that had ever happened to sh-103.
Restart boxoffice once more and run both, one file at a time with `--test-concurrency=1`:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap --test-concurrency=1 tests/seats.test.mjs tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
not ok 2 - sh-103 sells out at four seats
# pass 1
# fail 1
# todo 0
```

The seats test passed and the sellout test failed: it asked for four seats, and two of them were
already sold. Swap the two names on the command line and nothing changes:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap --test-concurrency=1 tests/sellout.test.mjs tests/seats.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
not ok 2 - sh-103 sells out at four seats
# pass 1
# fail 1
# todo 0
```

**node sorts the files it is given**, so `seats` runs before `sellout` either way. That is useful to
know and no help: the order is still an accident of the names, and renaming a file would move the
failure. Without `--test-concurrency=1`, Node runs files in parallel, one process each, and which
request reaches sh-103 first becomes a race between processes. The same two files can then pass on
your machine and fail on a slower one.

## The fix: state that belongs to the test

Two remedies exist, and which one fits depends on what is shared:

| remedy | how | here |
|---|---|---|
| **unique data per test** | each test creates what it needs, with a name nobody else uses: its own customer, its own product | not available: boxoffice has three shows and no way to add one |
| **fresh state per suite** | each test file gets a system of its own, started clean and thrown away | boxoffice starts in a fraction of a second and forgets everything when it stops |

So each file gets a boxoffice of its own, on a port of its own. Node's `child_process` starts it, and
a helper waits for the line that says it is listening. Save it as `tests/start.mjs`:

```js
// tests/start.mjs: a server of the test's own, started and stopped by it.
import { spawn } from 'node:child_process';

// Start `node file` with extra environment variables, and resolve once it
// prints "listening". The value is a function that stops it.
export function start(file, env = {}) {
  const child = spawn(process.execPath, [file], {
    env: { ...process.env, ...env },
    stdio: ['ignore', 'pipe', 'inherit'],
  });
  return new Promise((resolve, reject) => {
    let said = '';
    child.stdout.on('data', (chunk) => {
      said += chunk;
      if (said.includes('listening')) resolve(() => new Promise((done) => {
        child.once('exit', done);
        child.kill();
      }));
    });
    child.once('exit', (code) => reject(new Error(`${file} exited (${code}) before it was listening`)));
  });
}
```

**It rejects if the program exits before it listens**, so a server that could not start, because the
port was taken, say, fails the test file in `before` with the reason, instead of letting every test
time out against nothing. Now the fixed first test; save it as `tests/seats.test.mjs`:

```js
// tests/seats.test.mjs: buying seats takes them off the show.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order, get } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8181';
let stop, bearer;

before(async () => {
  stop = await start('boxoffice.mjs', { PORT: '8181' });
  bearer = await token(BASE);
});
after(() => stop());

test('two seats of sh-103 leave two', async () => {
  const placed = await order(BASE, bearer, { show_id: 'sh-103', seats: 2 });
  assert.equal(placed.status, 201);
  const { body } = await get(`${BASE}/v1/shows/sh-103`);
  assert.equal(body.seats_left, 2);
});
```

and the fixed second; save it as `tests/sellout.test.mjs`:

```js
// tests/sellout.test.mjs: a show with no seats left refuses the next order.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { token, order } from './lib.mjs';
import { start } from './start.mjs';

const BASE = 'http://localhost:8182';
let stop, bearer;

before(async () => {
  stop = await start('boxoffice.mjs', { PORT: '8182' });
  bearer = await token(BASE);
});
after(() => stop());

test('sh-103 sells out at four seats', async () => {
  const all = await order(BASE, bearer, { show_id: 'sh-103', seats: 4 });
  assert.equal(all.status, 201);
  const one = await order(BASE, bearer, { show_id: 'sh-103', seats: 1 });
  assert.equal(one.status, 409);
  assert.equal(one.body.detail, 'only 0 seats left');
});
```

Each starts its own boxoffice in `before`, on 8181 and 8182, and stops it in `after`. Run them
together, in parallel this time, and twice:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
ok 2 - sh-103 sells out at four seats
# pass 2
# fail 0
# todo 0
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/seats.test.mjs tests/sellout.test.mjs | grep -E '^(not )?ok|^# (pass|fail|todo)'
ok 1 - two seats of sh-103 leave two
ok 2 - sh-103 sells out at four seats
# pass 2
# fail 0
# todo 0
```

**Same answer in any order, any number of times**, because neither test can see what the other did.
The cost is one server started per file, a fraction of a second here, which is cheap next to an
afternoon spent on a test that fails one run in five.
