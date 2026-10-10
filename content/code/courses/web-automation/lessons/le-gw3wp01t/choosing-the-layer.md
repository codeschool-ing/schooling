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
%%CAP ssr-html%%
```

HTML_SENTENCE

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
%%CAP all%%
```

ALL_SENTENCE

The rule underneath this section, checking each thing at the cheapest layer that can see it and
keeping the browser for what only a browser can see, is the testing pyramid of lesson 21, and
`testing-cicd` lesson 1 names the layers. Tests that speak only HTTP are the subject of the next
course, `api-mobile-automation`.
