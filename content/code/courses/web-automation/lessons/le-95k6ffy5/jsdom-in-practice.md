---
title: jsdom, run against the shop
version: 1
---

**jsdom is the DOM and the HTML standard, implemented in JavaScript for Node.** No browser is
behind it. It is the one simulated browser in wide use today, and most people run it second-hand:
Jest's `jsdom` test environment is a package, `jest-environment-jsdom`, built on it.

```
%%CAP jest-env%%
```

So a Jest user today runs jsdom 26, whatever version is newest. This section installs jsdom itself,
at 30.1.2, and points it at the shop.

## Installing it

The project's `package.json` gains one line. Save it as `package.json`:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "cypress": "16.1.1",
    "jsdom": "30.1.2",
    "puppeteer": "25.13.0",
    "selenium-webdriver": "4.51.0"
  }
}
```

```
%%CAP npm-install%%
```

**Read the warnings before the last line.** jsdom 30.1.2 declares which versions of Node it
supports, and the Node of lesson 1 is just below them:

```
%%CAP jsdom-engines%%
```

22.22.0 is two patch releases short of 22.22.2. npm warns and installs anyway, and everything in
this lesson ran on 22.22.0 without an error from jsdom. A warning like this one is still a claim by
the authors that they no longer test your combination, so on your own machine the fix is to update
Node within the 22 line.

## The home page, as a browser would open it

Make a folder `simulated` for this lesson's scripts. The first one opens the home page, waits a
second for `app.js`, and counts the cards. Save it as `simulated/home.mjs`:

```javascript
// The shop's home page in jsdom: no browser, only Node.
import { JSDOM } from 'jsdom';

const dom = await JSDOM.fromURL('http://localhost:3000/', {
  runScripts: 'dangerously',
  resources: 'usable',
});
const { document } = dom.window;

await new Promise((resolve) => setTimeout(resolve, 1000));
console.log(`cards: ${document.querySelectorAll('#products li').length}`);
dom.window.close();
```

**Both options are off by default, and their names are a warning.** By default jsdom parses the
HTML and does nothing else: no `<script>` runs and nothing linked from the page is fetched.

- `runScripts: 'dangerously'` runs the page's scripts. jsdom's README explains the adverb: its
  sandbox "is not foolproof", and a script that tries hard enough can reach Node, and from Node the
  rest of your machine. A real browser keeps a page away from your files; jsdom cannot promise to.
  It is safe here because the page is your own shop on `localhost`. Pointed at a page somebody
  else controls, it is running their code with your permissions.
- `resources: 'usable'` lets jsdom fetch what the page links to: scripts in `<script src>`,
  stylesheets in `<link rel="stylesheet">`, frames. Without it, `app.js` is never even
  downloaded. Images need an extra package, `canvas`, which this lesson does not install.

`fromURL` fetches the page and tells jsdom its address, so that `/app.js` and `/style.css` resolve
against `http://localhost:3000`. With the shop running:

```
%%CAP home-bare%%
```

**jsdom 30.1.2 has no `fetch`.** Node 22 has one, and every script in this course has used it; the
window jsdom builds for the page does not, so the first line of `getJson` throws. The program then
ends, and that part is Node's doing: `load()` is an `async` function, its failure became a rejected
promise nobody handled, and Node stops a program with an unhandled rejection. A browser would have
logged the error in the console of lesson 1 and gone on drawing an empty shop.

## Lending the page a fetch

jsdom's README suggests the way round it: an option called `beforeParse`, a function that receives
the window before the page's scripts run, "for example adding shims for web platform APIs jsdom does
not support". A **shim** is a stand-in you write for a missing API. This one passes the page's
requests to Node's `fetch`, after turning a relative address like `/api/products` into a full one.
Every script from here on opens the shop the same way, so it goes in a module of its own, with a
small wait beside it. Save it as `simulated/shop.mjs`:

```javascript
// Open a page of the shop in jsdom: the HTML parsed, its scripts run,
// and nothing drawn.
import { JSDOM } from 'jsdom';

export const address = 'http://localhost:3000';

export async function open(path) {
  const dom = await JSDOM.fromURL(address + path, {
    runScripts: 'dangerously',
    resources: 'usable',
    // jsdom has no fetch, and app.js needs one: lend the page Node's.
    beforeParse(window) {
      window.fetch = (url, init) => fetch(new URL(url, window.location.href), init);
    },
  });
  return dom.window;
}

// Check fn every 20 ms until it returns true, for at most five seconds.
export async function until(fn) {
  const deadline = Date.now() + 5000;
  while (!fn()) {
    if (Date.now() > deadline) throw new Error('until: still false after 5 s');
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
}
```

**`until` is a wait written by hand**, like Puppeteer's in lesson 11: jsdom has no auto-waiting,
because it has no idea what you are about to check. The home page uses it twice, for the list to
stop being busy and for the count to change after a click. Save it as `simulated/home.mjs`:

```javascript
// The shop's home page in jsdom, with a fetch to draw the cards.
import { address, open, until } from './shop.mjs';

await fetch(address + '/api/reset', { method: 'POST' });
const window = await open('/');
const { document } = window;

const list = document.querySelector('#products');
await until(() => list.getAttribute('aria-busy') === 'false');
console.log(`cards: ${list.children.length}`);

document.querySelector('[data-testid=product-banana] button').click();
const count = document.querySelector('[data-testid=basket-count]');
await until(() => count.textContent === '1');
console.log(`basket: ${count.textContent}, toast: ${document.querySelector('.toast').textContent}`);
window.close();
```

```
%%CAP home%%
```

**Eight cards, a banana in the basket and the toast's text**, from the same `app.js` Chromium runs.
The click ran the button's listener, which sent `POST /api/basket` through the shim and wrote the
answer into the header.

Notice what the shim changed. The requests no longer go through anything jsdom wrote: Node's
`fetch` sends them, with no cookies from the page and none of the rules a browser applies between
one site and another. **A check that passes through a shim has tested the shim**, which is fine
for counting cards and wrong for anything about how a browser makes requests. The next section
asks jsdom what it cannot answer at all.
