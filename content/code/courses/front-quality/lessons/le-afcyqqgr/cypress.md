---
title: The same journey in Cypress
version: 1
---

**Cypress is the other end-to-end tool you will meet, and it is built the other way round: instead of
driving the browser from outside, it runs inside it, next to your app.** The test and the page share
one browser tab. That gives Cypress its strengths, a window where you watch each step and travel back
through them, and its limits, such as one tab per test and one site per test unless you ask for more.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l04-where\" aria-label=\"Two arrangements side by side. Playwright: the test runs in Node, outside the browser, and sends commands over a connection to Chromium, where the planner runs in a tab of its own. Cypress: the browser holds both the test and the planner, side by side in one tab, and a Node process beside the browser serves the test and handles what the browser cannot, such as files.\"><defs><marker id=\"l04-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Playwright</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Cypress</text><rect x=\"20\" y=\"50\" width=\"120\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Node</text><rect x=\"32\" y=\"90\" width=\"96\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your test</text><rect x=\"200\" y=\"50\" width=\"150\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Chromium</text><rect x=\"212\" y=\"90\" width=\"126\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a tab: the planner</text><path d=\"M128 110 L212 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-where-ah-paper-dim)\"></path><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">commands over a connection</text><rect x=\"400\" y=\"40\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the browser, one tab</text><rect x=\"420\" y=\"80\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your test</text><rect x=\"560\" y=\"80\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the planner</text><path d=\"M540 105 L560 105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-where-ah-paper-dim)\" marker-start=\"url(#l04-where-ah-paper-dim)\"></path><rect x=\"450\" y=\"180\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Node: serves the test,</text><text x=\"550.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">reads files, the network</text><path d=\"M550 160 L550 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-where-ah-paper-dim)\" marker-start=\"url(#l04-where-ah-paper-dim)\"></path></svg>", "caption": "Outside or inside. Playwright's test can open tabs and browsers at will; Cypress's test sits beside the page and sees it directly."}
```

*Nothing in this section was run.* Cypress downloads its own application the first time it is
installed, from Cypress's servers, and the machine this course was recorded on was not allowed to
reach them. What follows is written from Cypress's documentation for version 16, and the transcripts
are absent rather than invented. To try it, install it the way the documentation says, in a copy of
the planner rather than in the planner itself, for the same reason the Jest copy of lesson 2 was
separate:

```sh
npm install --save-exact -D cypress@16.2.0
```

The configuration names the address, like Playwright's `baseURL`:

```typescript
// cypress.config.ts
import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    baseUrl: "http://localhost:5173",
  },
});
```

And the second Playwright test, as Cypress writes it, in `cypress/e2e/planner.cy.ts`:

```typescript
// cypress/e2e/planner.cy.ts
describe("the planner", () => {
  beforeEach(() => {
    cy.clock(new Date("2026-10-21T10:00:00-03:00").getTime(), ["Date"]);
  });

  it("a session added to a course counts in its week", () => {
    cy.visit("/");
    cy.contains("a", "JavaScript").click();
    cy.contains("label", "Date").find("input").type("2026-10-23");
    cy.contains("label", "Minutes").find("input").type("15");
    cy.contains("button", "Add session").click();
    cy.contains("This week: 105 min").should("be.visible");
  });
});
```

## Reading one beside the other

| | Playwright | Cypress |
|---|---|---|
| where the test runs | in Node, driving the browser | inside the browser, beside the page |
| how a step is written | `await page.getByLabel("Minutes").fill("15")` | `cy.contains("label", "Minutes").find("input").type("15")`, a chain with no `await` |
| waiting | web-first assertions retry, `await expect(…)` | every command and `.should(…)` retries |
| the network | `page.route` | `cy.intercept` |
| the clock | `page.clock` | `cy.clock` |
| starting the app | `webServer` in the configuration | started by you, or by a package such as `start-server-and-test` |
| browsers | Chromium, Firefox and WebKit | Chrome-family browsers and Firefox; WebKit is experimental |

**The habits are the same**: find elements by what a person reads, let the tool retry rather than
pausing, fake the network only to reach a state. Cypress's own queries are by text and selector, and
`@testing-library/cypress` adds the role and label queries of lesson 3 to it. Choose the tool the
project already has; a team that knows one learns the other in a day.
