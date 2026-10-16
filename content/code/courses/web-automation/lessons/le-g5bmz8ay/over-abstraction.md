---
title: When a page object hurts
version: 1
---

A page object is an abstraction, and an abstraction is paid for: every reader of a test has to
trust, or open, the method it calls. **It pays back when it hides something the test should not
care about, and costs when it hides something the test is about.** Four ways to get that wrong
turn up in almost every suite that adopted the pattern with enthusiasm.

## Wrappers named after the widget

```javascript
async clickAddButtonOnBananaCard() {
  await this.page.getByTestId('product-banana').getByRole('button').click();
}

getBasketCountSpan() {
  return this.page.getByTestId('basket-count');
}
```

Each of these is one line, and line count is not the problem: this lesson's `basketCount()` is
one line too. **The problem is the name.** `clickAddButtonOnBananaCard` describes the markup, so
it changes when the markup does, and the test that calls it still reads like a list of widgets.
Rename it to what the customer does, `addToBasket('banana')`, and the same line starts earning its
place. The question to ask of any method is whether its name would survive a redesign of the page.
A method that only renames a Playwright call, `click(locator)` around `locator.click()`, does not
pass that question; it is a second vocabulary for the same thing.

## The God object

One `AppPage` with methods for the shop, the search, the offer, the sign-up and the SPA, because
every test imports it anyway. After a year it has two hundred methods, three of them called
something like `addToBasket` with slightly different behaviour, and nobody dares remove one.
**A page object stands for a page, or a component for a part of one**; when a class needs a
table of contents, it is several classes. The shop's search page from lesson 3 gets a
`SearchPage` of its own, with a box and a list and nothing about baskets.

## Hidden waits and swallowed failures

```javascript
async addToBasket(id) {
  await this.product(id).add();
  await this.page.waitForTimeout(2000);   // let the toast go away
}

async isInBasket(id) {
  try {
    await expect(this.basketCount()).not.toHaveText('0', { timeout: 1000 });
    return true;
  } catch {
    return false;
  }
}
```

The first adds two seconds to every call, and every test pays them, including the ones that never
look at the toast. It was added for one test, and lesson 3 showed what a fixed sleep is worth: a
guess about time that is too long on a fast day and too short on a slow one. The second turns a
failure into a `false` the caller may never check, with a timeout nobody can see from the test.
**A page object may wait for what its own action needs, as `click()` already does; it should not
wait for what some test needed once, and it must not decide that a failure is not one.** Waits on
purpose are lesson 13's subject.

## Abstraction before duplication

The last mistake is timing. A page object written before there are tests to share it guesses at
which steps will repeat, and guesses wrong: it ends up with methods nobody calls and without the
one everybody needs. This lesson started from three tests that repeated themselves and moved only
what they repeated. **Let the duplication appear, then remove it**: a second copy is a signal, a
third is a decision.

## Beyond page objects

Page objects organise a suite around pages. Another pattern organises it around **people and
their goals**: the **Screenplay pattern**, where a test reads as an actor performing tasks, and
the tasks are made of interactions with the page. Serenity/JS is the best-known JavaScript
implementation. It solves the same duplication with more structure, and the trade, as always, is
more to learn and more to read. This course stays with page objects and components; recognise
the name when a team mentions it.
