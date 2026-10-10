---
title: One document, many addresses
version: 1
---

A **single-page application**, a SPA, loads one HTML document and never loads another. Every
screen after the first is drawn by JavaScript inside that document, and the address bar is changed
by the script as well, so the browser's back button and a bookmark still work. Gmail, Trello and the
admin screens of most web products work this way, and the frameworks behind them, React, Vue,
Angular and Svelte among them, are mostly ways of organising that drawing.

The common belief is that a SPA is just a page with a lot of JavaScript. The shop's first page
already has a script that fetches the products, and it is not a SPA. **What makes one is the
navigation**: clicking a link does not ask the server for a page. For a test that changes two
things at once, what it waits for and what it can ask the server about, and this section is about
the first.

## The app

Quitanda has a small one at `/spa/`, with two views: the fruit and the basket. The HTML is a header
with two links and an empty `<main>`. Save it as `app/public/spa/index.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Quitanda app</title>
  <link rel="stylesheet" href="/style.css">
  <link rel="manifest" href="/spa/manifest.json">
</head>
<body>
  <header>
    <a class="brand" href="/spa/">Quitanda app</a>
    <nav>
      <a href="/spa/">Fruit</a>
      <a href="/spa/basket">Basket</a>
    </nav>
  </header>
  <main id="view"></main>
  <script src="/spa/spa.js"></script>
</body>
</html>
```

The script. `pages` maps each address to a function that fetches what that view needs and draws
it into `#view`, which carries `aria-busy="true"` while it does. The click handler is the whole
trick: it cancels the link's ordinary navigation, calls `history.pushState` to put the new address
in the bar, and draws the view itself. Save it as `app/public/spa/spa.js`:

```javascript
// One HTML page, and the address bar changed by JavaScript rather than by
// loading another page.
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const view = document.querySelector('#view');

const pages = {
  '/spa/': async () => {
    const products = await (await fetch('/api/products')).json();
    view.innerHTML = '<h1>Fruit</h1><ul></ul>';
    view.querySelector('ul').append(...products.map((p) => {
      const li = document.createElement('li');
      li.textContent = `${p.name}, ${money.format(p.price / 100)}`;
      return li;
    }));
  },
  '/spa/basket': async () => {
    const basket = await (await fetch('/api/basket')).json();
    view.innerHTML = `<h1>Basket</h1><p>Total: ${money.format(basket.total / 100)}</p>`;
  },
};

async function show(path) {
  view.setAttribute('aria-busy', 'true');
  await (pages[path] ?? (() => { view.innerHTML = '<h1>Not found</h1>'; }))();
  view.setAttribute('aria-busy', 'false');
  document.title = view.querySelector('h1').textContent + ' · Quitanda app';
}

document.addEventListener('click', (event) => {
  const link = event.target.closest('a');
  if (!link || !link.pathname.startsWith('/spa/')) return;
  event.preventDefault();
  history.pushState(null, '', link.pathname);
  show(link.pathname);
});
window.addEventListener('popstate', () => show(location.pathname));

show(location.pathname);
if ('serviceWorker' in navigator) navigator.serviceWorker.register('/spa/sw.js');
```

Its last line registers a **service worker**, and the HTML names a **manifest**. Both are what
make this app a PWA, and the section on service workers, two tabs on, is about them; save them now
so the page finds them. Save it as `app/public/spa/manifest.json`:

```json
{
  "name": "Quitanda",
  "start_url": "/spa/",
  "display": "standalone",
  "background_color": "#fbfaf5",
  "theme_color": "#2f6f4e"
}
```

Save it as `app/public/spa/sw.js`:

```javascript
// The service worker that makes the app open with no network. It keeps a
// copy of the page, its script and its style, and answers from that copy
// before asking the server.
const SHELL = ['/spa/', '/spa/spa.js', '/style.css'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open('shell-v1').then((cache) => cache.addAll(SHELL)));
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.pathname.startsWith('/api/')) return;
  event.respondWith(caches.match(event.request).then((hit) => hit ?? fetch(event.request)));
});
```

## What a click asks the server for

Lesson 1's `look.mjs` printed every response while a page loaded. This script does the same for
the app and then clicks **Basket**, so you can see what one navigation inside a SPA costs. It keeps
the browser's profile in a folder called `.spa-profile` in the project, so that a second run is a
visitor coming back; delete the folder to be a new visitor again. Save it as `spa-look.mjs`:

```javascript
// Opens the single-page app, clicks Basket, and prints every response and
// who answered it. The browser's profile is kept in .spa-profile, so a second
// run is a visitor coming back. Run it with the shop started:
// node spa-look.mjs
import { chromium } from '@playwright/test';

const context = await chromium.launchPersistentContext('.spa-profile');
const page = context.pages()[0] ?? await context.newPage();
const start = Date.now();
const ms = () => String(Date.now() - start).padStart(5) + ' ms';

page.on('response', (response) => {
  const request = response.request();
  const who = response.fromServiceWorker() ? 'the service worker' : 'the server';
  const path = new URL(response.url()).pathname;
  console.log(`${ms()}  ${request.resourceType().padEnd(10)} ${path}  from ${who}`);
});

await page.goto('http://localhost:3000/spa/');
await page.locator('#view[aria-busy=false]').waitFor();
console.log(`${ms()}  heading: ${await page.locator('h1').textContent()}`);
await page.evaluate(() => navigator.serviceWorker.ready);
console.log(`${ms()}  service worker ready; click Basket`);
await page.getByRole('link', { name: 'Basket' }).click();
await page.getByRole('heading', { name: 'Basket' }).waitFor();
console.log(`${ms()}  heading: Basket, address: ${page.url()}`);
await context.close();
```

With the shop started in one terminal, the first run:

```
%%CAP spa-look-1%%
```

The first four lines are an ordinary page load: the document, the stylesheet and the script, then
the script's `fetch` for the products. **After the click there is one line, a `fetch`.** No
document, no stylesheet, no script: the address changed to `/spa/basket` and the browser asked the
server for nothing but the basket's data. In a multi-page site the same click asks for a new
document and everything it names, and the `load` event fires again when it has arrived.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Two columns. On the left, a page per address: click on Basket, a new document is asked for, HTML, CSS and script arrive, the load event, the basket is drawn. On the right, one page with many addresses: click on Basket, history.pushState, fetch of /api/basket, the view is redrawn. Beside pushState a note says the address changes and waitForURL returns; beside the last step a note says the Basket heading appears.\"><text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">A page per address</text><text x=\"370\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">One page, many addresses</text><rect x=\"20\" y=\"48\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"69\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">click on Basket</text><rect x=\"20\" y=\"98\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"36\" y=\"119\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a new document is asked for</text><rect x=\"20\" y=\"148\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"36\" y=\"169\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">HTML, CSS and script arrive</text><rect x=\"20\" y=\"198\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"219\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the load event</text><rect x=\"20\" y=\"248\" width=\"300\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"36\" y=\"269\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the basket is drawn</text><path d=\"M170 80 L170 98 M170 130 L170 148 M170 180 L170 198 M170 230 L170 248\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"370\" y=\"48\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"386\" y=\"69\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">click on Basket</text><rect x=\"370\" y=\"98\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"386\" y=\"119\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">history.pushState(…)</text><rect x=\"370\" y=\"148\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"386\" y=\"169\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">fetch('/api/basket')</text><rect x=\"370\" y=\"198\" width=\"230\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"386\" y=\"219\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the view is redrawn</text><path d=\"M485 80 L485 98 M485 130 L485 148 M485 180 L485 198\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M604 114 L614 114\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"618\" y=\"110\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the address changes;</text><text x=\"618\" y=\"126\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">waitForURL returns</text><path d=\"M604 214 L614 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"618\" y=\"210\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the Basket heading</text><text x=\"618\" y=\"226\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">appears</text></svg>", "caption": "The same click twice. On the right, the address is correct one request before the page is."}
```

## Waiting for the wrong thing

In a multi-page site, a test that clicks a link can wait for the next page's `load` event. **In a
SPA nothing loads.** The `load` event fired once, when `/spa/` opened, and `pushState` fires no
other, so `page.waitForLoadState()` after the click has nothing to wait for and returns at once.
The replacement people reach for is `page.waitForURL`, which waits until the address matches. It
does wait for something, but the figure shows what: the address changes in the click handler,
**before** the fetch for the basket has even been sent.

Here is a first attempt written that way, twice. The second test is the same as the first on a
slower network: `page.route` holds every request for `/api/basket` for half a second before
letting it through, which is what a phone on a weak signal does to it anyway. Save it as
`tests/spa.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('Basket opens the basket', async ({ page }) => {
  await page.goto('/spa/');
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  expect(await page.locator('h1').textContent()).toBe('Basket');
});

test('Basket opens the basket on a slow network', async ({ page }) => {
  await page.route('**/api/basket', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
  await page.goto('/spa/');
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  expect(await page.locator('h1').textContent()).toBe('Basket');
});
```

```
%%CAP naive%%
```

%%PROSE naive%%

**The address is a fact about the URL, and the heading is a fact about the page.** The fix is to
wait for the thing the test is about, with an assertion that retries until it holds. The version
below keeps `waitForURL`, because a SPA that forgot `pushState` would draw the basket at the wrong
address and that is worth catching, and then asserts on the heading. The first test also asserts on
`aria-busy`, and it listens for document requests after the first page has loaded and expects none.
Both wait for the fruit before clicking, so that two views are never loading at once; lesson 3 is
about what happens when two answers race. Save it as `tests/spa.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('Basket opens the basket without loading a page', async ({ page }) => {
  await page.goto('/spa/');
  await expect(page.getByRole('heading', { name: 'Fruit' })).toBeVisible();
  const documents = [];
  page.on('request', (request) => {
    if (request.resourceType() === 'document') documents.push(request.url());
  });

  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
  await expect(page.locator('#view')).toHaveAttribute('aria-busy', 'false');
  expect(documents).toEqual([]);
});

test('Basket opens the basket on a slow network', async ({ page }) => {
  await page.route('**/api/basket', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
  await page.goto('/spa/');
  await expect(page.getByRole('heading', { name: 'Fruit' })).toBeVisible();
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
});
```

```
%%CAP fixed%%
```

`toBeVisible` and `toHaveAttribute` are **web-first assertions**: they ask the page again until the
answer is right or the time runs out, five seconds by default. `expect(await …textContent())` asks
once and compares whatever came back. Lesson 13 is about waiting in general, and why the retrying
assertion is the one to reach for first; the point here is narrower. In a SPA, **the signal that
the page is ready is something on the page**, never the navigation.
