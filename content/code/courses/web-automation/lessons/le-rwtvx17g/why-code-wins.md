---
title: One change, counted, and why code wins
version: 1
---

A suite is not written once. It is changed every time the application changes, and **what a
recording costs is mostly paid after it is made**. That can be counted. Take one change a copywriter
might ask for on any afternoon, the button's words from *Add to basket* to *Add to cart*, and count
what each version of the test has to change to follow it.

## The change

Edit `app/public/app.js` so the button says `Add to cart`. It is one line of the card's HTML:

```
ana@laptop:~/quitanda$ grep -n "Add to" app/public/app.js
22:    <button type="button">Add to cart</button>`;
```

Now count where the old words appear, in the recordings and in what lesson 12 wrote:

```
ana@laptop:~/quitanda$ grep -c "Add to basket" recorded/codegen.spec.js pages/product-card.js tests/page-object.spec.js tests/two-fruit.spec.js
recorded/codegen.spec.js:3
pages/product-card.js:1
tests/page-object.spec.js:0
tests/two-fruit.spec.js:0
```

**Three lines in the recording, one in the page object, none in either test file that uses it.**
The recording repeats the button's name in every step that clicks one, because each session was
recorded on its own and codegen writes the full locator every time. The page object says it once,
in `ProductCard`, and every test reaches the button through `addToBasket`.

Run both against the changed shop. The recordings, then lesson 12's tests and this lesson's together,
one worker for the shared basket:

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/codegen.spec.js | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✘  1 recorded/codegen.spec.js:3:1 › banana (30.0s)
  ✘  2 recorded/codegen.spec.js:9:1 › two fruit (30.0s)
  ✘  3 recorded/codegen.spec.js:16:1 › acerola (30.0s)
  3 failed
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js tests/two-fruit.spec.js --workers 1 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✘  1 tests/page-object.spec.js:3:1 › a banana goes into the basket (30.0s)
  ✘  2 tests/page-object.spec.js:8:1 › two fruit make two items (30.0s)
  ✘  3 tests/page-object.spec.js:15:1 › the total follows the price (30.0s)
  ✘  4 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (30.0s)
  4 failed
```

**Every test failed, on both sides, and that is fair.** The words a customer reads did change, so a
locator by role and name ought to look again; that is the trade lesson 2 made on purpose. The
difference is only in what the fix costs. On the hand-written side it is the one line in
`pages/product-card.js`:

```
ana@laptop:~/quitanda$ grep -n "Add to" pages/product-card.js
7:    this.addButton = root.getByRole('button', { name: 'Add to cart' });
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js tests/two-fruit.spec.js --workers 1 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✓  1 tests/page-object.spec.js:3:1 › a banana goes into the basket (266ms)
  ✓  2 tests/page-object.spec.js:8:1 › two fruit make two items (340ms)
  ✓  3 tests/page-object.spec.js:15:1 › the total follows the price (181ms)
  ✓  4 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (316ms)
  4 passed (2.8s)
```

Four tests followed one line. The recording needs its three lines found and edited by hand, and a
real suite of recordings holds the same click once per session that made it: fifty recorded flows
through the shop are fifty copies of the button's name. The same is true of the rest of this
course's project, which is worth seeing whole before you put the words back:

```
ana@laptop:~/quitanda$ grep -rc 'Add to basket' --include='*.js' --include='*.mjs' --exclude-dir=node_modules . | grep -v ':0$'
./recorded/codegen.spec.js:3
./cypress/e2e/shop.cy.js:2
./app/routes/ssr.js:1
./tests/banana.spec.js:1
./tests/waiting.spec.js:1
./tests/locators.spec.js:1
./tests/contexts.spec.js:1
./tests/basket-data.spec.js:1
./tests/ssr.spec.js:1
./evidence/ssr.spec.js:1
```

Tests from lessons 2, 6, 9, 10, 11, 15 and 16 name the button directly too, so a change of words
reaches each of them. That is not an argument against those tests: they were written to teach one
idea each, not to be maintained together. It is the measurement of what a page object is for. One
line in that list is not a test at all: `app/routes/ssr.js` draws the same button on lesson 6's
server-rendered page, so the copywriter's change is two edits in the shop as well, and this
experiment made only the one on `/`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 284\" role=\"img\" aria-label=\"One change at the top: the button's words go from Add to basket to Add to cart. On the left, the recording, recorded/codegen.spec.js: three of its lines name the button and are hit by the change, the banana line of test banana and the banana and mango lines of test two fruit; the fourth line, in test acerola, names a card id instead. Three lines to find and edit. On the right, the page object: one line, addButton in pages/product-card.js, is hit by the change, and four tests reach the button through it. One line; four tests follow it.\"><rect x=\"230\" y=\"14\" width=\"300\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"380\" y=\"39\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Add to basket  →  Add to cart</text><text x=\"190\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the recording</text><rect x=\"20\" y=\"96\" width=\"340\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">recorded/codegen.spec.js</text><rect x=\"40\" y=\"124\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"50\" y=\"138\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">test('banana')  · banana</text><rect x=\"40\" y=\"150\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"50\" y=\"164\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">test('two fruit') · banana</text><rect x=\"40\" y=\"176\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"50\" y=\"190\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">test('two fruit') · mango</text><rect x=\"40\" y=\"202\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"50\" y=\"216\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">test('acerola')  · #card-…</text><path d=\"M330 56 L250 122\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M250 122 L253.2 115.8 L256.7 120.0 Z\" fill=\"var(--amber)\"></path><path d=\"M330 56 L280 148\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M280 148 L280.7 141.0 L285.5 143.6 Z\" fill=\"var(--amber)\"></path><path d=\"M330 56 L310 174\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M310 174 L308.4 167.2 L313.8 168.1 Z\" fill=\"var(--amber)\"></path><text x=\"190\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3 lines to find and edit</text><text x=\"570\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the page object</text><rect x=\"420\" y=\"96\" width=\"320\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"430\" y=\"121\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">pages/product-card.js · addButton</text><path d=\"M430 56 L520 94\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M520 94 L513.0 94.0 L515.1 89.0 Z\" fill=\"var(--amber)\"></path><rect x=\"450\" y=\"146\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">two fruit make two items</text><path d=\"M435 136 L435 156 L450 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"170\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"184\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a banana goes into the basket</text><path d=\"M435 136 L435 180 L450 180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"194\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the total follows the price</text><path d=\"M435 136 L435 204 L450 204\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"218\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"232\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a banana and a mango make…</text><path d=\"M435 136 L435 228 L450 228\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"580\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 line; 4 tests follow it</text></svg>", "caption": "The same change, counted on both sides. A recording repeats a name once per click that used it; a page object says it once, and the tests ask for it."}
```

Put the words back in both files before going on: `Add to basket` in `app/public/app.js` and in
`pages/product-card.js`.

## Why code wins

The count is one reason of six. Each of the others is something the recording cannot hold, because
it is not a click.

- **Version control and review.** A test file travels in the same pull request as the change that
  needed it, and somebody reads the two together. A test in a vendor's account is edited somewhere
  else, by somebody else, at another time.
- **Abstraction.** `addToBasket('mango')` says what the step is for. When the page changes, one
  class changes, which is the count above.
- **Waits.** A web-first assertion waits for the thing the test cares about. A recording waits for
  nothing, or for a pause somebody added after a failure, which lesson 3 measured and lesson 13 takes
  apart.
- **Data.** The fixture empties the basket before each test. A recording starts from whatever the
  shop held, and the second codegen test failed on exactly that, then passed on it.
- **CI.** A file in the repository runs wherever the repository goes, the way `testing-cicd` lesson
  5 sets up. A recording needs its tool, or its vendor, on the other end.
- **Intent.** A test called `a banana and a mango make two items` tells the person reading the
  failure what broke. A test called `test` tells them where to start reading.

## When a recorder is the right tool

**Code wins for a test that has to live.** Some tests do not, and a recorder serves them well.

- **A throwaway reproduction.** A recording of the eleven clicks that crash the checkout, attached
  to a defect report, is a better report than a paragraph, as `manual-testing` lesson 15 would want.
  Nobody has to maintain it, because it is deleted with the defect.
- **A first smoke check by somebody who does not program.** A tester with no JavaScript can record
  the shop's five main paths in an afternoon and have a scheduled check running by evening. It will
  break, and that is fine as long as everybody knows it is a first step, not the suite.
- **Generating locators to edit.** Codegen and `pick.mjs` answer "what would Playwright call this?"
  faster than reading the page. Take the six good names, replace the two random ids and the total's
  text, and move them into a page object. Used like that, the recorder writes a first draft and you
  write the test.

Lesson 22 asks the larger question, which tests are worth automating at all. A recorder makes some
tests cheap to create, and creating them was never the expensive part.
