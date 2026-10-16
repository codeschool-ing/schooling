---
title: The test that passes once
version: 1
---

**A test is a program that changes the application it checks.** Every test that signs somebody up,
adds to a basket or places an order leaves something behind, and the next test, or the next run of
the same test, starts from whatever was left. Most of what goes wrong with test data is a test that
assumed it was alone, or assumed it was first. This section builds the smallest case of it.

## Customers, at last

The shop gets accounts: a name, and nothing else. `POST /api/users` with a name creates one and
answers `201`; a name that already exists is refused with `409 Conflict` and a sentence saying so;
`DELETE /api/users?name=…` removes one and answers `204`, whether it existed or not. Like the
basket, the customers live in memory, in the `users` set of `app/store.js`, and
`POST /api/reset` empties it along with the basket and the offer. Save it as
`app/routes/users.js`:

```javascript
import { send } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'POST', path: '/api/users',
    handle: ({ res, body }) => {
      const name = String(body.name ?? '').trim();
      if (!name) return send(res, 400, { error: 'a name is required' });
      if (store.users.has(name)) return send(res, 409, { error: `${name} already exists` });
      store.users.add(name);
      send(res, 201, { name });
    },
  },
  {
    method: 'DELETE', path: '/api/users',
    handle: ({ res, url }) => {
      store.users.delete(url.searchParams.get('name'));
      res.writeHead(204);
      res.end();
    },
  },
];
```

The page has a form with one field, and writes the server's answer into a paragraph marked
`role="status"`: *Welcome, maria* or *maria already exists*. Save it as
`app/public/signup.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up · Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Sign up</h1>
    <form>
      <label for="name">Name</label>
      <input id="name" name="name" required>
      <button type="submit">Create account</button>
    </form>
    <p role="status"></p>
  </main>
  <script>
    document.querySelector('form').addEventListener('submit', async (event) => {
      event.preventDefault();
      const name = document.querySelector('#name').value;
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name }),
      });
      const answer = await response.json();
      document.querySelector('[role=status]').textContent =
        response.ok ? `Welcome, ${answer.name}` : answer.error;
    });
  </script>
</body>
</html>
```

Restart the shop, because the server reads `app/routes/` when it starts, and ask it twice for the
same customer from a second terminal. The number at the end of each line is the status code, which
`-w` asks `curl` to print:

```
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"maria"}' http://localhost:3000/api/users
{"name":"maria"} 201
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"maria"}' http://localhost:3000/api/users
{"error":"maria already exists"} 409
ana@laptop:~/quitanda$ curl -s -w '%{http_code}\n' -X DELETE 'http://localhost:3000/api/users?name=maria'
204
ana@laptop:~/quitanda$ curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"name":"maria"}' http://localhost:3000/api/users
{"name":"maria"} 201
```

The second request is refused, the `DELETE` answers `204` with no body, and after it the name is
free again. **That `409` is correct behaviour.** Two customers with the same name would be a
defect, and the shop is right to refuse.

## The obvious test

A tester writing the first test for the page picks a name, types it, presses the button and checks
the greeting. Save it as `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a new customer can sign up', async ({ page }) => {
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill('maria');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText('Welcome, maria');
});
```

Stop any shop you have running and run it twice:

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:3:1 › a new customer can sign up (205ms)

  1 passed (1.7s)
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:3:1 › a new customer can sign up (217ms)

  1 passed (1.5s)
```

**Green twice, and the reason is not the test.** Lesson 1's configuration has a `webServer` block:
with no shop on port 3000, Playwright starts one before the tests and stops it after. Each run had
a shop of its own, born empty, so each run's Maria was the first.

## The same test against a shop that stays up

The same block says `reuseExistingServer: !process.env.CI`. On your machine `CI` is not set, so
when something already answers on port 3000, Playwright uses it instead of starting its own.
Lesson 1 had you leave `npm start` running in a second terminal to look at the shop by hand, and
that is exactly the situation. With the shop running there, the same two runs:

```
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✓  1 tests/signup.spec.js:3:1 › a new customer can sign up (236ms)

  1 passed (1.2s)
ana@laptop:~/quitanda$ npx playwright test tests/signup.spec.js

Running 1 test using 1 worker

  ✘  1 tests/signup.spec.js:3:1 › a new customer can sign up (5.2s)


  1) tests/signup.spec.js:3:1 › a new customer can sign up ─────────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  getByRole('status')
    Expected: "Welcome, maria"
    Received: "maria already exists"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for getByRole('status')
        9 × locator resolved to <p role="status">maria already exists</p>
          - unexpected value "maria already exists"


      5 |   await page.getByLabel('Name').fill('maria');
      6 |   await page.getByRole('button', { name: 'Create account' }).click();
    > 7 |   await expect(page.getByRole('status')).toHaveText('Welcome, maria');
        |                                          ^
      8 | });
      9 |
        at /home/ana/quitanda/tests/signup.spec.js:7:42

    Error Context: test-results/signup-a-new-customer-can-sign-up/error-context.md

  1 failed
    tests/signup.spec.js:3:1 › a new customer can sign up ──────────────────────────────────────────
```

The first run created Maria in the shop that stays up. The second asked for her again and got the
answer the shop should give: *maria already exists*. **The application is right and the test is
wrong**, and the error message puts the blame on neither; a tester reading *Expected "Welcome,
maria", Received "maria already exists"* in a nightly report can lose an hour deciding whether
sign-up broke.

Three properties of this failure are worth naming, because every data problem in this lesson has
some of them:

- **it depends on history.** The test has no defect you can see by reading it. It fails because of
  a run that happened earlier, possibly somebody else's;
- **it depends on the environment.** The same file is green with a fresh shop and red with a
  reused one. On a build server, where `CI` is set, a fresh shop starts every time and it would
  pass for months. It would fail on the first day somebody pointed the suite at a shared test
  environment whose database is never emptied;
- **retrying does not help.** Maria is still there on the third run. Lesson 14 calls a test that
  fails *sometimes* flaky; this one fails every time once the conditions are met, which makes it
  easier to diagnose and just as easy to misread.

A shared test environment, the kind `manual-testing` lesson 21 describes, is the reused shop at a
larger scale: a database that lives for months, written to by every test run and every person
testing by hand. A test that needs the name *maria* to be free there is a test that passes once.
