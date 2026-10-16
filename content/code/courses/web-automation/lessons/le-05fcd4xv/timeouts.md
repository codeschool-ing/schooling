---
title: Timeouts, layer by layer
version: 1
---

**Every wait in a Playwright test runs inside more than one clock, and the first one to run out
decides what the failure says.** An assertion has its own; an action and a navigation can have
one; the test has one around all of them; and the run can have one around every test. Lesson 10
read two of them off failures. This section reads them all off the installed code, gives each one
a failure of its own, and ends with the reason not to raise any of them to make a test pass.

## The defaults, from the source

Documentation and memory both drift between versions; the code that is installed does not. These
lines come from `@playwright/test` 1.56.0 in the project. `3e4` is JavaScript for 30000, and `5e3`
for 5000:

```
ana@laptop:~/quitanda$ grep -n -e 'defaultTimeout = ' -e 'defaultExpectTimeout = ' -e 'actionTimeout: \[' -e 'navigationTimeout: \[' -e 'launchTimeout = ' node_modules/playwright/lib/common/config.js node_modules/playwright/lib/matchers/expect.js node_modules/playwright/lib/index.js node_modules/playwright/lib/plugins/webServerPlugin.js
node_modules/playwright/lib/common/config.js:46:const defaultTimeout = 3e4;
node_modules/playwright/lib/matchers/expect.js:129:const defaultExpectTimeout = 5e3;
node_modules/playwright/lib/index.js:133:  actionTimeout: [0, { option: true, box: true }],
node_modules/playwright/lib/index.js:135:  navigationTimeout: [0, { option: true, box: true }],
node_modules/playwright/lib/plugins/webServerPlugin.js:134:    const launchTimeout = this._options.timeout || 60 * 1e3;
ana@laptop:~/quitanda$ grep -n -o -e 'globalTimeout, 0)' -e 'toPass?.timeout, 0)' node_modules/playwright/lib/common/config.js node_modules/playwright/lib/matchers/matchers.js
node_modules/playwright/lib/common/config.js:79:globalTimeout, 0)
node_modules/playwright/lib/matchers/matchers.js:311:toPass?.timeout, 0)
```

| layer | default | where it is set |
|---|---|---|
| the test, its hooks and fixtures | 30 s | `timeout` in the config, `test.setTimeout()` |
| an assertion | 5 s | `expect.timeout` in the config, `{ timeout }` on the call |
| an action: `click`, `fill`… | none of its own | `actionTimeout` under `use`, `{ timeout }` on the call |
| a navigation: `goto`, `reload`… | none of its own | `navigationTimeout` under `use`, `{ timeout }` on the call |
| `toPass` | none of its own | `{ timeout }` on the call |
| the whole run | none | `globalTimeout` in the config |
| starting the `webServer` | 60 s | `webServer.timeout` |

The test's clock covers more than the test function: its documentation says the `beforeEach`
hooks and the fixtures a test uses are counted in it too. **`0` means *no limit of its own*, not
*no wait*.** An action with no timeout still stops when the
test's 30 seconds run out, which is exactly what the click on *Buy now* did in lesson 10. The test
timeout is the outermost clock that is on by default, and everything inside it borrows from it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Nested boxes. The outermost is the run, with no limit by default. Inside it, a test, with 30 seconds by default, hooks included. Inside the test, three steps: page.goto and locator.click with no limit of their own, and expect with 5 seconds of its own. A note says an inner clock longer than the outer one is never reached.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"34\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">the run</text><text x=\"26\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">globalTimeout: no limit by default</text><rect x=\"30\" y=\"66\" width=\"660\" height=\"176\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"46\" y=\"90\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" text-anchor=\"start\">a test</text><text x=\"46\" y=\"108\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">30 s by default, its hooks included</text><rect x=\"50\" y=\"124\" width=\"190\" height=\"66\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\"></rect><text x=\"64\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">page.goto</text><text x=\"64\" y=\"172\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">no limit of its own</text><rect x=\"260\" y=\"124\" width=\"190\" height=\"66\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\"></rect><text x=\"274\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">locator.click</text><text x=\"274\" y=\"172\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">no limit of its own</text><rect x=\"470\" y=\"124\" width=\"190\" height=\"66\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">expect</text><text x=\"484\" y=\"172\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">5 s of its own</text><text x=\"46\" y=\"220\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">an inner clock longer than the outer one is never reached</text></svg>", "caption": "Clocks inside clocks. A step with no limit of its own stops when the test does."}
```

## One failure per layer

This file waits for four things that cannot happen in time, each with a different clock set
short. It is not part of the project: put it in `tests/scratch.spec.js`, run it, then delete the
file.

```javascript
import { test, expect } from '@playwright/test';

test('an action with a timeout of its own', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Buy now' }).click({ timeout: 2000 });
});

test('a navigation slower than its timeout', async ({ page }) => {
  await page.goto('/slow/ssr.js', { timeout: 1000 });
});

test('an assertion shorter than the page needs', async ({ page }) => {
  await page.goto('/ssr');
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true', { timeout: 1000 });
});

test('a test shorter than its steps', async ({ page }) => {
  test.setTimeout(1000);
  await page.goto('/ssr');
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/scratch.spec.js --workers 1

Running 4 tests using 1 worker

  ✘  1 tests/scratch.spec.js:3:1 › an action with a timeout of its own (2.2s)
  ✘  2 tests/scratch.spec.js:8:1 › a navigation slower than its timeout (2.6s)
  ✘  3 tests/scratch.spec.js:12:1 › an assertion shorter than the page needs (1.2s)
  ✘  4 tests/scratch.spec.js:17:1 › a test shorter than its steps (1.0s)


  1) tests/scratch.spec.js:3:1 › an action with a timeout of its own ───────────────────────────────

    TimeoutError: locator.click: Timeout 2000ms exceeded.
    Call log:
      - waiting for getByRole('button', { name: 'Buy now' })


      3 | test('an action with a timeout of its own', async ({ page }) => {
      4 |   await page.goto('/');
    > 5 |   await page.getByRole('button', { name: 'Buy now' }).click({ timeout: 2000 });
        |                                                       ^
      6 | });
      7 |
      8 | test('a navigation slower than its timeout', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:5:55

    Error Context: test-results/scratch-an-action-with-a-timeout-of-its-own/error-context.md

  2) tests/scratch.spec.js:8:1 › a navigation slower than its timeout ──────────────────────────────

    TimeoutError: page.goto: Timeout 1000ms exceeded.
    Call log:
      - navigating to "http://localhost:3000/slow/ssr.js", waiting until "load"


       7 |
       8 | test('a navigation slower than its timeout', async ({ page }) => {
    >  9 |   await page.goto('/slow/ssr.js', { timeout: 1000 });
         |              ^
      10 | });
      11 |
      12 | test('an assertion shorter than the page needs', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:9:14

    Error Context: test-results/scratch-a-navigation-slower-than-its-timeout/error-context.md

  3) tests/scratch.spec.js:12:1 › an assertion shorter than the page needs ─────────────────────────

    Error: expect(locator).toHaveAttribute(expected) failed

    Locator:  locator('body')
    Expected: "true"
    Received: ""
    Timeout:  1000ms

    Call log:
      - Expect "toHaveAttribute" with timeout 1000ms
      - waiting for locator('body')
        5 × locator resolved to <body>…</body>
          - unexpected value "null"


      12 | test('an assertion shorter than the page needs', async ({ page }) => {
      13 |   await page.goto('/ssr');
    > 14 |   await expect(page.locator('body')).toHaveAttribute('data-ready', 'true', { timeout: 1000 });
         |                                      ^
      15 | });
      16 |
      17 | test('a test shorter than its steps', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:14:38

    Error Context: test-results/scratch-an-assertion-shorter-than-the-page-needs/error-context.md

  4) tests/scratch.spec.js:17:1 › a test shorter than its steps ────────────────────────────────────

    Test timeout of 1000ms exceeded.

    Error: expect(locator).toHaveAttribute(expected) failed

    Locator:  locator('body')
    Expected: "true"
    Received: ""

    Call log:
      - Expect "toHaveAttribute" with timeout 5000ms
      - waiting for locator('body')
        5 × locator resolved to <body>…</body>
          - unexpected value "null"


      18 |   test.setTimeout(1000);
      19 |   await page.goto('/ssr');
    > 20 |   await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
         |                                      ^
      21 | });
      22 |
        at /home/ana/quitanda/tests/scratch.spec.js:20:38

    Error Context: test-results/scratch-a-test-shorter-than-its-steps/error-context.md

  4 failed
    tests/scratch.spec.js:3:1 › an action with a timeout of its own ────────────────────────────────
    tests/scratch.spec.js:8:1 › a navigation slower than its timeout ───────────────────────────────
    tests/scratch.spec.js:12:1 › an assertion shorter than the page needs ──────────────────────────
    tests/scratch.spec.js:17:1 › a test shorter than its steps ─────────────────────────────────────
```

**Each message names the clock that ran out**, and that is the first thing to read in any timeout.
`locator.click: Timeout 2000ms exceeded` and `page.goto: Timeout 1000ms exceeded` are the action's
and the navigation's own. The assertion reports `Timeout: 1000ms`. The last one is the instructive
one: its call log still says `with timeout 5000ms`, the assertion's own clock, but the test's clock
of one second ran out first, and the failure opens with `Test timeout of 1000ms exceeded`. An inner
timeout longer than the outer one is never reached.

## Choosing the numbers

Two rules cover most suites. **Leave the assertion's five seconds alone, and give actions and
navigations a limit of their own**, such as ten or fifteen seconds through `actionTimeout` and
`navigationTimeout`, so that a click that can never happen fails with its own name after a few
seconds instead of using up the whole test. And when one step is genuinely slow, an upload or a
report the server builds, give **that call** a `{ timeout }`, with a comment saying why. A number
raised for the whole suite is paid by every test that fails.

## Why raising a timeout hides a defect

The tempting fix for a timeout is a bigger timeout, and sometimes it is wrong in a way no test will
ever report. This file stands in for a release that made the shop's product list six seconds
slower, by holding the answer back with `page.route`, as lesson 3's `at-load.mjs` did. Put it in
`tests/scratch.spec.js` in place of the last one, run it, and delete the file afterwards:

```javascript
import { test, expect } from '@playwright/test';

// Stands in for a release that made the products six seconds slower.
test.beforeEach(async ({ page }) => {
  await page.route('**/api/products', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 6000));
    await route.continue();
  });
});

test('the default timeout notices', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});

test('a raised timeout does not', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8, { timeout: 10000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/scratch.spec.js --workers 1

Running 2 tests using 1 worker

  ✘  1 tests/scratch.spec.js:11:1 › the default timeout notices (5.2s)
  ✓  2 tests/scratch.spec.js:16:1 › a raised timeout does not (7.2s)


  1) tests/scratch.spec.js:11:1 › the default timeout notices ──────────────────────────────────────

    Error: expect(locator).toHaveCount(expected) failed

    Locator:  locator('#products li')
    Expected: 8
    Received: 0
    Timeout:  5000ms

    Call log:
      - Expect "toHaveCount" with timeout 5000ms
      - waiting for locator('#products li')
        9 × locator resolved to 0 elements
          - unexpected value "0"


      11 | test('the default timeout notices', async ({ page }) => {
      12 |   await page.goto('/');
    > 13 |   await expect(page.locator('#products li')).toHaveCount(8);
         |                                              ^
      14 | });
      15 |
      16 | test('a raised timeout does not', async ({ page }) => {
        at /home/ana/quitanda/tests/scratch.spec.js:13:46

    Error Context: test-results/scratch-the-default-timeout-notices/error-context.md

  1 failed
    tests/scratch.spec.js:11:1 › the default timeout notices ───────────────────────────────────────
  1 passed (15.0s)
```

**The raised timeout passed a shop where a customer stares at an empty page for six seconds.** The
default failed, and its failure was the only report anybody would get that the release had made
the page slower; the passing test is green, quiet, and wrong about the thing a customer would
notice first. A timeout is not only how long a test is willing to wait. It is also the slowest
answer the test is willing to call correct, and raising it changes what the suite accepts. Whether
six seconds is acceptable is a question for `non-functional-testing` lesson 10, on front-end
performance, not one to settle by editing a number until the run goes green.
