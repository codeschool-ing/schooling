---
title: Attaching what the browser said
version: 1
---

Lesson 1 ended with a page whose list stayed empty while the Console said why: a `404` for the
product list, and the script throwing as it read `not found` as JSON. A test that checks only what
it can see reports *the list is empty* and stops. **The reason was printed by the browser, during
the run, and nobody was listening.** This section makes the test listen and puts what it heard in
the report, next to the failure.

## Listening, and attaching

Playwright gives a page two events for this, the same two `look.mjs` used in lesson 1. `console`
fires for every message the page writes or the browser writes about it, and `pageerror` fires for
every error the page's scripts threw and nobody caught. Collecting them takes two lines in a
`beforeEach`.

Putting them in the report is `testInfo.attach`. Every test and hook receives a `testInfo` object
as the argument after the fixtures, and `attach` adds a named item to that test's result: a `body`
built in memory, or a `path` to a file already on disk, with a `contentType` saying what it is. The
`list` reporter prints a text attachment in the terminal, and the HTML report shows it on the
test's page, beside the screenshot and the trace.

The test below needs the page to fail, and the shop's product list works. So the test makes it
fail: `page.route` catches the request for `/api/products` before it leaves the browser and
answers it with `404` and the text `not found`, as a broken server would. That stand-in for the
server lives in the test, and the shop's own code is untouched. Save it as
`evidence/errors.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

let messages = [];

// Before each test: listen to the page, as look.mjs did in lesson 1.
test.beforeEach(async ({ page }) => {
  messages = [];
  page.on('console', (m) => messages.push(`console.${m.type()}: ${m.text()}`));
  page.on('pageerror', (e) => messages.push(`pageerror: ${e.message}`));
});

// After each test, passed or failed: put what was heard into the report.
test.afterEach(async ({}, testInfo) => {
  await testInfo.attach('browser messages', {
    body: messages.join('\n') || '(none)',
    contentType: 'text/plain',
  });
});

// Fails on purpose: the product list is answered with a 404, as if the
// server had broken, and the page's script throws reading it.
test('the shop lists eight products', async ({ page }) => {
  await page.route('**/api/products', (route) => route.fulfill({ status: 404, body: 'not found' }));
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});
```

```
%%CAP errors-run%%
```

**Attachment #2 is the one this file added**, and it holds the diagnosis in two lines: the server
answered `404`, and the page threw on the answer. The assertion above it says only *expected 8,
received 0*. Somebody reading this on a build server knows where to look without downloading
anything, which is the reason to put a short text in the terminal rather than in a file nobody
opens.

## Why the hook is `afterEach`

The attachment is made in `afterEach` because a hook runs **whether the test passed or failed**.
Had `attach` been the last line of the test, it would never have run: the test stopped at the
failing `expect`, and nothing after a failed line executes. A passing test gets its messages
attached too, a few hundred bytes of text, and an error in a passing test is still worth seeing.

`messages` lives outside the hooks so that both can reach it, and `beforeEach` empties it, because
a worker runs the tests of a file one after another and the list would otherwise carry one test's
messages into the next.

## The trace already had them

The trace recorded the same two events, with their times, whether or not anybody attached them:

```
%%CAP errors-trace%%
```

So the attachment adds no evidence. It moves the same evidence to where somebody reads first, and
it stays there when there is no trace, which under `retain-on-failure` is the case for every test
that passed.

## Should an uncaught error fail the test?

Lesson 1 named the stronger position: **an uncaught error fails the test that saw it**, whether or
not the page still looks right. With the messages collected, it is one more line at the end of the
`afterEach`:

```javascript
  expect(messages.filter((m) => m.startsWith('pageerror'))).toEqual([]);
```

A team that adds it finds pages that throw and still draw their heading, which no assertion about
the heading would catch. It also finds errors in code nobody on the team owns, a chat widget or an
analytics script, and then has to decide what to do about them. That decision belongs to the team;
the evidence for it is what this section collected.
