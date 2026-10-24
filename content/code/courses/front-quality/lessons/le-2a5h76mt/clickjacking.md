---
title: Clickjacking, and the line that already stops it
version: 1
---

**Clickjacking puts a real page inside another, invisibly, so that the person clicks a button on the
real page while looking at the other one.** The planner signed in, a button that says Done placed under
something that says *claim your prize*: the click is genuine, from the person, on the planner, with
their cookie, and no request forgery is needed because nothing is forged.

The defence is one line, and the planner has had it since lesson 8: **`frame-ancestors 'none'`** in the
Content Security Policy, which tells the browser that no page may put this one in a frame. The older
header `X-Frame-Options: DENY` says the same to browsers that do not read the directive, and every
current browser does. What the planner lacks is a test that the line works, so here is one, with a
control beside it. Save this as `e2e/frame.spec.ts`:

```typescript
// e2e/frame.spec.ts
import { expect, test, type Page } from "@playwright/test";

async function framedBy(page: Page, address: string): Promise<string> {
  await page.setContent(`<h1>another site</h1><iframe src="${address}"></iframe>`);
  return page.frames()[1].url();
}

test("another site cannot put the built planner in a frame", async ({ page }) => {
  expect(await framedBy(page, "http://localhost:4173/")).toBe("chrome-error://chromewebdata/");
});

test("without the policy, the same frame loads: the control", async ({ page }) => {
  expect(await framedBy(page, "http://localhost:5173/")).toBe("http://localhost:5173/");
});
```

`setContent` gives the test a page that belongs to no site, a stand-in for another one, holding a frame
of the planner. When a frame is refused, Chromium shows its own error page in it, and its address is
`chrome-error://chromewebdata/`; that address is Chromium's and the test says so by naming it.

**The second test is a control.** It frames the dev server, which sends no policy, and expects the frame
to load. If it ever failed, the first test's pass would mean nothing, because a frame that cannot load
for some other reason also never shows the planner.

```
ana@dev:~/planner$ npx playwright test e2e/frame.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✓  1 [chromium] › e2e/frame.spec.ts:9:1 › another site cannot put the built planner in a frame (114ms)
  ✓  2 [chromium] › e2e/frame.spec.ts:13:1 › without the policy, the same frame loads: the control (166ms)

  2 passed (3.7s)
```

Commit it:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Test that no other site can frame the built planner"
```
