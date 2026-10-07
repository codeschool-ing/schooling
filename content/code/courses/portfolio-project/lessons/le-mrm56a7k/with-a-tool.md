---
title: What a tool finds
version: 2
---

**axe** is an open-source engine that tests a page against the WCAG criteria a machine can decide. The
script below opens loanbook in Chromium at two widths, runs axe with the WCAG A and AA rules, and also
checks whether the page scrolls sideways:

```schooling-example
{"language": "javascript", "file": "axe-check.mjs", "parts": [{"code": "// Open the page in Chromium at two widths and print what axe finds.\nimport { chromium } from 'playwright';\nimport { AxeBuilder } from '@axe-core/playwright';\n\nconst url = process.argv[2] || 'http://127.0.0.1:8000/';\nconst browser = await chromium.launch();", "note": "Two libraries: Playwright drives a real Chromium, and `@axe-core/playwright` runs axe inside the page it opened."}, {"code": "for (const width of [1280, 320]) {\n  const context = await browser.newContext({ viewport: { width, height: 800 } });\n  const page = await context.newPage();\n  await page.goto(url);\n  await page.waitForSelector('#items tr');", "note": "The same page at a desktop width and at 320 pixels. It waits for the first table row, because the list is drawn by JavaScript after the page loads, and checking before that would check an empty table."}, {"code": "  const { violations } = await new AxeBuilder({ page })\n    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])\n    .analyze();", "note": "Only the WCAG A and AA rules, up to 2.2, which is the level lesson 13 calls the floor. axe also has best-practice rules; they are useful, and they are not the standard."}, {"code": "  const sideways = await page.evaluate(\n    () => document.documentElement.scrollWidth > window.innerWidth);\n  console.log(`${width}px: ${violations.length} problem(s)` +\n    (sideways ? ', and the page scrolls sideways' : ''));\n  for (const v of violations) {\n    console.log(`  ${v.id}: ${v.nodes.length} element(s). ${v.help}`);\n  }\n  await context.close();\n}\nawait browser.close();", "note": "Sideways scrolling is not an axe rule, so the script checks it itself: a document wider than the window scrolls. Then one line per problem, with how many elements have it."}]}
```

To run it on your own project you need Node.js, from nodejs.org or your system's packages, and, once, in
the folder that holds the script, Playwright, the axe engine and the Chromium that Playwright drives:

```sh
npm install playwright @axe-core/playwright
npx playwright install chromium
```

Then `node axe-check.mjs` with your page's address after it. These transcripts start with a bare `$`
because they ran on a computer with a desktop and a browser, not on the laptop of the other transcripts,
against loanbook at two steps of its history. Here is the page at step 10, **before** the accessibility
commit:

```
$ node axe-check.mjs
1280px: 0 problem(s)
320px: 1 problem(s), and the page scrolls sideways
  target-size: 1 element(s). All touch targets must be 24px large, or leave sufficient space
```

At 1280 pixels, nothing. At 320, one problem, a touch target smaller than 24 pixels, and the page scrolls
sideways: the table is wider than the phone. Now the same check **after** steps 11 and 12:

```
$ node axe-check.mjs
1280px: 0 problem(s)
320px: 0 problem(s)
```

Clean at both widths. It would be easy to stop here, and it would be wrong. Look at what axe did **not**
report on the page before: the name field had only a placeholder, *Borrower*, with no label, and axe
passed it. A placeholder counts as an accessible name, so a machine that checks *does this field have a
name?* finds one. What it cannot check is that the placeholder vanishes the moment you start typing, and
that *Borrower* does not say which item the loan is for. **The tool answered the question it can answer.**
The next section asks the one it cannot.
