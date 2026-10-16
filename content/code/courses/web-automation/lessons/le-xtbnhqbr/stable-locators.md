---
title: "Locators that last: role, text and test id"
version: 1
---

**The locators that last are the ones that lean on what the test is about.** A test of a shop is
about what a customer meets: a heading that says Mango, a button that says Add to basket, a
message that says it was added. Those change when the page really changes, and then the test
ought to look again. Playwright builds its main locators around exactly that, and its
documentation recommends them ahead of CSS and XPath.

## Playwright's locators

| locator | finds | on the shop |
|---|---|---|
| `getByRole(role, { name })` | an element by its **role** and **accessible name**, what a screen reader announces | `getByRole('button', { name: 'Add to basket' })` |
| `getByLabel(text)` | a form field by the text of its label | the search page lesson 3 adds has a box labelled *Fruit* |
| `getByPlaceholder(text)` | a field by its placeholder | none on the shop |
| `getByText(text)` | an element by the text it shows | `getByText('Mango')` |
| `getByAltText(text)` | an image by its `alt` | none on the shop |
| `getByTestId(id)` | an element by its `data-testid` | `getByTestId('product-mango')` |

The role comes from the tag (`<button>`, `<h2>`, `<li>`) or from a `role` attribute, like the
shop's toast, which is a `<p role="status">`. The name of a button is its text. By default
`getByText` and the `name` of `getByRole` match **part** of the text and ignore case; `{ exact: true }`
makes them match the whole of it.

## A first attempt, and two failures

Three tests that use them. The third checks a price against the text a person would type. Save
it as `tests/locators.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/');
});

test('banana, by its test id', async ({ page }) => {
  const banana = page.getByTestId('product-banana');
  await expect(banana.getByRole('heading')).toHaveText('Banana');
});

test('add a mango, by role and name', async ({ page }) => {
  await page.getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByRole('status')).toHaveText('Added Mango');
});

test('a price, and the space nobody can see', async ({ page }) => {
  const price = page.getByTestId('product-banana').getByText('R$');
  await expect(price).toHaveText('R$ 5,90 / dozen');
  expect(await price.textContent()).toBe('R$ 5,90 / dozen');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/locators.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/locators.spec.js:7:1 › banana, by its test id (241ms)
  ✘  2 tests/locators.spec.js:12:1 › add a mango, by role and name (201ms)
  ✘  3 tests/locators.spec.js:17:1 › a price, and the space nobody can see (210ms)


  1) tests/locators.spec.js:12:1 › add a mango, by role and name ───────────────────────────────────

    Error: locator.click: Error: strict mode violation: getByRole('button', { name: 'Add to basket' }) resolved to 8 elements:
        1) <button type="button">Add to basket</button> aka getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })
        2) <button type="button">Add to basket</button> aka getByTestId('product-mango').getByRole('button', { name: 'Add to basket' })
        3) <button type="button">Add to basket</button> aka getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })
        4) <button type="button">Add to basket</button> aka getByTestId('product-guava').getByRole('button', { name: 'Add to basket' })
        5) <button type="button">Add to basket</button> aka getByTestId('product-cashew').getByRole('button', { name: 'Add to basket' })
        6) <button type="button">Add to basket</button> aka getByTestId('product-passion').getByRole('button', { name: 'Add to basket' })
        7) <button type="button">Add to basket</button> aka locator('#card-9158 > button')
        8) <button type="button">Add to basket</button> aka locator('#card-7101 > button')

    Call log:
      - waiting for getByRole('button', { name: 'Add to basket' })


      11 |
      12 | test('add a mango, by role and name', async ({ page }) => {
    > 13 |   await page.getByRole('button', { name: 'Add to basket' }).click();
         |                                                             ^
      14 |   await expect(page.getByRole('status')).toHaveText('Added Mango');
      15 | });
      16 |
        at /home/ana/quitanda/tests/locators.spec.js:13:61

    Error Context: test-results/locators-add-a-mango-by-role-and-name/error-context.md

  2) tests/locators.spec.js:17:1 › a price, and the space nobody can see ───────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: "R$ 5,90 / dozen"
    Received: "R$ 5,90 / dozen"

      18 |   const price = page.getByTestId('product-banana').getByText('R$');
      19 |   await expect(price).toHaveText('R$ 5,90 / dozen');
    > 20 |   expect(await price.textContent()).toBe('R$ 5,90 / dozen');
         |                                     ^
      21 | });
      22 |
        at /home/ana/quitanda/tests/locators.spec.js:20:37

    Error Context: test-results/locators-a-price-and-the-space-nobody-can-see/error-context.md

  2 failed
    tests/locators.spec.js:12:1 › add a mango, by role and name ────────────────────────────────────
    tests/locators.spec.js:17:1 › a price, and the space nobody can see ────────────────────────────
  1 passed (3.0s)
```

**The second test is Playwright refusing to guess.** Eight buttons are called *Add to basket*,
and the test said click, which is an action on one element. Playwright calls this a **strict
mode violation**: an action, or an assertion about one element, on a locator that matches more
than one, fails at once instead of picking the first. That is the defence against the quiet
failure at the end of the previous section. Read the list it prints, too. For each match it
suggests a locator that would find that one alone, and most of them chain the card's test id to
the button's role. Look at the last ones: where it found nothing better to offer, it offered the
card's random `id`, the flaw the previous section ran into. **A tool's suggestion is a starting
point, not a verdict**, and that one would fail on the next load.

**The third test failed on a comparison, not on a locator.** Its first line passed:
`toHaveText` treats any run of whitespace as one space before comparing, and the non-breaking
space counts as whitespace. Its second line read the text and compared it with `toBe`, which
compares characters. The two strings in the message look identical, and differ in one character
you cannot see.

## Narrowing, chaining and filtering

A locator can start from another one. `page.getByTestId('product-mango').getByRole('button')` is
the button inside that card; `filter({ hasText: 'Mango' })` keeps only the matches that contain
the text. This version finds the card the way a customer does, the list item that says Mango, then
the button inside it, and writes the price with the character it really has, `\u00a0`. Save it as
`tests/locators.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/');
});

test('banana, by its test id', async ({ page }) => {
  const banana = page.getByTestId('product-banana');
  await expect(banana.getByRole('heading')).toHaveText('Banana');
});

test('add a mango, by role and name', async ({ page }) => {
  const mango = page.getByRole('listitem').filter({ hasText: 'Mango' });
  await mango.getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByRole('status')).toHaveText('Added Mango');
});

test('a price, and the space nobody can see', async ({ page }) => {
  const price = page.getByTestId('product-banana').getByText('R$');
  await expect(price).toHaveText('R$ 5,90 / dozen');
  expect(await price.textContent()).toBe('R$\u00a05,90 / dozen');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/locators.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/locators.spec.js:7:1 › banana, by its test id (202ms)
  ✓  2 tests/locators.spec.js:12:1 › add a mango, by role and name (215ms)
  ✓  3 tests/locators.spec.js:18:1 › a price, and the space nobody can see (131ms)

  3 passed (2.1s)
```

## A ranking, and its reasons

| | locator | breaks when | what it asserts on the way |
|---|---|---|---|
| 1 | role and name | what a customer meets changes | that the element is announced as what it is |
| 2 | label, placeholder, alt text | a form or an image is reworded | the same, for fields and images |
| 3 | visible text | the words change: an edit, a translation | that the words are there |
| 4 | test id | somebody removes the attribute | nothing a customer sees |
| 5 | CSS on structure or styling classes | a redesign | nothing a customer sees |
| 6 | XPath by position or from the root | almost any change | nothing a customer sees |
| — | generated `id` or class | the next load, or the next build | nothing at all |

**The top of the list is where teams disagree.** A test id does not change by accident: it means
nothing to a designer or a translator, and it survives the day the shop is translated into
Portuguese, when every role name on the page changes. That is also its weakness. If the button lost
its text, `getByTestId('product-mango').locator('button')` would still click it and pass, while a test
that asks for the role and the name *Add to basket* would fail, and that failure is a real defect
for a customer using a screen reader; `non-functional-testing` lessons 12 to 15 are about that kind of testing. The ordering here puts
what the customer meets first, and uses the test id where the customer's words do not pick out
one element: eight cards with the same button are the shop's example.
