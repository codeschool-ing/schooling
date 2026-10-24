---
title: Waiting is built in, and why it matters
version: 1
---

**A browser does things on its own time: it fetches, it parses, it runs scripts, and the page you
asked for arrives in pieces.** A test that reads the page once, at the wrong moment, sees an
unfinished page. That is the most common cause of a **flaky** test, one that passes or fails on the
same code depending on how fast the machine was.

Here is one made on purpose. The data is held back for half a second, which is what a slow network
does, and two tests read the course list in two ways. Save this as `e2e/waiting.spec.ts`:

```typescript
// e2e/waiting.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.route("**/courses.json", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
});

test("reading once, straight away", async ({ page }) => {
  await page.goto("/");
  expect(await page.getByRole("listitem").count()).toBe(3);
});

test("asserting, and letting it retry", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("listitem")).toHaveCount(3);
});
```

```
ana@dev:~/planner$ npx playwright test e2e/waiting.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✘  1 [chromium] › e2e/waiting.spec.ts:11:1 › reading once, straight away (276ms)
  ✓  2 [chromium] › e2e/waiting.spec.ts:16:1 › asserting, and letting it retry (986ms)


  1) [chromium] › e2e/waiting.spec.ts:11:1 › reading once, straight away ───────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: 3
    Received: 0

      11 | test("reading once, straight away", async ({ page }) => {
      12 |   await page.goto("/");
    > 13 |   expect(await page.getByRole("listitem").count()).toBe(3);
         |                                                    ^
      14 | });
      15 |
      16 | test("asserting, and letting it retry", async ({ page }) => {
        at /home/ana/planner/e2e/waiting.spec.ts:13:52

    Error Context: test-results/waiting-reading-once-straight-away-chromium/error-context.md

    attachment #2: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/waiting-reading-once-straight-away-chromium/trace.zip
    Usage:

        npx playwright show-trace test-results/waiting-reading-once-straight-away-chromium/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    [chromium] › e2e/waiting.spec.ts:11:1 › reading once, straight away ────────────────────────────
  1 passed (3.7s)
```

**The first test read the page once, found no items, and failed.** `page.goto` waits for the page's
`load` event, and the planner's script was still waiting for its data when that fired. On a fast
network the same test passes, which is exactly what makes it dangerous: it is green on your machine
and red in CI on a busy afternoon.

The second test differs by where the `await` sits. `expect(locator).toHaveCount(3)` is a
**web-first assertion**: it keeps asking the page until the answer is right or five seconds have
passed. It waited about half a second here, and it would wait as long as the network needed, and not
a moment longer.

The rule is lesson 3's, in a real browser: **assert on a locator, never on a value read out of it.**
`expect(locator).toHaveText(…)` retries; `expect(await locator.textContent()).toBe(…)` reads once.
The same goes for a fixed pause, `page.waitForTimeout(1000)`, which is too long on a fast machine and
too short on a slow one.

The demonstration has done its work; delete the file so it does not fail the suite:

```
ana@dev:~/planner$ rm e2e/waiting.spec.ts
```
