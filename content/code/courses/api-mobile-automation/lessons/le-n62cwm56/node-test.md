---
title: Tests in plain Node, with node:test
version: 1
---

**Node 22 carries its own test runner and its own assertions, so an API test needs nothing
installed.** `node:test` finds test files, runs them and reports. `node:assert` compares what came
back with what was expected. `fetch`, built into Node since version 18, sends the requests. Jest,
Mocha and Vitest are popular frameworks, and they add watch modes, module mocks and snapshot files.
A test that talks to a server over HTTP uses none of those. So this lesson and the next use what
Node already has, and every line of the tests is visible in the lesson.

## Shared helpers

Every test file needs a token and needs to place orders, so those live in one module. Make the
directory with `mkdir ~/boxoffice/tests` and save it as `tests/lib.mjs`:

```js
// tests/lib.mjs: what the test files share. Run the tests from ~/boxoffice.
export const BASE = process.env.BASE_URL || 'http://localhost:8080';
export const STUB = process.env.STUB_URL || 'http://localhost:8090';

// A token for the ci-tests client, from the boxoffice at `base`.
export async function token(base = BASE) {
  const res = await fetch(`${base}/oauth/token`, {
    method: 'POST',
    body: new URLSearchParams({ grant_type: 'client_credentials', client_id: 'ci-tests', client_secret: 'ci-secret' }),
  });
  if (res.status !== 200) throw new Error(`no token from ${base}: ${res.status}`);
  return (await res.json()).access_token;
}

// POST an order and return its status, headers and body.
export async function order(base, bearer, body, headers = {}) {
  const res = await fetch(`${base}/v1/orders`, {
    method: 'POST',
    headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  return { status: res.status, headers: res.headers, body: await res.json() };
}

// GET a URL and return its status and JSON body.
export async function get(url) {
  const res = await fetch(url);
  return { status: res.status, body: await res.json() };
}
```

`BASE` and `STUB` say where the servers are. An environment variable can move them, so the same
tests can run against another machine. `token`, `order` and `get` each hide one request and hand back
what a test asserts on: a status, a body, sometimes headers. **`token` throws when it gets no
token.** A test that went on with `undefined` as its bearer would fail three lines later, with a 401
that points at the wrong place.

## A first test file

Save it as `tests/shows.test.mjs`:

```js
// tests/shows.test.mjs: the shows, read from the boxoffice at BASE.
import test from 'node:test';
import assert from 'node:assert/strict';
import { BASE, get } from './lib.mjs';

test('the list holds the three shows', async () => {
  const { status, body } = await get(`${BASE}/v1/shows`);
  assert.equal(status, 200);
  assert.deepEqual(body.shows.map((s) => s.id), ['sh-101', 'sh-102', 'sh-103']);
});

test('a show has its price in cents', async () => {
  const { body } = await get(`${BASE}/v1/shows/sh-103`);
  assert.equal(body.price_cents, 6500);
  assert.ok(Number.isInteger(body.seats_left));
});

test('an unknown show is a 404 in problem details', async () => {
  const res = await fetch(`${BASE}/v1/shows/sh-999`);
  assert.equal(res.status, 404);
  assert.equal(res.headers.get('content-type'), 'application/problem+json');
});

test('HEAD answers like GET, without a body', async () => {
  const res = await fetch(`${BASE}/v1/shows/sh-103`, { method: 'HEAD' });
  assert.equal(res.status, 200);
});
```

Each `test` has a name, written as a sentence about boxoffice, and an `async` function. The test
passes if the function finishes and fails if it throws, and `assert` throws when a comparison does
not hold. `assert/strict` is the variant to use: its `equal` compares with `===`, so `'6500'` is not
`6500`. The last test is lesson 1's defect, written down as a test.

## Running it

boxoffice has to be running, as in every earlier lesson:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

`node --test` runs the files you name, each in a process of its own. **On a terminal its default
report draws a tick or a cross beside each test.** This course asks for the `tap` reporter instead.
It writes the same results as plain text in the Test Anything Protocol, a format Perl made up in the
1980s and test tools have written ever since. CI systems read it:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/shows.test.mjs
TAP version 13
# Subtest: the list holds the three shows
ok 1 - the list holds the three shows
  ---
  duration_ms: 50.71813
  type: 'test'
  ...
# Subtest: a show has its price in cents
ok 2 - a show has its price in cents
  ---
  duration_ms: 5.27458
  type: 'test'
  ...
# Subtest: an unknown show is a 404 in problem details
ok 3 - an unknown show is a 404 in problem details
  ---
  duration_ms: 3.52822
  type: 'test'
  ...
# Subtest: HEAD answers like GET, without a body
not ok 4 - HEAD answers like GET, without a body
  ---
  duration_ms: 4.604792
  type: 'test'
  location: '/home/ana/boxoffice/tests/shows.test.mjs:24:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    
    405 !== 200
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 200
  actual: 405
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/boxoffice/tests/shows.test.mjs:26:10)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async Test.run (node:internal/test_runner/test:1054:7)
    async Test.processPendingSubtests (node:internal/test_runner/test:744:7)
  ...
1..4
# tests 4
# suites 0
# pass 3
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 193.479738
ana@laptop:~/boxoffice$ echo $?
1
```

Read it from the bottom. The summary says four tests, three passed, one failed. **The exit code is
1**, and that is what a pipeline reads to go red. Above it, each test has a line, `ok` or `not ok`.
The failure carries what a defect report needs: the comparison that failed (`405 !== 200`), the
`expected` and `actual` values, and the `location` of the test as file, line and column. The stack
trace below it is Node's own; its first line is the test's.

## A known defect, kept in sight

The HEAD test fails because boxoffice is wrong, and it will keep failing until somebody fixes
boxoffice. Leaving it red trains everybody to ignore a red run; deleting it loses the defect. Node's
answer is the `todo` option. The test still runs and its result is still reported, but a failing
todo does not fail the run. Change the HEAD test's first line to this:

```js
test('HEAD answers like GET, without a body', { todo: 'boxoffice answers HEAD with 405, lesson 1' }, async () => {
```

This time the report goes to a file, `shows.tap`, and `grep` picks out the lines worth reading:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap tests/shows.test.mjs > shows.tap
ana@laptop:~/boxoffice$ echo $?
0
ana@laptop:~/boxoffice$ grep -E '^(not )?ok|^# (pass|fail|todo)' shows.tap
ok 1 - the list holds the three shows
ok 2 - a show has its price in cents
ok 3 - an unknown show is a 404 in problem details
not ok 4 - HEAD answers like GET, without a body # TODO boxoffice answers HEAD with 405, lesson 1
# pass 3
# fail 0
# todo 1
```

**Exit code 0, and the defect is still in the report**, marked `# TODO` with the reason written
beside it. The day HEAD is fixed, that line turns to `ok … # TODO`. That is the signal to take the
option away.
