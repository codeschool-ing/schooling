---
title: The limits, and where each one comes from
version: 1
---

Lists of Cypress's limits are easy to find and hard to remember, because they read as arbitrary.
They are not. **Nearly every one is the price of the position this lesson started with**: a test
that runs as a script on a page lives by the rules for scripts on a page. This section takes the
four that matter to a tester, measures the first for real, and ends with what Cypress costs.

## One origin at a time

An **origin** is the scheme, the host and the port of an address together: `http://localhost:3000`
is one. A browser lets a script read a frame, a window or a response only when it comes from the
script's own origin. That rule, the **same-origin policy**, is most of what keeps one website from
reading another one open in the same browser.

The rule can be watched without Cypress. This script opens the shop, puts two frames on the page,
one from `localhost` and one from `127.0.0.1`, and asks each for its title twice: once from code
running inside the page, and once from Playwright's own process. Save it as `origins.mjs`:

```schooling-example
{"language": "javascript", "file": "origins.mjs", "parts": [{"code": "// One page, two frames: one from the page's own origin and one from\n// another. Run it with the shop started: node origins.mjs\nimport { chromium } from '@playwright/test';\n\nconst browser = await chromium.launch();\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/');", "note": "Playwright opens the shop at `localhost`, as any test of this course does."}, {"code": "\nawait page.evaluate(async () => {\n  for (const src of ['http://localhost:3000/', 'http://127.0.0.1:3000/']) {\n    const frame = document.createElement('iframe');\n    frame.src = src;\n    document.body.append(frame);\n    await new Promise((loaded) => frame.addEventListener('load', loaded));\n  }\n});", "note": "Code that runs in the page adds two frames showing the same shop. `localhost` and `127.0.0.1` reach the same server, but the browser compares origins by their text, so the second frame belongs to another origin."}, {"code": "\nconst inside = await page.evaluate(() =>\n  [...document.querySelectorAll('iframe')].map((frame) => {\n    try {\n      return `${frame.src}  ${frame.contentWindow.document.title}`;\n    } catch (error) {\n      return `${frame.src}  ${error.name}: ${error.message}`;\n    }\n  }));\nconsole.log('asked from inside the page:');\nfor (const line of inside) console.log('  ' + line);", "note": "Still inside the page, the code reads each frame's title, the way a Cypress test reads anything: as a script on the page. An error is printed rather than thrown, so one frame cannot hide the other."}, {"code": "\nconsole.log('asked from outside, through the driver:');\nfor (const frame of page.frames().slice(1)) {\n  console.log(`  ${frame.url()}  ${await frame.title()}`);\n}\nawait browser.close();", "note": "Then Playwright reads the same two titles from its own process, through the browser's debugging protocol rather than through the page."}]}
```

With the shop started:

```
ana@laptop:~/quitanda$ node origins.mjs
asked from inside the page:
  http://localhost:3000/  Quitanda
  http://127.0.0.1:3000/  SecurityError: Failed to read a named property 'document' from 'Window': Blocked a frame with origin "http://localhost:3000" from accessing a cross-origin frame.
asked from outside, through the driver:
  http://localhost:3000/  Quitanda
  http://127.0.0.1:3000/  Quitanda
```

**The same server, asked the same question, answered once and refused once.** From inside the page,
the frame at `127.0.0.1` is another origin, and the browser blocks the script with a
`SecurityError`. From outside, Playwright reads both titles, because it is not a script on the page
and the rule is not about it. A Cypress test stands where the first question was asked.

Cypress works around the rule in two ways. Its server serves the runner at the application's own
address, so the runner and the application share one origin, which is why ordinary tests never meet
the rule at all. And when a test has to move to a second origin, the usual case being a sign-in page
on another domain, it wraps those steps in `cy.origin`:

```javascript
it('opens the shop at a second origin', () => {
  cy.visit('/');
  cy.origin('http://127.0.0.1:3000', () => {
    cy.visit('/');
    cy.get('#products li').should('have.length', 8);
  });
});
```

The commands inside the function run in that origin. **The function is sent there as text**, so it
cannot use a variable from the test around it; a value it needs has to be passed in with the
`args` option, which the type definitions show. That is an odd rule for JavaScript, and it is the
same-origin policy again, seen from the inside.

## One tab, and frames

A Cypress test drives one tab. A link that opens a new tab, `target="_blank"`, opens nothing the
test can follow, and its documentation says plainly that driving several tabs is not supported.
The usual answer is to check where the link points, or to remove the attribute and follow it in the
same tab. Two users at once, each in a browser of their own, is out of reach for the same reason;
lesson 10 shows Playwright doing it with two contexts.

Frames are partly in reach. There is no command that steps into a frame; a test reaches the
document of a same-origin frame through the element, with `.its('0.contentDocument.body')`, and
the frame from another origin is closed to it, as the capture above showed for any script.

## The browsers it can drive

`npx cypress run` uses **Electron**, which comes inside the binary, unless told otherwise.
`--browser` picks an installed one by name: its documentation lists the Chrome family (Chrome,
Chromium, Edge) and Firefox. **Safari is not on the list.** The type definitions carry an
`experimentalWebKitSupport` setting, an experiment with WebKit, the engine under Safari, which is
not Safari itself. Lesson 10's Playwright drives Chromium, Firefox and WebKit as equals, and
`manual-testing` lesson 7 is about why the browser matters at all. The tests themselves are
JavaScript or TypeScript; there is no Cypress for Python or Java.

## What it costs

The runner is free: the package is MIT-licensed, and its own `package.json` says so. The paid part
is **Cypress Cloud**, a service the runner can send its results to. Two of `cypress run`'s options
lead there, and the package's help text, which runs without the binary, says what they are for:

```
ana@laptop:~/quitanda$ npx cypress run --help | grep -E -- '--(browser|parallel|record) '
  -b, --browser <browser-name-or-path>                        runs Cypress in the browser with the given name. if a filesystem path is supplied, Cypress will attempt to use the browser at that path.
  --parallel                                                  enables concurrent runs and automatic load balancing of specs across multiple machines or processes
  --record [bool]                                             records the run. sends test results, screenshots and videos to Cypress Cloud.
ana@laptop:~/quitanda$ grep '"license"' node_modules/cypress/package.json
  "license": "MIT",
```

`--record` sends the run to Cloud, and `--parallel` balances the specs across machines or
processes; its documentation runs it through the same service, together with `--record`. Nothing in this course needs either. Lesson 19 splits a suite
across workers with Playwright, which does that on one machine with no service at all. The prices
and the free allowance are Cypress's to set and change, so they are not quoted here.
