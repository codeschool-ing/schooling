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
%%CAP signup-v4%%
```

The shop's terminal, once you stop it:

```
%%CAP signup-v4-log%%
```

Each `DELETE` follows its own test's requests, with the name the test made. The comment above
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
%%CAP interrupted-file%%
```

With the shop running in another terminal, start the test and press **Ctrl+C** a few seconds in.
Here `timeout -s INT 3` presses it after three seconds, then `curl` asks for *joao* again:

```
%%CAP interrupted-int%%
```

Playwright caught Ctrl+C, stopped the test, reported it *interrupted*, and still ran `afterEach`:
the name was free afterwards. Now the same run, ended by `SIGKILL`, the signal no program can
catch. It is what an out-of-memory killer sends, what a cancelled build job often amounts to, and
what a laptop lid closing on a dying battery is like from the test's point of view:

```
%%CAP interrupted-kill%%
```

**`joao created`, and nothing after it.** The runner and its workers were gone before `afterEach`
could start, and the shop kept the customer. The next run of that test fails at its first line
with `409`, and goes on failing until somebody deletes *joao* by hand.

@@FIGURE@@

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
%%CAP basket-v1%%
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
%%CAP basket-v2%%
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
