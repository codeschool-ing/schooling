---
title: What arrives before any script runs
version: 1
---

The shop's home page arrives empty. Lesson 1 showed it: the HTML holds a list with nothing in it,
and `app.js` asks the server for the products once the page has loaded and draws them itself. That
is **client-side rendering**, where the server sends a frame and the browser builds the content.
This lesson adds the same shop built the other way round. With **server-side rendering** the
server writes the products into the HTML before it sends it, so the document already says what is
for sale when it arrives.

The usual belief is that the two differ in speed and nothing else, so a test written against one
passes against the other. They break tests in different places, and this lesson is about where.

## The page, rendered on the server

The new route answers `/ssr` by building the whole list into a string and sending it, with the
prices formatted the way `app.js` formats them. The inline script at the foot of the page waits
for the `load` event and then adds a second script, `/slow/ssr.js`, which the server holds back
for a second and a half; the comment above that pause marks it as this lesson's flaw. Save it as
`app/routes/ssr.js`:

```javascript
import fs from 'node:fs/promises';
import path from 'node:path';
import { send, pause } from '../http.js';
import { store } from '../store.js';

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const script = path.join(import.meta.dirname, '..', 'public', 'ssr.js');

// The same shop, rendered on the server: the HTML arrives with the products
// already in it, and a script makes the buttons work once it has loaded.
function page() {
  const items = store.products.map((p) => `
      <li class="card" data-testid="product-${p.id}">
        <h2>${p.name}</h2>
        <p class="price">${money.format(p.price / 100)}</p>
        <button type="button" data-id="${p.id}">Add to basket</button>
      </li>`).join('');
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Quitanda, rendered on the server</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Fruit of the season</h1>
    <p>Basket: <span data-testid="basket-count">0</span> items</p>
    <ul id="products">${items}
    </ul>
  </main>
  <script>
    window.addEventListener('load', () => {
      const s = document.createElement('script');
      s.src = '/slow/ssr.js';
      document.body.append(s);
    });
  </script>
</body>
</html>`;
}

export const routes = [
  {
    method: 'GET', path: '/ssr',
    handle: ({ res }) => send(res, 200, page(), { 'Content-Type': 'text/html; charset=utf-8' }),
  },
  {
    method: 'GET', path: '/slow/ssr.js',
    handle: async ({ res }) => {
      // A known flaw, on purpose: the script that makes the buttons work
      // takes a second and a half to arrive.
      await pause(1500);
      send(res, 200, await fs.readFile(script, 'utf8'),
        { 'Content-Type': 'text/javascript; charset=utf-8' });
    },
  },
];
```

The server reads `app/routes/` only when it starts, so stop it with Ctrl+C and run `npm start`
again. Then open `http://localhost:3000/ssr` beside `http://localhost:3000/`. Both show the same
heading and the same eight cards, each with its button. The server-rendered page is plainer, with
a count of items and no header, total or toast, because it was written to show one difference and
leave the rest out.

## Asking without a browser

`curl` does the first thing a browser does, asking for the document, and nothing after it: it
runs no script. Count the product headings in what `/` sends:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/ | grep -c '<h2>'
0
```

None. Ask `/ssr` the same question and print the lines instead of counting them:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/ssr | grep '<h2>'
        <h2>Banana</h2>
        <h2>Mango</h2>
        <h2>Papaya</h2>
        <h2>Guava</h2>
        <h2>Cashew fruit</h2>
        <h2>Passion fruit</h2>
        <h2>Acerola</h2>
        <h2>Pineapple</h2>
```

All eight, in the order the store lists them, inside the document itself.

## What that means for a test

**The way a page is rendered decides which tools can see its content at all.** Anything that
speaks HTTP and runs no JavaScript sees eight products on `/ssr` and none on `/`: `curl`, a
script that fetches a page, and the `request` fixture Playwright gives a test, which the last
reading section of this lesson uses. On `/`, the products exist only after a browser has
fetched `app.js`, run it, and had its request to `/api/products` answered. That is why every test
of the home page in this course opens a browser, and why lesson 3 is about the moment a test looks
too early.

The server-rendered page moves that problem rather than removing it. The products are there from
the first byte, so a test that only reads them has nothing to wait for. A test that **uses** them,
by clicking a button, still depends on a script, and the next section shows what that costs.

## And for somebody on a slow phone

What a person sees while they wait is the other half. With client-side rendering, the frame of the
page appears and the list stays empty until the script has arrived, run, asked and drawn, and on a
slow phone each of those steps is slower. With server-side rendering the products are on screen
as soon as the HTML is, which is the main reason sites that care about their first seconds render
on the server.

The price is that the page **looks** ready before it **is** ready. A person sees a button, taps it,
and nothing happens, because the script that makes it work has not arrived yet. In this shop that
delay is the server's deliberate pause rather than a slow device, which makes it the same every
time and easy to study. Measuring how long a real page takes to become usable is
`non-functional-testing` lesson 10.
