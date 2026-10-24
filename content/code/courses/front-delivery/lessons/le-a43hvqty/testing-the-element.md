---
title: Testing the element in a browser
version: 1
---

**An element is best tested where it runs, in a browser, and Playwright reaches into open shadow roots on
its own.** A locator such as `page.locator("#session-6 .when")` finds the `.when` span although it is inside
the row's shadow tree, and `getByRole` finds the button the same way. The library gets the same two test
packages the planner got in lesson 6, pinned to the same versions:

```
ana@dev:~/planner-ui$ npm install --save-dev --save-exact @playwright/test@1.63.0 @axe-core/playwright@4.14.0 2>&1 | tail -1
found 0 vulnerabilities
```

The configuration starts Vite on a port of its own, so the tests never meet a dev server you left running,
and runs in Chromium:

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  use: { baseURL: "http://127.0.0.1:5180" },
  webServer: {
    command: "npx vite --host 127.0.0.1 --port 5180 --strictPort",
    url: "http://127.0.0.1:5180/",
    reuseExistingServer: false,
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
```

The tests open the demo page and check four things, one per test:

```typescript
// tests/session-element.spec.ts
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.goto("/");
});

test("draws its attributes", async ({ page }) => {
  await expect(page.locator("#session-6 .when")).toHaveText("2026-10-15 · 45 min");
  await expect(page.locator("#session-4 .when")).toHaveText("2026-10-12 · 1 h");
});

test("marks itself done and says so", async ({ page }) => {
  await page.locator("#session-6").getByRole("button", { name: "Mark done" }).click();
  await expect(page.locator("#session-6")).toHaveAttribute("done", "");
  await expect(page.locator("#log")).toHaveText("session-6 marked done");
});

test("keeps the page's styles out", async ({ page }) => {
  const button = page.locator("#session-6").getByRole("button");
  await expect(button).toHaveCSS("background-color", "rgb(47, 111, 78)");
});

test("passes axe", async ({ page }) => {
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations.map((v) => v.id)).toEqual([]);
});
```

- **Draws its attributes** reads the text the shadow tree drew from `date` and `minutes`, through the
  library's own `duration`.
- **Marks itself done and says so** presses the button as a person would, then checks the two results in
  the order the element produces them: the attribute, then the event the page heard.
- **Keeps the page's styles out** asks for the button's computed background. `rgb(47, 111, 78)` is
  `#2f6f4e`, the token `--color-green-600` that `--accent` points at in the light theme; the page's red
  would be `rgb(255, 0, 0)`. One assertion proves both halves of the last two sections: the selector did
  not get in, and the custom property did.
- **Passes axe** runs the accessibility rules over the page, shadow trees included.

Run them, after telling Git to leave Playwright's output alone:

```
ana@dev:~/planner-ui$ printf 'test-results\nplaywright-report\n' >> .gitignore
```

```
ana@dev:~/planner-ui$ npx playwright test 2>&1 | tail -1
  4 passed (5.2s)
```

Four passed. Commit the element with its page and its tests:

```
ana@dev:~/planner-ui$ git add -A && git commit -qm "Add <planner-session>, its demo page and its tests"
```

## A test that can fail

A test that has never failed has not shown it can. So break the boundary on purpose: make `#root` the
element itself instead of a shadow root, and the same template is drawn into the light DOM, where the
page's rules reach it.

```
ana@dev:~/planner-ui$ sed -i 's/#root = this.attachShadow({ mode: "open" });/#root = this;/' src/session-element.ts
ana@dev:~/planner-ui$ npx playwright test 2>&1 | grep -E '^  [0-9]+ (failed|passed)|Received: |"color-contrast"'
    Received: "rgb(255, 0, 0)"
    +   "color-contrast",
  2 failed
  2 passed (11.5s)
ana@dev:~/planner-ui$ git restore src/session-element.ts
```

Two tests fail, and each says what it found. The button is the page's red, and axe now finds a
`color-contrast` violation: red text and white on red both measure about 4:1 against the 4.5:1 that
text needs. That is why the demo page's rules say `main button` and not `button`: with no shadow root,
the element's `<style>` would be one more style sheet in the page, and a plain `button` rule in the page
would lose to it on order alone, so the test would pass with the boundary gone. `git restore` puts the
file back as it was committed.

## Where Playwright stops

Playwright's CSS and role locators pierce **open** shadow roots. They do not pierce closed ones, and XPath
does not pierce any, which is one more reason the element is open. A test that must reach a closed tree
has to go through code the element exposes for it, and at that point the element's privacy is a cost
rather than a protection.

A runner on a simulated DOM, jsdom or happy-dom under Vitest, supports custom elements and shadow roots
too, and starts faster. It does not compute styles from a real cascade, though, so the third test, the one
about the boundary, could only run in a real browser. The planner's unit tests stay in Vitest; what the
element draws is tested here.
