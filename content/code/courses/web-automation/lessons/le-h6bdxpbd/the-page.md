---
title: The page, and the first run
version: 1
---

The shop's one page is three files: the HTML the browser asks for first, the script that fills it
in, and the stylesheet. The page arrives **empty** — the list of products is not in the HTML — and
the script asks the server for them once the page has loaded. That is the ordinary shape of a
modern page, and it is the reason lesson 3 exists: a test that looks for a product the instant the
page opens can be faster than the request that brings it.

Save it as `app/public/index.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <header>
    <a class="brand" href="/">Quitanda</a>
    <button class="menu-toggle" type="button" aria-expanded="false">Menu</button>
    <nav>
      <a href="/">Shop</a>
      <a href="/search.html">Search</a>
    </nav>
    <p class="basket">Basket: <span data-testid="basket-count">0</span> items
      · <span class="basket-total">R$ 0,00</span></p>
  </header>
  <main>
    <h1>Fruit of the season</h1>
    <ul id="products" aria-busy="true"></ul>
    <p role="status" class="toast"></p>
  </main>
  <script src="/app.js"></script>
</body>
</html>
```

The script. It asks for the products, draws a card for each, and wires the **Add to basket**
button to a request that adds one and redraws the total. The toast that says *Added Banana*
disappears after two seconds, which lesson 13 has a use for. Save it as `app/public/app.js`:

```javascript
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

async function getJson(url, options) {
  const response = await fetch(url, options);
  return response.json();
}

function showBasket(basket) {
  const count = basket.lines.reduce((n, line) => n + line.qty, 0);
  document.querySelector('[data-testid=basket-count]').textContent = count;
  document.querySelector('.basket-total').textContent = money.format(basket.total / 100);
}

function card(product) {
  const li = document.createElement('li');
  li.className = 'card';
  // A known flaw, on purpose: the id changes every time the page loads.
  li.id = 'card-' + Math.floor(Math.random() * 10000);
  li.dataset.testid = 'product-' + product.id;
  li.innerHTML = `<h2>${product.name}</h2>
    <p class="price">${money.format(product.price / 100)} <small>/ ${product.unit}</small></p>
    <button type="button">Add to basket</button>`;
  li.querySelector('button').addEventListener('click', async () => {
    const basket = await getJson('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: product.id }),
    });
    showBasket(basket);
    const toast = document.querySelector('.toast');
    toast.textContent = `Added ${product.name}`;
    setTimeout(() => { toast.textContent = ''; }, 2000);
  });
  return li;
}

async function load() {
  const products = await getJson('/api/products');
  const list = document.querySelector('#products');
  list.append(...products.map(card));
  list.setAttribute('aria-busy', 'false');
  showBasket(await getJson('/api/basket'));
}

document.querySelector('.menu-toggle').addEventListener('click', (event) => {
  const open = event.target.getAttribute('aria-expanded') === 'true';
  event.target.setAttribute('aria-expanded', String(!open));
  document.querySelector('nav').classList.toggle('open', !open);
});

load();
```

Two of its lines are flaws a test will trip on. Each card gets an `id` drawn at random, so it is
different every time the page loads; lesson 2 is about why a test must never look for an element
by something like that. And the prices are written by `Intl.NumberFormat` for Brazil, which puts a
**non-breaking space** between `R$` and the number. It looks exactly like a space, and a test that
compares the text with an ordinary one fails for a reason nobody can see.

The stylesheet. The block at the bottom changes the layout for windows 600 pixels wide or
narrower, and the comment in the middle marks the flaw lesson 7 is about. Save it as
`app/public/style.css`:

```css
body { margin: 0; font-family: system-ui, sans-serif; color: #1d2b1f; background: #fbfaf5; }
header { display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; padding: 0.75rem 1rem; background: #2f6f4e; color: #fff; }
header a { color: #fff; }
.brand { font-weight: 700; font-size: 1.25rem; text-decoration: none; }
nav { display: flex; gap: 1rem; }
.menu-toggle { display: none; }
/* A known flaw, on purpose: this line refuses to wrap. */
.basket { margin: 0 0 0 auto; white-space: nowrap; min-width: 24rem; text-align: right; }
main { padding: 1rem; }
#products { list-style: none; padding: 0; display: grid; gap: 1rem; grid-template-columns: repeat(auto-fill, minmax(12rem, 1fr)); }
.card { background: #fff; border: 1px solid #c9d6c3; border-radius: 0.5rem; padding: 1rem; }
.card h2 { margin: 0 0 0.5rem; font-size: 1.1rem; }
.price { margin: 0 0 0.75rem; }
button { font: inherit; padding: 0.5rem 0.75rem; border-radius: 0.375rem; border: 1px solid #2f6f4e; background: #fff; color: #2f6f4e; cursor: pointer; }
.toast { min-height: 1.5rem; }

@media (max-width: 600px) {
  .menu-toggle { display: inline-block; margin-left: auto; }
  nav { display: none; width: 100%; flex-direction: column; }
  nav.open { display: flex; }
}
```

## Installing the tools

In the project folder, `npm install` reads `package.json` and puts Playwright in `node_modules`:

```
ana@laptop:~/quitanda$ npm install

added 3 packages, and audited 4 packages in 1s

found 0 vulnerabilities
```

That installed the **library**: the code that tells a browser what to do. The **browsers** are a
separate download, because each version of Playwright is built against particular builds of them.
This command fetches the Chromium build that Playwright 1.56.0 expects, about 920 MB unpacked, into
a cache folder in your home directory:

```sh
npx playwright install chromium
```

On Linux, Chromium also needs some system libraries a desktop usually has and a fresh machine may
not. If a run later complains about a missing `.so` file, `npx playwright install-deps chromium`
installs them with `sudo`. **The download was not run for these transcripts**: the machine they
come from cannot reach Playwright's download server, so the same Chromium build was copied into the
cache folder instead. Everything after this point ran against it.

## Starting the shop

```
ana@laptop:~/quitanda$ npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
```

The terminal is now busy: the server runs until you press **Ctrl+C**. Open
`http://localhost:3000` in your own browser and you see eight cards, an **Add to basket** button
on each, and the basket's total in the green bar. Add a banana and watch the total change.

The server answers anything that asks, not only browsers. From a second terminal, the basket as
JSON, after one banana:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/api/basket
{"lines":[{"id":"banana","qty":1}],"total":590}
```

and the reset, which empties it again:

```
ana@laptop:~/quitanda$ curl -s -X POST http://localhost:3000/api/reset
{"reset":true}
```

## The first test

One test proves that the lab works from end to end: Playwright starts the shop, opens Chromium,
loads the page, and checks that the heading is there and that eight products were drawn. Stop the
server with Ctrl+C first, because Playwright starts its own. Save it as `tests/smoke.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('the shop opens and lists its fruit', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Fruit of the season' })).toBeVisible();
  await expect(page.locator('#products li')).toHaveCount(8);
});
```

```
ana@laptop:~/quitanda$ npx playwright test

Running 1 test using 1 worker

  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (225ms)

  1 passed (1.4s)
```

**One passed, and the lab is ready.** You did not see a browser window: by default Playwright runs
the browser **headless**, drawing the page in memory with no window, which is faster and is what a
build server does. Add `--headed` to the command and a Chromium window opens, loads the shop and
closes when the test ends; the machine these transcripts come from has no screen, so that one was
not run here. Lesson 17 is about what changes between the two modes.
