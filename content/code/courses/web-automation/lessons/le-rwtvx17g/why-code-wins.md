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
%%CAP change%%
```

Now count where the old words appear, in the recordings and in what lesson 12 wrote:

```
%%CAP count%%
```

**Three lines in the recording, one in the page object, none in either test file that uses it.**
The recording repeats the button's name in every step that clicks one, because each session was
recorded on its own and codegen writes the full locator every time. The page object says it once,
in `ProductCard`, and every test reaches the button through `addToBasket`.

Run both against the changed shop. The recordings, then lesson 12's tests and this lesson's together,
one worker for the shared basket:

```
%%CAP after%%
```

**Every test failed, on both sides, and that is fair.** The words a customer reads did change, so a
locator by role and name ought to look again; that is the trade lesson 2 made on purpose. The
difference is only in what the fix costs. On the hand-written side it is the one line in
`pages/product-card.js`:

```
%%CAP fix%%
```

Four tests followed one line. The recording needs its three lines found and edited by hand, and a
real suite of recordings holds the same click once per session that made it: fifty recorded flows
through the shop are fifty copies of the button's name. The same is true of the rest of this
course's project, which is worth seeing whole before you put the words back:

```
%%CAP project%%
```

Tests from lessons 2, 6, 9, 10, 11, 15 and 16 name the button directly too, so a change of words
reaches each of them. That is not an argument against those tests: they were written to teach one
idea each, not to be maintained together. It is the measurement of what a page object is for. One
line in that list is not a test at all: `app/routes/ssr.js` draws the same button on lesson 6's
server-rendered page, so the copywriter's change is two edits in the shop as well, and this
experiment made only the one on `/`.

%%FIG fanout%%

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
  shop held, and the second codegen test failed on exactly that.
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
