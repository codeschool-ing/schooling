---
title: What belongs at each level
version: 1
---

**Each level of test answers a different question, at a different price, and a failure means
something different at each.** The planner now has a test at every level Angular has:

| level | in the planner | what a failure means | price |
| --- | --- | --- | --- |
| a plain function | `planner.spec.ts`, `minutes-pipe.spec.ts` | the rule is wrong | almost nothing, and a failure points at one function |
| a service, with a fake server | `planner-store.spec.ts` | the store mishandles an answer | `TestBed`, a fake backend, a `tick()` |
| a component, through its page | `course-sessions.spec.ts`, `week-summary.spec.ts` | the page shows the wrong thing | the component and everything it imports, rendered in jsdom |
| a component, with harnesses | the second test of `course-sessions.spec.ts` | a control does not do what it says | a harness per control, and an `await` per step |
| the whole application, in a browser | the `look` transcripts of this course | the pieces do not fit together | a running server, a browser, and seconds per check |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Five levels of test, one per row, from a plain function at the top to the whole application in a browser at the bottom. Each row has a bar whose length is the price of a test at that level, growing from short to long, and names the planner&#x27;s file at that level. An arrow down the side says that a failure means more, and points at less, further down.\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a plain function</text><rect x=\"230\" y=\"34\" width=\"115\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planner.spec.ts</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a service, fake server</text><rect x=\"230\" y=\"78\" width=\"185\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planner-store.spec.ts</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a component, its page</text><rect x=\"230\" y=\"122\" width=\"250\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course-sessions.spec.ts</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a component, harnesses</text><rect x=\"230\" y=\"166\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MatCheckboxHarness</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the application, a browser</text><rect x=\"230\" y=\"210\" width=\"400\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">look</text><text x=\"230\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">price of one test</text><line x1=\"680\" y1=\"40\" x2=\"680\" y2=\"238\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,238.0 676.9,230.6 683.1,230.6\" fill=\"var(--wire)\"></polygon><text x=\"672\" y=\"246\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">covers more, points at less</text></svg>", "caption": "Each rule goes to the cheapest level that can see it; the levels below the top cost more and say less about where the fault is."}
```

Two rules decide where a test goes.

**Push each rule down to the cheapest level that can see it.** The week's arithmetic was tested
through `Week` in lesson 10, which needed the router, a token and a rendered page to check a date
range. The same rule tested on `weekOf` needs none of that, and when it fails it names the function.
A component test should check what the component adds, the choosing, sorting and hiding, and trust
the levels below for the rest.

**Test what a person or a caller can see, never how it is done.** Every test in this lesson reads a
result: the text of a page, the value of a signal, the request that was sent. None reads a private
field or counts how often a method ran. That is what lets a test survive a rewrite of the code it
tests, which is the point of having one.

## The level this lesson does not write

The last row is end-to-end testing: the real server, the real API, a real browser, a person's
steps from the first page to the result. It is the only level that catches a fake that has drifted
from what it imitates, an API that renamed a field while every test kept answering with the old
one. The Angular CLI ships no runner for it; `ng e2e` offers to add one, Playwright or Cypress among
them. The `look` program this course has used since lesson 2 is a small version of the same idea,
Playwright driving Chromium, and its transcripts are this course's end-to-end checks: run again,
they would fail if the planner stopped doing what the lessons say.

End-to-end tests are worth having and expensive to keep: they are slow, they need everything
running, and when one fails, the cause can be anywhere. A few, for the paths that matter most, ticking
a session or adding one, cover what the levels below cannot.

## On counting

`ng test --coverage` reports which lines the tests ran. It needs one more package, and says so:

```
ana@dev:~/planner$ npx ng test --watch=false --coverage 2>&1 | tail -3
The following packages are required but were not found:
  - @vitest/coverage-v8
Please install the missing packages and rerun the test command.
```

Installed, at an exact version like everything else, it answers "what has no test at all", which is useful, and nothing else. A line that ran was not
necessarily checked: the CLI's "should create" ran every line of a constructor and asserted nothing
about any of them. Write the test that would catch the failure you can name, as this lesson did
with the Sunday and the refused `PATCH`, and let the number be what it comes to.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Tests: the arithmetic, the store against a fake server, a component and a harness"
```
