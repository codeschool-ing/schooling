---
title: A first spec, and the queue behind it
version: 1
---

A Cypress test file is called a **spec**, and it has the shape Mocha gave to JavaScript tests before
Cypress existed: `describe` names a group, `it` names one test, and `beforeEach` runs before each of
them. Cypress bundles Mocha for the structure and Chai for the assertions. Every step inside a test
is a command on one global object, `cy`.

The spec below does what lesson 1's smoke test did, the heading and the eight products, and then
adds to the basket, which the smoke test never touched. Make the folder first, from the project:

```sh
mkdir -p cypress/e2e
```

Save it as `cypress/e2e/shop.cy.js`:

```schooling-example
{"language": "javascript", "file": "cypress/e2e/shop.cy.js", "parts": [{"code": "describe('the shop', () => {\n  beforeEach(() => {\n    cy.request('POST', '/api/reset');\n    cy.visit('/');\n  });", "note": "`describe`, `it` and `cy` are globals the runner provides, so the file imports nothing. `cy.request` asks the server for a reset from Cypress's Node side, not from the page; `cy.visit` then loads the shop into the application frame. Both run before every test, so each one starts from an empty basket."}, {"code": "\n  it('opens and lists its fruit', () => {\n    cy.contains('h1', 'Fruit of the season').should('be.visible');\n    cy.get('#products li').should('have.length', 8);\n  });", "note": "`cy.contains` finds an element by its text, here the one `h1` that says it. `cy.get` takes a CSS selector. Each `should` is retried with the query in front of it until it passes or four seconds go by."}, {"code": "\n  it('adds a banana to the basket', () => {\n    cy.get('[data-testid=product-banana]')\n      .contains('button', 'Add to basket')\n      .click();\n    cy.get('[data-testid=basket-count]').should('have.text', '1');\n    cy.get('.toast').should('have.text', 'Added Banana');\n  });", "note": "A chain narrows as it goes: the Banana card, then the button inside it whose text is *Add to basket*, then a click. The two checks after it wait for the request the click started to come back and redraw the header."}, {"code": "\n  it('counts one more than before', () => {\n    cy.get('[data-testid=basket-count]').then(($count) => {\n      const before = Number($count.text());\n      cy.get('[data-testid=product-mango]').contains('button', 'Add to basket').click();\n      cy.get('[data-testid=basket-count]').should('have.text', String(before + 1));\n    });\n  });\n});", "note": "To use a value from the page, take it inside `.then()`, which runs when the queue reaches it and hands over the element Cypress found, wrapped in jQuery. The commands written inside it join the queue at that point. The next section explains why the obvious version, without `.then()`, cannot work."}]}
```

**Every command in it was checked against the type definitions that ship with Cypress 16.1.1, and
none was run.** On your machine, with the shop started in another terminal, this runs the spec
headless in Electron and prints a summary:

```sh
npx cypress run --spec cypress/e2e/shop.cy.js
```

and `npx cypress open` opens the runner in a window, where you choose **E2E Testing**, a browser and
then the spec. On the machine these lessons come from, with no binary, the first command printed
this and stopped, before any test:

```
%%CAP cypress-run-missing%%
```

That is the same message `cypress verify` gave in the last section; it is all a run without the
binary produces.

## The command that has not happened yet

The misunderstanding everybody brings from ordinary JavaScript, or from Playwright, is that a line
like `cy.get(...)` finds an element and hands it back. So the first attempt to read the basket's
count looks like this:

```javascript
// This does not work: cy.get returns a chain, not the element.
const count = cy.get('[data-testid=basket-count]');
if (count.text() === '0') {
  cy.log('the basket is empty');
}
```

**A Cypress command does not run when you call it. It is added to a queue, and the call returns at
once.** Your test function runs from top to bottom in a moment, writing the list; only after it has
returned does Cypress take the first command off the queue and carry it out, then the next. So
`count` is not the element, and not a promise of one: it is the chain the next command will be
attached to. A chain has no `text()` method, so `count.text()` throws a `TypeError` while the
test function is still writing the list, before a single command has run.

`await` does not help either. Its documentation is explicit that commands are not promises, and an
`await` in front of one waits for nothing useful. The way to use a value from the page is the one
the spec's third test shows: `.then()`, whose function runs when the queue reaches it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Above, three commands, cy.visit, cy.get and should, each marked queued: calling them only adds them to a list. Below, a timeline of the queue running: the page loads, then the get and its assertion are tried six times while the list is empty, finding 0, and pass on the seventh try, finding 8. At the far end, a note that it would fail at 4 seconds.\"><text x=\"20\" y=\"28\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">1. Your function runs once, and returns. Nothing has happened yet.</text><rect x=\"20\" y=\"42\" width=\"210\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"32\" y=\"64\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cy.visit('/')</text><text x=\"32\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">queued</text><rect x=\"250\" y=\"42\" width=\"210\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"262\" y=\"64\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cy.get('#products li')</text><text x=\"262\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">queued</text><rect x=\"480\" y=\"42\" width=\"210\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"492\" y=\"64\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.should('have.length', 8)</text><text x=\"492\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">queued</text><text x=\"20\" y=\"140\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">2. Then Cypress runs the queue, one command at a time.</text><path d=\"M20 200 L700 200\" stroke=\"var(--wire)\"></path><rect x=\"20\" y=\"160\" width=\"120\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"30\" y=\"181\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">page loaded</text><rect x=\"160\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"178\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"204\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"222\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"248\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"266\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"292\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"310\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"336\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"354\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"380\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"398\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"424\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"442\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8</text><text x=\"160\" y=\"220\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">get and should, tried again</text><text x=\"424\" y=\"220\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">8 found: passes,</text><text x=\"424\" y=\"237\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">next command</text><text x=\"700\" y=\"181\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">or fails at 4 s</text></svg>", "caption": "The test function only writes the list. The waiting happens afterwards, inside the queue, while the list on the page is still empty."}
```

## Why the queue is worth it: a check that tries again

The queue is what lets Cypress retry. When it reaches `cy.get('#products li').should('have.length',
8)`, it looks for the items, tests the assertion, and if the assertion fails, **looks again and tests
again**, until it passes or the time allowed runs out. That time is `defaultCommandTimeout`, and
the type definitions give its default as 4000 milliseconds.

That matters on this shop because of the gap lesson 1 found in the Network panel: the page is on
screen, with an empty list, before `/api/products` has answered. A check that looked once, at the
wrong moment, would find nothing. This one finds nothing several times, then eight. Lesson 3 is
built around that gap, and lesson 13 compares this kind of waiting with the others.

Two details stop retrying from being magic:

- **Only the queries before an assertion are retried with it.** `cy.get`, `cy.contains` and
  `.find` are queries. An action such as `.click()` is not repeated: it waits until the element can
  be clicked, then clicks once. A test that clicks, fails and clicks again would add two bananas.
- **Retrying does not wait for a request.** It waits for the DOM to look right. When the thing you
  are waiting for is an answer from the server, the next section has a better tool.

Playwright's `expect(locator).toHaveCount(8)`, in lesson 1's smoke test, retries too. What is particular
to Cypress is that the retry is a property of the queue rather than of a special kind of assertion,
so every `should` behaves this way without being asked.
