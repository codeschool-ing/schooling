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
