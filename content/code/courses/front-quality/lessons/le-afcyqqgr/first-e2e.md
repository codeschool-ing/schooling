---
title: The first tests in a browser
version: 1
---

**An end-to-end test does what a person does, in the browser a person uses, against the app as it
is served.** The four tests below cover the planner's whole journey: the week on the home page,
opening a course, adding a session, marking one done, and what happens when the data does not come.
Save this as `e2e/planner.spec.ts`:

```typescript
// e2e/planner.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

test("the home page shows the week", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Study planner" })).toBeVisible();
  await expect(page.getByText("This week: 160 min")).toBeVisible();
});

test("a session added to a course counts in its week", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "JavaScript" }).click();
  await expect(page).toHaveURL(/#\/course\/javascript$/);
  await page.getByLabel("Date").fill("2026-10-23");
  await page.getByLabel("Minutes").fill("15");
  await page.getByRole("button", { name: "Add session" }).click();
  await expect(page.getByText("This week: 105 min")).toBeVisible();
});

test("Done marks a session and takes its button away", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await page.getByRole("button", { name: "Done" }).click();
  await expect(page.getByRole("button", { name: "Done" })).toHaveCount(0);
});

test("a failed load says so", async ({ page }) => {
  await page.route("**/courses.json", (route) => route.fulfill({ status: 500 }));
  await page.goto("/");
  await expect(page.getByText("Could not load your courses.")).toBeVisible();
});
```

Every test receives a `page`, a fresh tab in a fresh browser profile, so no test sees what another
stored. The queries are Testing Library's, by name: `getByRole`, `getByLabel`, `getByText`. And
**`page.clock.setFixedTime` stops the browser's clock** at ten in the morning on Wednesday 21 October
2026, so "this week" is the week of the planner's data on any day this test is run. That is the
sentence lesson 1 left open: the totals you saw in your own browser were 0, and these are not.

The last test answers the request for `courses.json` itself, with a 500, so the page's error path
runs in a real browser without a broken server. The next section but one is about that.

```
ana@dev:~/planner$ npx playwright test --reporter=list

Running 4 tests using 1 worker

  ✓  1 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (275ms)
  ✓  2 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (340ms)
  ✓  3 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (240ms)
  ✓  4 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (159ms)

  4 passed (2.3s)
```

**Four tests, four passes, a few seconds**, most of it starting the dev server and the browser.
`--reporter=list` prints a line per test; without it, Playwright prints a dot per test and writes an
HTML report as well. Commit them:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "End-to-end tests with Playwright"
```

## What this layer saw that the others could not

These tests ran the real `main.ts`, fetching `courses.json` over HTTP from Vite. They clicked
elements that had a size and a place on a page with its CSS applied, and Playwright **refuses to
click** what is hidden, covered or still moving: before each click it checks that the element is
visible, stable, enabled and receives the pointer. A green run here means a person could have done
all of it, in Chromium, which is a stronger sentence than any test in lessons 2 and 3 can say.
