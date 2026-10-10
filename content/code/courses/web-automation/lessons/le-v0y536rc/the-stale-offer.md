---
title: The offer that does not change
version: 1
---

The shop gets a page with one line on it, **today's offer**: a fruit and a price, which somebody at
the shop changes during the day. The flaw is in one header. The server tells the browser it may keep
the offer for ten minutes **without asking**, so a customer who opened the page before the change
goes on seeing the old price after it, and nothing on their screen says so.

## The route and the page

Two routes. `GET /api/offer` answers with the offer's name and price, in cents, and the
`Cache-Control` header marked as the flaw; `POST /api/offer` sets a new one from a product id and a
price. `reset()` in `app/store.js` already puts the offer back to a mango at 390. Save it as
`app/routes/offer.js`:

```javascript
import { send } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/offer',
    handle: ({ res }) => {
      const product = store.products.find((p) => p.id === store.offer.id);
      // A known flaw, on purpose: the browser may keep this answer for ten
      // minutes without asking again, so a new offer goes unseen.
      send(res, 200, { name: product.name, price: store.offer.price },
        { 'Cache-Control': 'max-age=600' });
    },
  },
  {
    method: 'POST', path: '/api/offer',
    handle: ({ res, body }) => {
      store.offer = { id: body.id, price: body.price };
      send(res, 200, store.offer);
    },
  },
];
```

The page asks for the offer once it has loaded and writes it into the paragraph, with the price
formatted the way the shop's front page does it. Save it as `app/public/offer.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Offer · Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Today's offer</h1>
    <p id="offer">…</p>
  </main>
  <script>
    const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
    fetch('/api/offer')
      .then((response) => response.json())
      .then((offer) => {
        document.querySelector('#offer').textContent =
          `${offer.name} for ${money.format(offer.price / 100)}`;
      });
  </script>
</body>
</html>
```

The server reads `app/routes/` when it starts, so **stop the shop and start it again** before
asking for the new route. Then, from a second terminal:

```
ana@laptop:~/quitanda$ curl -s -i http://localhost:3000/api/offer
HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: max-age=600
Date: Sat, 10 Oct 2026 19:37:12 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"name":"Mango","price":390}
```

`max-age=600` and no `ETag`: for ten minutes, a browser that has this answer has no reason to ask
again, and after that it has no fingerprint to ask with, so it fetches the whole thing.

## A returning customer, by script

This script plays a customer who comes back. It resets the shop, opens the offer page, changes the
offer through the API the way somebody at the shop would, then opens the same page again in the
same browser and reloads it. On the way it prints every response the browser reports, like
`look.mjs` in lesson 1. Save it as `stale.mjs`:

```javascript
// A returning customer: one browser, the offer page opened twice, and a
// new offer set through the API in between.
import { chromium } from '@playwright/test';

const shop = 'http://localhost:3000';
const post = (path, body) => fetch(shop + path, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});

await post('/api/reset', {});
const browser = await chromium.launch();
const page = await browser.newPage();
page.on('response', (r) => console.log('  browser got', r.status(), new URL(r.url()).pathname));

async function show() {
  const offer = page.locator('#offer', { hasNotText: '…' });
  console.log('the page says', await offer.textContent());
}

console.log('first visit');
await page.goto(shop + '/offer.html');
await show();

await post('/api/offer', { id: 'banana', price: 290 });
console.log('the offer is now banana, at 290');

console.log('second visit, same browser');
await page.goto(shop + '/offer.html');
await show();

console.log('reload');
await page.reload();
await show();

await browser.close();
```

Start the shop with its log on, as in lesson 1, and run the script from the other terminal:

```
ana@laptop:~/quitanda$ node stale.mjs
first visit
  browser got 200 /offer.html
  browser got 200 /style.css
  browser got 200 /api/offer
the page says Mango for R$ 3,90
the offer is now banana, at 290
second visit, same browser
  browser got 200 /offer.html
  browser got 304 /style.css
  browser got 200 /api/offer
the page says Mango for R$ 3,90
reload
  browser got 200 /offer.html
  browser got 304 /style.css
  browser got 200 /api/offer
the page says Mango for R$ 3,90
```

**Mango three times.** The offer changed between the first visit and the second, and the page never
showed it. Now the shop's terminal, which printed every request that reached it while the script
ran:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
POST /api/reset 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/offer 200
GET /offer.html 304
GET /style.css 304
GET /offer.html 304
GET /style.css 304
```

**One `GET /api/offer`, for three visits.** The browser listed the offer on every visit, with a `200`
each time, and two of those answers never left the browser: they came from the copy it kept on the
first visit. This is what lesson 1 meant by a request the browser lists and the server does not.
The page and its stylesheet carry `no-cache`, so the browser did ask about them again, and the
server answered `304` both times.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two timelines. Above, the server's offer: Mango at R$ 3,90 until a POST to /api/offer changes it to Banana at R$ 2,90. Below, what the page shows: the first visit asks the server and shows Mango; the second visit, after the change, is answered by the browser's copy and still shows Mango; a visit after 600 seconds asks the server again and shows Banana.\"><text x=\"20\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the server's offer</text><text x=\"20\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">what the page shows</text><rect x=\"150\" y=\"46\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"162\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Mango, R$ 3,90</text><rect x=\"380\" y=\"46\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"392\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Banana, R$ 2,90</text><path d=\"M380 36 L380 90\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></path><text x=\"384\" y=\"30\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">POST /api/offer</text><path d=\"M150 180 L700 180\" stroke=\"var(--wire)\"></path><path d=\"M190 176 L190 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M190 82 L185 92 L195 92 Z\" fill=\"var(--phosphor)\"></path><circle cx=\"190\" cy=\"180\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"196\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">first visit</text><text x=\"190\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Mango</text><rect x=\"410\" y=\"110\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"450\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the copy</text><path d=\"M450 176 L450 140\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M450 134 L445 144 L455 144 Z\" fill=\"var(--amber)\"></path><circle cx=\"450\" cy=\"180\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"456\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">second visit</text><text x=\"450\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">Mango</text><path d=\"M630 176 L630 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M630 82 L625 92 L635 92 Z\" fill=\"var(--phosphor)\"></path><circle cx=\"630\" cy=\"180\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"636\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">after 600 s</text><text x=\"630\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Banana</text><path d=\"M190 222 L190 232 M190 227 L600 227 M600 222 L600 232\" stroke=\"var(--amber)\"></path><text x=\"395\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">for 600 s the copy is used without asking</text></svg>", "caption": "The server changed its answer; the browser had been told it need not ask."}
```


Two details in that pair of transcripts are worth keeping.

**A status reported by the browser is not the server's answer.** For the offer, the browser said
`200` on visits the server never saw: a copy is reported with the status it was stored with. For the
page itself it said `200` where the server's log says `304`. Only `style.css` came through as the `304` it was. When the
question is *did this reach the server*, the server's own log is the evidence, and the browser's
list is not.

**Reloading did not help.** A reload asked the server about the page again, and the page's script
then asked for the offer, which the browser still had, fresh for ten minutes. A customer who
suspects the price and presses reload gets the same price back.

## Why this is a defect

The page is not broken in any way a screenshot shows. It shows a real offer, correctly formatted,
from the real server. **It is wrong for up to ten minutes after every change**, to every customer
who loaded it before the change, and right for everybody else. If the price at the till is the new
one, the customer was shown one price and charged another; `manual-testing` lesson 15 is about
writing that up so somebody can reproduce it, and the next section is about why your tests did not
find it first.
