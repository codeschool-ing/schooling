---
title: Cleaning up, and when cleanup never runs
version: 1
---

**There are three places to clean up test data, and they fail in different ways.** At the end of
each test, a test deletes what it made. At the start, it puts the application in a known state
whatever the last run left. Or the whole environment is thrown away after the run and the next one
starts from nothing. The tempting belief is that the first is the careful one, because it tidies
up after itself. It is the one that breaks when a run ends badly, which is exactly when the
leftovers cause trouble.

## Deleting at the end

Playwright's `test.afterEach` runs after every test in the file, **whether the test passed or
failed**, so it is the natural place for a delete. The sign-up file keeps a list of the names it
made and deletes them. Save it as `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// Every name this file makes, so that afterEach can delete it again.
const created = [];
function newName(who) {
  const name = `${who}-${randomUUID().slice(0, 8)}`;
  created.push(name);
  return name;
}

// Runs after every test, passed or failed: tidy, not essential.
test.afterEach(async ({ request }) => {
  for (const name of created.splice(0)) {
    await request.delete('/api/users', { params: { name } });
  }
});

test('a new customer can sign up', async ({ page }) => {
  const name = newName('maria');
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
});

test('a name that is taken is refused', async ({ page, request }) => {
  const name = newName('joao');
  // The setup goes through the API: this test is about the refusal.
  const created = await request.post('/api/users', { data: { name } });
  expect(created.status()).toBe(201);

  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`${name} already exists`);
});
```

`params` builds the query string, encoding the name on the way. To watch the deletes happen, run
the shop with its request log in one terminal and the tests in another:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/signup.spec.js:19:1 › a new customer can sign up (212ms)
  ✓  2 tests/signup.spec.js:27:1 › a name that is taken is refused (269ms)

  2 passed (1.6s)
```

The shop's terminal, once you stop it:

```

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET /api/products 200
GET /api/products 200
GET /signup.html 200
GET /style.css 200
POST /api/users 201
DELETE /api/users?name=maria-cfcdad45 204
POST /api/users 201
GET /signup.html 200
GET /style.css 200
POST /api/users 409
DELETE /api/users?name=joao-b7629e9a 204
```

Each `DELETE` comes after its own test's requests and names the customer that test made: `maria-cfcdad45` after the sign-up, `joao-b7629e9a` after the refusal. The two `GET /api/products` at the top are Playwright checking that a shop already answers before it reuses it. The comment above
`afterEach` says *tidy, not essential*, and that is the important word in this file. **The tests
are already safe because the names are unique**; the delete only stops the shop filling with
customers nobody needs. A test whose correctness depended on that delete would be back in the
first section's trouble.

## When the end never comes

`afterEach` runs after a failure, and after an interruption Playwright can handle. It does not run
after an interruption it cannot. A file for the experiment only, with a fixed name on purpose, a
delete in `afterEach`, and a test that takes ten seconds. Save it as `tests/interrupted.spec.js`
and delete it when you have seen both runs:

```javascript
import { test, expect } from '@playwright/test';

test.afterEach(async ({ request }) => {
  await request.delete('/api/users', { params: { name: 'joao' } });
  console.log('afterEach: joao deleted');
});

test('a slow test that creates joao', async ({ page, request }) => {
  const created = await request.post('/api/users', { data: { name: 'joao' } });
  expect(created.status()).toBe(201);
  console.log('joao created');
  await page.goto('/signup.html');
  await page.waitForTimeout(10000);   // stands for ten seconds of real work
});
```

With the shop running in another terminal, start the test and press **Ctrl+C** a few seconds in.
Here `timeout -s INT 3` presses it after three seconds, then `curl` asks for *joao* again:

```
ana@laptop:~/quitanda$ timeout -s INT 3 npx playwright test tests/interrupted.spec.js

Running 1 test using 1 worker

joao created
afterEach: joao deleted
  ✘  1 tests/interrupted.spec.js:8:1 › a slow test that creates joao (966ms)


  1) tests/interrupted.spec.js:8:1 › a slow test that creates joao ─────────────────────────────────

    Test was interrupted.

    Error: page.waitForTimeout: Test ended.

      11 |   console.log('joao created');
      12 |   await page.goto('/signup.html');
    > 13 |   await page.waitForTimeout(10000);   // stands for ten seconds of real work
         |              ^
      14 | });
      15 |
        at /home/ana/quitanda/tests/interrupted.spec.js:13:14

  1 interrupted
    tests/interrupted.spec.js:8:1 › a slow test that creates joao ──────────────────────────────────
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"joao"}' http://localhost:3000/api/users
{"name":"joao"} 201
ana@laptop:~/quitanda$ curl -s -X DELETE 'http://localhost:3000/api/users?name=joao'
```

Playwright caught Ctrl+C, stopped the test, reported it *interrupted*, and still ran `afterEach`:
the name was free afterwards. Now the same run, ended by `SIGKILL`, the signal no program can
catch. It is what an out-of-memory killer sends, what a cancelled build job often amounts to, and
what a laptop lid closing on a dying battery is like from the test's point of view:

```
ana@laptop:~/quitanda$ timeout -s KILL 3 npx playwright test tests/interrupted.spec.js

Running 1 test using 1 worker

joao created
Killed
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"joao"}' http://localhost:3000/api/users
{"error":"joao already exists"} 409
```

**`joao created`, and nothing after it.** The runner and its workers were gone before `afterEach`
could start, and the shop kept the customer. The next run of that test fails at its first line
with `409`, and goes on failing until somebody deletes *joao* by hand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Run 1 creates joao and is killed by SIGKILL, so its afterEach never runs and the shop keeps joao. A second run that relies on deleting at the end asks for joao again and fails with 409 at its first line. A second run that resets at the start empties the shop first, then creates joao and passes.\"><text x=\"20\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">run 1</text><text x=\"20\" y=\"112\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the shop</text><text x=\"20\" y=\"172\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">run 2</text><text x=\"20\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">delete at the end</text><text x=\"20\" y=\"242\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">run 2</text><text x=\"20\" y=\"258\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reset at the start</text><rect x=\"200\" y=\"32\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"275\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">creates joao</text><path d=\"M372 36 L392 58 M392 36 L372 58\" stroke=\"var(--amber)\" stroke-width=\"3\"></path><text x=\"382\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">SIGKILL</text><rect x=\"414\" y=\"32\" width=\"190\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"509\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">afterEach: never runs</text><rect x=\"275\" y=\"100\" width=\"425\" height=\"18\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"487\" y=\"113\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">joao is still there</text><path d=\"M275 62 L275 98\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><rect x=\"200\" y=\"160\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"275\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">creates joao</text><path d=\"M350 175 L398 175\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"400\" y=\"160\" width=\"200\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"500\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">409: fails at line 1</text><rect x=\"200\" y=\"230\" width=\"100\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"></rect><text x=\"250\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reset</text><path d=\"M300 245 L318 245\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"320\" y=\"230\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"395\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">creates joao</text><path d=\"M470 245 L488 245\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"490\" y=\"230\" width=\"200\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"590\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">201: passes</text><path d=\"M250 230 L250 120\" stroke=\"var(--phosphor)\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "The same killed run, followed by two kinds of next run. Only the one that resets first is untouched by what the dead run left."}
```

## Resetting at the start

The other place to clean is before the test, and the shop has the tool for it: `POST /api/reset`
puts the products, the basket, the offer and the customers back as they started. A reset at the
start **does not care how the last run ended**. A killed run, a test that forgot its delete, a
person who added a mango by hand: all of it is gone before the test looks.

The basket is where that matters, because a basket cannot be made unique. Two tests that each
expect to start from an empty one. Save it as `tests/basket-data.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

const add = (page, id) =>
  page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

test('a banana costs R$ 5,90', async ({ page }) => {
  await page.goto('/');
  await add(page, 'banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});

test('two mangoes cost R$ 9,00', async ({ page }) => {
  await page.goto('/');
  await add(page, 'mango');
  await add(page, 'mango');
  await expect(page.getByTestId('basket-count')).toHaveText('2');
  await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
});
```

The ` ` is the non-breaking space lesson 1 warned about. One worker, the default for one
file, so the two tests run one after the other:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/basket-data.spec.js:6:1 › a banana costs R$ 5,90 (212ms)
  ✘  2 tests/basket-data.spec.js:13:1 › two mangoes cost R$ 9,00 (5.2s)


  1) tests/basket-data.spec.js:13:1 › two mangoes cost R$ 9,00 ─────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.basket-total')
    Expected: "R$ 9,00"
    Received: "R$ 14,90"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for locator('.basket-total')
        - locator resolved to <span class="basket-total">R$ 10,40</span>
        - unexpected value "R$ 10,40"
        8 × locator resolved to <span class="basket-total">R$ 14,90</span>
          - unexpected value "R$ 14,90"


      16 |   await add(page, 'mango');
      17 |   await expect(page.getByTestId('basket-count')).toHaveText('2');
    > 18 |   await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
         |                                               ^
      19 | });
      20 |
        at /home/ana/quitanda/tests/basket-data.spec.js:18:47

    Error Context: test-results/basket-data-two-mangoes-cost-R-9-00/error-context.md

  1 failed
    tests/basket-data.spec.js:13:1 › two mangoes cost R$ 9,00 ──────────────────────────────────────
  1 passed (7.0s)
```

**The second test found the first test's banana**: R$ 14,90 is one banana and two mangoes. Neither
test is wrong on its own, and the second passes when run alone. A reset at the start of each test
fixes it. Save it as `tests/basket-data.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

const add = (page, id) =>
  page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

// Every test starts from an empty basket.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana costs R$ 5,90', async ({ page }) => {
  await page.goto('/');
  await add(page, 'banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});

test('two mangoes cost R$ 9,00', async ({ page }) => {
  await page.goto('/');
  await add(page, 'mango');
  await add(page, 'mango');
  await expect(page.getByTestId('basket-count')).toHaveText('2');
  await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/basket-data.spec.js:11:1 › a banana costs R$ 5,90 (266ms)
  ✓  2 tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 (330ms)

  2 passed (2.1s)
```

The reset has a price, and it is in the shop's code: `reset()` empties **everything**, the
customers included. It is a blunt tool for one shop on one laptop, and a dangerous one anywhere
else. On a shared test environment, a reset at the start of your test deletes the data of every
other person and suite using it; most real applications have no such endpoint, and the ones that
do refuse it outside test environments.

## Throwing the environment away

The third place is outside the tests: give each run an environment of its own and discard it
afterwards. You have used it all lesson without naming it. With no shop running, Playwright's
`webServer` starts a fresh one, in memory, for each run, which is why the fixed name passed twice
in the first section. On a build server, where `CI` is set, it always does. For an application with
a database the same idea is a container started for the run and removed after it; running a suite
on a build server is `testing-cicd` lesson 5.

| where | survives a killed run? | cost |
|---|---|---|
| delete at the end (`afterEach`) | **no** | needs to know what the test made |
| reset at the start (`beforeEach`) | yes | wipes everybody's data, and needs an endpoint the application may not have |
| throwaway environment | yes | an environment per run, and minutes to start one |

The arrangement that holds up uses them together: **unique data so tests cannot collide, a delete
at the end to stay tidy, and a fresh environment wherever one can be had.** The reset belongs to
the data that cannot be made unique, and the next section shows where even that stops working.
