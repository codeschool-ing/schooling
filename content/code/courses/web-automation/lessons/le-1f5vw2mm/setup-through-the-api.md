---
title: Setting up through the API
version: 1
---

**A test has a subject and a setup, and only the subject has to go through the screen.** The
sign-up test's subject is the form: typing a name, pressing the button, reading the greeting. Now
take a second test, one that checks the form refuses a name that is taken. Its subject is the
refusal. Its setup is a customer who already exists, and nothing about how that customer came to
exist is being tested.

The habit many testers bring from manual testing is to build the setup the way a person would:
open the form, sign up the first customer, then sign up the second with the same name. It works,
and it costs twice. **It is slower**, because every step of a setup through the screen loads a
page, finds elements and waits for them. **And it fails for the wrong reason**: if the form
breaks, every test that signs somebody up as a step on the way to something else turns red, and
the report has fifty failures for one defect, most of them in tests whose subject is fine.

## How much slower, measured

Playwright's `request` fixture, met in lessons 10 and 11 where it called `POST /api/reset`, sends
HTTP requests with no page at all. It takes `baseURL` from the configuration, and `data` is sent as
JSON. A file that creates ten customers each way and prints how long it took. Save it as
`tests/setup-cost.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

const fresh = () => `cost-${randomUUID().slice(0, 8)}`;

test('ten customers through the form', async ({ page }) => {
  const started = performance.now();
  for (let i = 0; i < 10; i += 1) {
    const name = fresh();
    await page.goto('/signup.html');
    await page.getByLabel('Name').fill(name);
    await page.getByRole('button', { name: 'Create account' }).click();
    await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
  }
  console.log(`form: ${Math.round(performance.now() - started)} ms for 10`);
});

test('ten customers through the API', async ({ request }) => {
  const started = performance.now();
  for (let i = 0; i < 10; i += 1) {
    const response = await request.post('/api/users', { data: { name: fresh() } });
    expect(response.status()).toBe(201);
  }
  console.log(`API: ${Math.round(performance.now() - started)} ms for 10`);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/setup-cost.spec.js

Running 2 tests using 1 worker

form: 1492 ms for 10
  ✓  1 tests/setup-cost.spec.js:6:1 › ten customers through the form (1.6s)
API: 57 ms for 10
  ✓  2 tests/setup-cost.spec.js:18:1 › ten customers through the API (65ms)

  2 passed (2.9s)
```

Ten customers took 1492 ms through the form and 57 ms through the API: about 26 times as long, nearly all of it pages loading and a browser waiting for them. **And this is the most favourable case for the form** that you will ever measure: one
field, one button, a page with no images, a server in memory on the same machine. A real sign-up
has more fields, a confirmation and a slower server, and the gap grows with each of them. The time
the test runner prints beside each test includes starting its context, which is why it is a little
above the figure the test printed.

## The second test, with its setup through the API

The refusal test creates its customer with one request, checks the request worked, and only then
opens the page. Save it as `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// A name no other test and no earlier run has used: readable at the
// front, random at the back.
const newName = (who) => `${who}-${randomUUID().slice(0, 8)}`;

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

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/signup.spec.js:8:1 › a new customer can sign up (226ms)
  ✓  2 tests/signup.spec.js:16:1 › a name that is taken is refused (184ms)

  2 passed (1.9s)
```

**Check the setup's answer.** The line `expect(created.status()).toBe(201)` looks fussy and is the
most useful line in the test. Without it, a setup that failed, a `400` for a bad body or a `404`
because the route moved, lets the test carry on and fail later at the greeting, with a message
about the form when the form is fine. With it, the failure names the step that broke.

## Where this stops being right

Setting up through the API is right when the setup is **not the subject**. It is wrong in two
places:

- **the test of the form itself.** The sign-up test above still types into the page, because the
  page is what it tests. One test, or a few, should create a customer the way a customer does;
- **an API that does not do what the screen does.** If the form also sent a welcome e-mail or
  filled in defaults that the endpoint skips, a customer made through the API is a different
  customer. Before trusting a shortcut, compare what each path leaves behind.

The same idea scales up. A test that needs a customer *with an order history* can be given one by
a few requests, or by a database seed, instead of ten minutes of clicking. The layers below the
screen, and how much of a suite belongs on each, are lesson 21's subject; testing an API for its
own sake is the next course, `api-mobile-automation`.
