---
title: Choosing the layer a check runs at
version: 1
---

The products on `/ssr` are in the HTML, and that changes which tool is cheapest for checking them.
A browser test starts a browser, loads the page and everything it asks for, runs its scripts and
waits. An HTTP request sends one request and reads one answer. **When what you want to know is
already in the HTML, the request is enough**, and a check that needs no browser is faster and has
fewer ways to fail for reasons that have nothing to do with the page.

## A test with no browser

Playwright's `request` fixture is an HTTP client that already knows the config's `baseURL`. A
test that asks only for `request`, and never for `page`, opens no page at all. The first test
below asks the shop's API for its products and checks that every one of them is in the HTML of
`/ssr`, so a product added to the store and left out of the page fails it. The second asks the same
of `/`. Save it as `tests/ssr-html.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// No page and no browser: only the request fixture, which speaks HTTP.
test('the HTML of /ssr names every product the API lists', async ({ request }) => {
  const products = await (await request.get('/api/products')).json();
  const html = await (await request.get('/ssr')).text();
  for (const product of products) {
    expect(html).toContain(`<h2>${product.name}</h2>`);
  }
});

test('the HTML of / names none of them', async ({ request }) => {
  const html = await (await request.get('/')).text();
  expect(html).not.toContain('<h2>');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr-html.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/ssr-html.spec.js:4:1 › the HTML of /ssr names every product the API lists (50ms)
  ✓  2 tests/ssr-html.spec.js:12:1 › the HTML of / names none of them (15ms)

  2 passed (1.2s)
```

Both pass, in 50 ms and 15 ms, against 121 ms and 103 ms for the two tests of the previous section,
which each opened a page and ran nothing on it. On a page this small the gap is a few dozen
milliseconds; what a request also saves is every way a browser test can fail on its own account.

The second test shows the limit of this layer. The HTML of `/` holds nothing to check, so the
question "are the products on the home page" has no answer without a browser that runs `app.js`,
which is what the smoke test of lesson 1 does.

## What each layer can see

| what you want to know | an HTTP request | a browser |
|---|---|---|
| are the products in what `/ssr` sends | yes | yes |
| are the products on `/` | no, they are not in the HTML | yes, once `app.js` has run |
| does Add to basket work | no | yes, once the page is ready |
| does `/ssr` list its products with no script | yes, the HTML is the answer | yes, with `javaScriptEnabled: false` |

**The cheaper layer has a blind spot that matters in this lesson.** The HTML of `/ssr` was right
all along, including during the second and a half when its buttons did nothing. An HTTP test
passes on the page whose test failed five times out of five, because the defect is in what
happens after the HTML arrives. So a server-rendered page wants both: a fast check that the server
writes the right content, and a browser test for the moment the page becomes usable.

All three files of this lesson, together:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/no-script.spec.js tests/ssr-html.spec.js

Running 5 tests using 2 workers

  ✓  2 tests/ssr-html.spec.js:4:1 › the HTML of /ssr names every product the API lists (63ms)
  ✓  3 tests/ssr-html.spec.js:12:1 › the HTML of / names none of them (32ms)
  ✓  1 tests/no-script.spec.js:6:1 › /ssr lists its eight products without a script (174ms)
  ✓  5 tests/no-script.spec.js:13:1 › / lists nothing without a script (105ms)
  ✓  4 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.0s)

  5 passed (3.6s)
```

Five tests on two workers. The one that waits for the page took 2.0 s, and each of the other four
took between 32 ms and 174 ms.

The rule underneath this section, checking each thing at the cheapest layer that can see it and
keeping the browser for what only a browser can see, is the testing pyramid of lesson 21, and
`testing-cicd` lesson 1 names the layers. Tests that speak only HTTP are the subject of the next
course, `api-mobile-automation`.
