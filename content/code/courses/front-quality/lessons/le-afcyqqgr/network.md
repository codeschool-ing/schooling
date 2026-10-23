---
title: The network, under the test's control
version: 1
---

**`page.route` stands between the page and the network: every request that matches its pattern goes
to a function the test wrote, which can answer it, delay it, change it or let it through.** It is the
browser's version of the `load` parameter lesson 3 gave `start()`, and it needs no change to the app.

The planner's fourth test used the plainest form, `route.fulfill({ status: 500 })`: the page asked for
`courses.json` and got an error, without any server failing, and the test checked the sentence the
page showed. The delay in the last section used `route.continue()` to send the request on after a
pause. A third form answers with data the test made up, which is how to test a state the real file
does not contain, such as a course with nothing planned:

```typescript
// e2e/empty.spec.ts
import { expect, test } from "@playwright/test";

test("a course with nothing planned says 0 for its week", async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
  await page.route("**/courses.json", (route) =>
    route.fulfill({ json: { courses: [{ id: "rust", title: "Rust" }], sessions: [] } }),
  );
  await page.goto("/#/course/rust");
  await expect(page.getByRole("heading", { name: "Rust" })).toBeVisible();
  await expect(page.getByRole("listitem")).toHaveCount(0);
  await expect(page.getByText("This week: 0 min")).toBeVisible();
});
```

```
ana@dev:~/planner$ npx playwright test e2e/empty.spec.ts --reporter=list

Running 1 test using 1 worker

  ✓  1 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (265ms)

  1 passed (1.4s)
```

## What not to fake

Each route is a part of the system the test no longer checks. Faking `courses.json` in every test
would mean no test ever loaded the real file, and a typo in it would ship. The planner's suite keeps
the real data in the tests that are about the journey and fakes it only in the tests that are about
a case the real data cannot produce: an error, an empty course, a slow answer. **Fake the network to
reach a state; do not fake it to avoid the real one.**
