---
title: With JavaScript switched off
version: 1
---

Some visits to a page run no script at all. A browser can have JavaScript switched off, and on a
bad connection the script can fail to arrive while the HTML did. Building a page that works first
as plain HTML and gets better when a script runs is called **progressive enhancement**, and
rendering on the server is what makes it possible: an empty list has nothing to enhance.

## A context with no JavaScript

Every Playwright test gets its own **browser context**, an isolated profile with its own cookies
and settings; lesson 10 explains contexts properly. One of those settings is
`javaScriptEnabled`, and `test.use` sets it for every test in a file, or in a `test.describe`
group when it is written inside one. Every page those tests open then runs no script, the inline
one included. Save it as `tests/no-script.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Every page in this file opens in a browser with JavaScript switched off.
test.use({ javaScriptEnabled: false });

test('/ssr lists its eight products without a script', async ({ page }) => {
  await page.goto('/ssr');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page.getByTestId('product-banana')).toContainText('Banana');
});

// A fact about the home page today, not a requirement anybody wrote.
test('/ lists nothing without a script', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(0);
  await expect(page.locator('#products')).toHaveAttribute('aria-busy', 'true');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/no-script.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/no-script.spec.js:6:1 › /ssr lists its eight products without a script (121ms)
  ✓  2 tests/no-script.spec.js:13:1 › / lists nothing without a script (103ms)

  2 passed (1.4s)
```

Both pass, and they say opposite things about the two pages. `/ssr` lists its eight products with
no script; `/` lists none, and its list still says `aria-busy="true"`, because nothing ever ran to
change it.

## What the first test proves

It proves that the **content** of `/ssr` survives without a script: a reader sees the eight
products and their prices. It does not prove that the page **works**. With JavaScript off, the
Add to basket buttons on `/ssr` do nothing for as long as the page is open, because the script that
gives them a handler never runs. A page built for progressive enhancement would put each button
inside a `<form>` that posts to the server, so that a click works with or without a script.
Quitanda does not do that, and the test is silent about it.

**A test proves what it asserts and nothing more**, and the name of the first test is chosen to
say exactly that: it lists products. A test called "the shop works without JavaScript" with the
same body would claim something nobody checked.

The fix from the previous section has a cost here too. With buttons sent disabled, a visit with no
script would show eight buttons that can never be pressed, which is honest, and no more useful than
before. Each kind of reader gets a different page, and a test for each kind is how a team finds out
what a change does to the others.

## What the second test is for

The second test records a fact rather than a requirement, and its comment says so. Nobody wants
the home page empty, but it is, and the test pins that down. The day the team decides the home
page must list its products without JavaScript, this is the test that fails first and gets turned
round. Without the comment, the next person to read it could take it for a requirement and defend
it.
