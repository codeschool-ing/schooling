---
title: axe, a machine for what a machine can decide
version: 1
---

**axe-core is an engine of accessibility rules that runs inside a page and reports every element that
breaks one.** It is open source, from Deque, and it is what most accessibility checkers are built on,
the ones inside Chrome's developer tools included. `@axe-core/playwright` puts it in the browser a
Playwright test already drives:

```
ana@dev:~/planner$ npm install --save-exact -D @axe-core/playwright@4.14.0

added 2 packages, and audited 116 packages in 729ms

found 0 vulnerabilities
```

Each rule of axe is tagged with what it tests, and a test chooses rules by tag. **These five are WCAG
2.2 at level AA**, every criterion of the levels A and AA of each version, since 2.2 builds on 2.1 and 2.1
on 2.0:

| tag | the criteria |
|---|---|
| `wcag2a`, `wcag2aa` | WCAG 2.0, levels A and AA |
| `wcag21a`, `wcag21aa` | added in 2.1 |
| `wcag22aa` | added in 2.2 |

axe also has rules tagged `best-practice`, which are good advice that no WCAG criterion requires, such as
every page having one `main` landmark. They are worth reading and are kept out of a pass or fail on WCAG,
so that a red test always means a criterion failed.

Before the test, a small program that prints what axe finds in words, so the findings can be read rather
than counted. Save it as `server/axe.mjs`:

```javascript
// server/axe.mjs
import { chromium } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const wcag22aa = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const browser = await chromium.launch();
const page = await (await browser.newContext()).newPage();
await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
for (const address of process.argv.slice(2)) {
  await page.goto(address);
  await page.getByRole("heading", { level: 1 }).waitFor();
  const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
  console.log(`${address}: ${violations.length} rule(s) broken`);
  for (const v of violations) {
    console.log(`  ${v.id} (${v.impact}): ${v.help}`);
    for (const node of v.nodes) console.log(`    ${node.target.join(" ")}  ${node.any[0]?.message ?? ""}`);
  }
}
await browser.close();
```

axe needs the page to belong to a browser context of its own, which is why the page is made through
`newContext()` rather than straight from the browser. The program opens each address it is given, waits for the planner's heading so that axe sees the page drawn, and
prints each broken rule with axe's own one-line description, then each element that breaks it and the
reason axe gives. The clock is stopped on the week of the data, as in lesson 4, so the totals on the page
are the ones the tests expect.
