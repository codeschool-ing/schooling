---
title: When a browser test fails
version: 1
---

**An end-to-end failure can be anywhere between the data file and the CSS, so Playwright records
what the page looked like when it happened.** To see that, break a test on purpose: change the
expected total of the first test from 160 to 150, as if somebody had worked it out wrong, and run
that one test.

```
ana@dev:~/planner$ npx playwright test e2e/planner.spec.ts -g "shows the week" --reporter=list

Running 1 test using 1 worker

  ✘  1 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (5.3s)


  1) [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week ───────────────────────────

    Error: expect(locator).toBeVisible() failed

    Locator: getByText('This week: 150 min')
    Expected: visible
    Timeout: 5000ms
    Error: element(s) not found

    Call log:
      - Expect "toBeVisible" getByText('This week: 150 min') with timeout 5000ms
      - waiting for getByText('This week: 150 min')


       9 |   await page.goto("/");
      10 |   await expect(page.getByRole("heading", { name: "Study planner" })).toBeVisible();
    > 11 |   await expect(page.getByText("This week: 150 min")).toBeVisible();
         |                                                      ^
      12 | });
      13 |
      14 | test("a session added to a course counts in its week", async ({ page }) => {
        at /home/ana/planner/e2e/planner.spec.ts:11:54

    Error Context: test-results/planner-the-home-page-shows-the-week-chromium/error-context.md

    attachment #2: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/planner-the-home-page-shows-the-week-chromium/trace.zip
    Usage:

        npx playwright show-trace test-results/planner-the-home-page-shows-the-week-chromium/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week ────────────────────────────
```

The report names the test, the line, what was expected and what the page showed instead, and then
two paths in `test-results/`. **`error-context.md`** is written for every failure. It opens with the error
and a few lines of instructions addressed to an AI coding assistant, and at its heart it holds the page
as the accessibility tree saw it at that moment, the same structure Testing Library queries. `sed`
prints just that part:

```
ana@dev:~/planner$ ls test-results/planner-the-home-page-shows-the-week-chromium
error-context.md
trace.zip
ana@dev:~/planner$ sed -n '/^- heading/,/^- paragraph/p' test-results/planner-the-home-page-shows-the-week-chromium/error-context.md
- heading "Study planner" [level=1]
- list:
  - listitem:
    - link "HTML and CSS":
      - /url: "#/course/html-css"
      - img
      - text: HTML and CSS
    - text: 45 min this week
  - listitem:
    - link "JavaScript":
      - /url: "#/course/javascript"
      - img
      - text: JavaScript
    - text: 90 min this week
  - listitem:
    - link "Git":
      - /url: "#/course/git"
      - img
      - text: Git
    - text: 25 min this week
- paragraph: "This week: 160 min"
```

Read it as a person would read the screen: a heading, a list of three links with their minutes, and
the paragraph that says 160. The test was wrong, not the page, and the file says so without anything
being opened. A failure in CI, on a machine you cannot look at, comes with this file.

**`trace.zip`** is the other one, kept because the configuration says `retain-on-failure`. It is a
recording of the whole test: every action, a picture of the page before and after it, the console,
and every request with its response. It opens in the trace viewer, which is a web page:

```sh
npx playwright show-trace test-results/planner-the-home-page-shows-the-week-chromium/trace.zip
```

*That command opens a window and was not run where this course was recorded, which has no screen.*
On your machine it opens the recording at the failing step; on a virtual machine, copy the zip to your
own computer and drop it on `trace.playwright.dev`, which opens it in your browser without sending it
anywhere.

Put the 160 back, and check the suite is green again before going on:

```
ana@dev:~/planner$ git checkout e2e/planner.spec.ts
Updated 1 path from the index
ana@dev:~/planner$ npx playwright test --reporter=list

Running 5 tests using 2 workers

  ✓  1 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (365ms)
  ✓  2 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (368ms)
  ✓  3 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (346ms)
  ✓  4 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (199ms)
  ✓  5 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (151ms)

  5 passed (2.5s)
```
