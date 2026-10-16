---
title: Writing your own condition
version: 1
---

**A condition is a question with a yes or no answer, and the only rule is that it must be false
until the moment you mean and true from then on.** Lesson 3 put that as two questions: *is it true
when the page is finished, and is it false until then?* The ready-made conditions answer those two
for common cases, an element appearing, a text, a title. When the page signals its state some
other way, the condition has to be written by hand, and both tools let you pass a function where a
ready-made condition would go.

## Selenium: any function

`driver.wait` accepts a function and calls it every 200 ms until it returns something truthy, which
is also what the wait returns. Nothing obliges the function to look at an element, or even at the
browser. This test uses one of each kind. The first asks the page for its ready marker with
`executeScript`, which runs a line of JavaScript inside the page and hands back the result. The
second never touches the browser: it asks the shop's server whether the banana reached the basket.
The third argument is the message the `TimeoutError` will carry, which is worth writing, because a
function has no description of its own. Save it as `selenium/conditions.test.js`:

```javascript
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { Builder, By } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

const shop = 'http://localhost:3000';
let driver;

before(async () => {
  const options = new chrome.Options().addArguments('--headless=new');
  driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
});

after(async () => {
  await driver?.quit();
});

test('any function is a condition', async () => {
  await fetch(`${shop}/api/reset`, { method: 'POST' });
  await driver.get(`${shop}/ssr`);
  await driver.wait(
    async () => (await driver.executeScript('return document.body.dataset.ready')) === 'true',
    5000, 'the page never said it was ready');
  await driver.findElement(By.css('[data-testid=product-banana] button')).click();

  // This one never looks at the browser: it asks the server.
  const lines = await driver.wait(async () => {
    const basket = await (await fetch(`${shop}/api/basket`)).json();
    return basket.lines.length > 0 && basket.lines;
  }, 5000, 'the server never received the banana');
  assert.deepEqual(lines.map((line) => line.id), ['banana']);
});
```

Run both Selenium files of this lesson together. `node --test` runs each file in a process of its
own, at the same time unless told otherwise. Both files put a banana in the one shared basket, so
`--test-concurrency=1` runs them one after the other:

```
ana@laptop:~/quitanda$ node --test --test-concurrency=1 --test-reporter=tap selenium/ssr.test.js selenium/conditions.test.js
TAP version 13
# Subtest: any function is a condition
ok 1 - any function is a condition
  ---
  duration_ms: 2161.758516
  type: 'test'
  ...
# Subtest: a click on /ssr counts once the page is ready
ok 2 - a click on /ssr counts once the page is ready
  ---
  duration_ms: 2252.671398
  type: 'test'
  ...
1..2
# tests 2
# suites 0
# pass 2
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 4941.910359
```

## Playwright: three ways to pass a function

Playwright has a form for each place a condition can live.

- **`page.waitForFunction(fn)`** runs `fn` inside the page until it returns something truthy. It is
  the direct equivalent of the Selenium `executeScript` condition.
- **`expect.poll(fn)`** runs `fn` in the test, in Node, and applies an ordinary matcher to whatever
  it returns, again and again. It is the form for a value that is not on the page at all: a
  server's answer, a file, a log line.
- **`expect(fn).toPass()`** runs a whole block of checks until the block stops throwing. It is the
  form for checks that only mean something together.

The search page from lesson 3 needs the first. Its own signal, `aria-busy="false"`, is already true
before the first key is pressed, so a wait for it can be satisfied too early; the count line, on
the other hand, is empty until the first answer is drawn. **Together they make a condition that is
false until the search has answered and nothing is outstanding**, which is what `settled` below
says. Once a test has waited for a state that is final, a single read is honest, so the checks after
it read once, with `allTextContents()`, instead of retrying.

The second test types the word key by key and meets the defect lesson 3 reported, so it carries
the same `test.fail()` and the same sentence about deleting it. The last two use `expect.poll` to
ask the server, and `toPass` for the basket's count and total, which the shop changes in one step.
Save it as `tests/conditions.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

// Runs in the page. True once an answer has been drawn and none is
// outstanding: false before the first key, unlike aria-busy on its own.
const settled = () =>
  document.querySelector('#count').textContent !== ''
  && document.querySelector('#results').getAttribute('aria-busy') === 'false';

test('waitForFunction: filled, the search settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').fill('papaya');
  await page.waitForFunction(settled);
  expect(await page.locator('#results li').allTextContents()).toEqual(['Papaya']);
});

test('waitForFunction: typed, the search settles on papaya', async ({ page }) => {
  // The defect lesson 3 reported: the answer to "p" arrives last and
  // replaces the list. Delete this line when it is fixed.
  test.fail();
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await page.waitForFunction(settled);
  expect(await page.locator('#results li').allTextContents()).toEqual(['Papaya']);
});

test('expect.poll: the server has the banana from /ssr', async ({ page, request }) => {
  await page.goto('/ssr');
  await page.waitForFunction(() => document.body.dataset.ready === 'true');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect.poll(async () => {
    const basket = await (await request.get('/api/basket')).json();
    return basket.lines.map((line) => line.id);
  }).toEqual(['banana']);
});

test('toPass: the count and the total change together', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-mango').getByRole('button').click();
  await expect(async () => {
    expect(await page.getByTestId('basket-count').textContent()).toBe('1');
    expect(await page.locator('.basket-total').textContent()).toBe('R$ 4,50');
  }).toPass({ timeout: 5000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/conditions.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/conditions.spec.js:13:1 › waitForFunction: filled, the search settles on papaya (320ms)
  ✘  2 tests/conditions.spec.js:20:1 › waitForFunction: typed, the search settles on papaya (953ms)
  ✓  3 tests/conditions.spec.js:30:1 › expect.poll: the server has the banana from /ssr (1.7s)
  ✓  4 tests/conditions.spec.js:40:1 › toPass: the count and the total change together (224ms)

  4 passed (4.8s)
```

**The typed test failed in under a second, and that is the condition working.** In lesson 3 the
same defect took five seconds to report, because the assertion kept retrying a list that would
never change. Here the wait ended when the page had finished, and one read found the three fruit
at once. ` ` in the total is the non-breaking space lesson 1 found after `R$`.

Two details are easy to get wrong. **`toPass` has no timeout of its own**: its default, in the
installed code, is `0`, so without `{ timeout }` it retries until the whole test runs out of time.
And a block inside `toPass` should only read. One that clicks, inside a loop that repeats until it
passes, can click twice and pass on the second banana.
