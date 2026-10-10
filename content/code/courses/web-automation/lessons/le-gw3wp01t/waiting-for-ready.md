---
title: Waiting for the page to be ready
version: 1
---

The test needs to wait for something before it clicks. What it waits for is the whole question,
and the first answer most people reach for does not work here.

## Why `toBeEnabled` cannot help

`await expect(button).toBeEnabled()` waits until a button is enabled. The buttons on `/ssr` are
enabled from the moment the HTML arrives, so the assertion passes at once and the click still lands
in the gap. **A wait helps only if the thing it watches changes when the page becomes ready**, and
nothing about the button changes when its handler is attached. Lesson 13 is about waits in
general; this lesson needs only that one rule.

## Three signals, strongest first

- **A marker the page sets when it is ready.** `ssr.js` ends with
  `document.body.dataset.ready = 'true'`, after every button has its handler, so waiting for
  `data-ready="true"` on the `<body>` waits for exactly the condition the click needs.
- **The script's response.** `page.waitForResponse('**/slow/ssr.js')` waits for the file to
  arrive. Playwright's documentation says the response event fires when the status and headers are
  received, which is before the browser has read the rest of the file and run it. On this shop the
  script is short and runs almost at once, but the test would be waiting for the wrong event and
  trusting the next few milliseconds for the rest.
- **The network going quiet.** `page.waitForLoadState('networkidle')` waits until the page has
  made no request for half a second. It happens to work here, because the slow script is the last
  thing the page asks for. Its documentation marks it as discouraged for tests, and a page that
  asks the server for news every few seconds never goes quiet at all.

The second one is worth seeing written down, because it has a trap of its own: the wait has to
start **before** `goto`, or the response can arrive while nobody is listening for it:

```javascript
const script = page.waitForResponse('**/slow/ssr.js');
await page.goto('/ssr');
await script;
```

## The test, waiting for the marker

The new version waits for the body's attribute and then clicks. It replaces the first one. Save it
as `tests/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so every test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a click on /ssr adds to the basket once the page is ready', async ({ page }) => {
  await page.goto('/ssr');
  // ssr.js sets this as its last line, after every button has a handler.
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js --repeat-each 5 --workers 1

Running 5 tests using 1 worker

  ✓  1 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.1s)
  ✓  2 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.1s)
  ✓  3 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.1s)
  ✓  4 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.2s)
  ✓  5 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.0s)

  5 passed (15.0s)
```

Five passes out of five, each taking a little over two seconds, a second and a half of which is the
server's pause. The test waits exactly as long as the page needs and no longer.

## The better fix belongs to the page

The marker works, and it is an agreement between the page and its tests that nobody else can see.
A developer who renames the attribute breaks the test without changing anything a user would
notice. There is a fix that serves everybody, and it is the developers' to make and a tester's to
ask for: **send the buttons disabled, and enable each one when its handler is attached.** A person
then sees a greyed-out button instead of tapping one that ignores them, a screen reader announces
it as unavailable, and Playwright's actionability check, which already waits for a button to be
enabled before clicking, does the waiting with no extra line in the test.

It is two edits. In `app/routes/ssr.js`, the button is sent with `disabled`:

```javascript
        <button type="button" data-id="${p.id}" disabled>Add to basket</button>
```

and in `app/public/ssr.js`, a new first line inside the loop enables it again:

```javascript
  button.disabled = false;
```

Make both, put back the first version of `tests/ssr.spec.js` from the previous section, the one
that clicks at once, and run it:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js

Running 1 test using 1 worker

  ✓  1 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket (2.0s)

  1 passed (3.2s)
```

**The test that failed five times out of five passes, and not one line of it changed.** Undo the
two edits and restore the test that waits for the marker afterwards, because the rest of the
course expects the shop as it was shown. In a team, this run is the evidence that goes with the
request to the developers; `manual-testing` lesson 15 is about what such a report needs.
