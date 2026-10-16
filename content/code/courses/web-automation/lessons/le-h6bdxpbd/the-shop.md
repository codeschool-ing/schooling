---
title: Building the shop
version: 1
---

The application every lesson tests is **quitanda**, a small online greengrocer; a *quitanda* is
the fruit and vegetable stall on a Brazilian street corner. It lists eight fruits, takes them into
a basket and shows the total in reais. It is a Node program with no dependencies, written for this
course and small enough to read whole, and this section and the next build it.

**It has flaws, on purpose, and each one is marked in the code with the words *a known flaw, on
purpose*.** An application that never misbehaves teaches nothing about automation: the lessons on
locators, waiting, caching and flaky tests each need something that goes wrong in a particular
way, every time, so you can watch a test meet it. Lessons 3 to 7 add pages with the flaws those
lessons are about.

**And it resets.** Everything the shop knows lives in memory, and one request puts it back as it
started. That is what lets a test begin from a known state, and lesson 15 is about why that
matters more than it sounds.

**Copy each file with the button on its block** rather than retyping it. Every file below is
saved relative to the project folder.

## The folders

```sh
mkdir -p ~/quitanda/app/routes ~/quitanda/app/public ~/quitanda/tests
cd ~/quitanda
```

On Windows, in PowerShell, `mkdir` makes one folder at a time and creates the parents it needs:
run it once for each of the three paths.

## How the project is described

`package.json` is what npm reads. It names the project, says that its JavaScript files are
**ES modules** (the `import` syntax, which `javascript` lesson 9 covers), gives `npm start` and
`npm test` their meaning, and pins the one tool the tests use to an exact version, so that your
runs print what these lessons print. Save it as `package.json`:

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
    "@playwright/test": "1.56.0"
  }
}
```

The configuration Playwright reads when you run the tests. It looks for tests in `tests/`, lets a
test write `page.goto('/')` instead of the whole address, and starts the shop itself before
running anything, which saves you a terminal. Lesson 10 explains every option Playwright has; these
are the three this course needs first. Save it as `playwright.config.js`:

```javascript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  reporter: 'list',
  use: { baseURL: 'http://localhost:3000' },
  // Playwright starts the shop before the tests and stops it after.
  webServer: {
    command: 'npm start',
    url: 'http://localhost:3000/api/products',
    reuseExistingServer: !process.env.CI,
  },
});
```

## The server

Two small helpers every route uses: one sends an answer, the other waits for a number of
milliseconds, which is how the shop's slow pages are slow. Save it as `app/http.js`:

```javascript
// What every route needs to answer.
export function send(res, status, body, headers = {}) {
  const json = typeof body !== 'string';
  res.writeHead(status, {
    'Content-Type': json ? 'application/json' : 'text/plain; charset=utf-8',
    ...headers,
  });
  res.end(json ? JSON.stringify(body) : body);
}

export const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
```

Everything the shop knows, and the `reset()` that puts it back. Prices are **integers in cents**,
so 590 is R$ 5,90; a price held as a decimal fraction would round wrong somewhere. The `offer` and
the `users` are used by lessons 4 and 15. Save it as `app/store.js`:

```javascript
// Everything the shop knows lives here, in memory. reset() puts it back the
// way it started, which is what lets a test begin from a known state.
const products = [
  { id: 'banana', name: 'Banana', price: 590, unit: 'dozen' },
  { id: 'mango', name: 'Mango', price: 450, unit: 'each' },
  { id: 'papaya', name: 'Papaya', price: 790, unit: 'each' },
  { id: 'guava', name: 'Guava', price: 1290, unit: 'kg' },
  { id: 'cashew', name: 'Cashew fruit', price: 1590, unit: 'kg' },
  { id: 'passion', name: 'Passion fruit', price: 990, unit: 'kg' },
  { id: 'acerola', name: 'Acerola', price: 1890, unit: 'kg' },
  { id: 'pineapple', name: 'Pineapple', price: 690, unit: 'each' },
];

export const store = {};

export function reset() {
  store.products = products.map((p) => ({ ...p }));
  store.basket = [];
  store.offer = { id: 'mango', price: 390 };
  store.users = new Set();
}

reset();

export function total(basket) {
  return basket.reduce((sum, line) => {
    const product = store.products.find((p) => p.id === line.id);
    return sum + product.price * line.qty;
  }, 0);
}
```

The server itself. It answers a request in one of three ways: a route from `app/routes/` if one
matches, a file from `app/public/` if one exists, and `404` otherwise. Every file it serves
carries an `ETag`, a fingerprint of its contents, and `Cache-Control: no-cache`, which lets the
browser keep a copy but makes it ask first; lesson 4 is about what those two headers do to a
test. Setting `QUITANDA_LOG=1` makes it print every request it answers. Save it as
`app/server.js`:

```javascript
// Quitanda: the shop every lesson of this course tests. No dependencies,
// only what Node itself ships.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { send } from './http.js';

const port = Number(process.env.PORT ?? 3000);
const publicDir = path.join(import.meta.dirname, 'public');
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
};

// Every file in routes/ exports a list of routes. A later lesson adds a
// file there; this one never changes.
const routes = [];
const routeDir = path.join(import.meta.dirname, 'routes');
for (const file of (await fs.readdir(routeDir)).sort()) {
  routes.push(...(await import(path.join(routeDir, file))).routes);
}

async function serveFile(req, res, pathname) {
  if (pathname.endsWith('/')) pathname += 'index.html';
  const file = path.join(publicDir, path.normalize(pathname));
  if (!file.startsWith(publicDir)) return send(res, 404, 'not found');
  let body;
  try {
    body = await fs.readFile(file);
  } catch {
    return send(res, 404, 'not found');
  }
  // A static file may be kept, but must be checked with the server first.
  const etag = '"' + crypto.createHash('sha1').update(body).digest('hex').slice(0, 12) + '"';
  const headers = { 'Cache-Control': 'no-cache', ETag: etag };
  if (req.headers['if-none-match'] === etag) {
    res.writeHead(304, headers);
    return res.end();
  }
  headers['Content-Type'] = types[path.extname(file)] ?? 'application/octet-stream';
  res.writeHead(200, headers);
  res.end(body);
}

async function readJson(req) {
  let text = '';
  for await (const chunk of req) text += chunk;
  return text ? JSON.parse(text) : {};
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  // QUITANDA_LOG=1 prints every request the server receives.
  if (process.env.QUITANDA_LOG) {
    res.on('finish', () => console.log(req.method, req.url, res.statusCode));
  }
  const route = routes.find((r) => r.method === req.method && r.path === url.pathname);
  try {
    if (route) return await route.handle({ req, res, url, body: await readJson(req) });
    if (req.method === 'GET') return await serveFile(req, res, url.pathname);
    send(res, 404, 'not found');
  } catch (err) {
    console.error(err);
    send(res, 500, { error: String(err.message) });
  }
}).listen(port, () => console.log(`quitanda is listening on http://localhost:${port}`));
```

**This file never changes again.** Lessons that add to the shop add a file to `app/routes/` and
the server picks it up the next time it starts, which is why the loop near the top reads the
folder rather than naming the files.

The shop's first routes: the list of products, the basket, adding to it, and the reset. Save it
as `app/routes/shop.js`:

```javascript
import { send } from '../http.js';
import { store, reset, total } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/products',
    handle: ({ res }) => send(res, 200, store.products),
  },
  {
    method: 'GET', path: '/api/basket',
    handle: ({ res }) => send(res, 200, { lines: store.basket, total: total(store.basket) }),
  },
  {
    method: 'POST', path: '/api/basket',
    handle: ({ res, body }) => {
      if (!store.products.some((p) => p.id === body.id)) {
        return send(res, 400, { error: `no product called ${body.id}` });
      }
      const line = store.basket.find((l) => l.id === body.id);
      if (line) line.qty += 1;
      else store.basket.push({ id: body.id, qty: 1 });
      send(res, 200, { lines: store.basket, total: total(store.basket) });
    },
  },
  {
    method: 'POST', path: '/api/reset',
    handle: ({ res }) => {
      reset();
      send(res, 200, { reset: true });
    },
  },
];
```

Notice what the basket is: **one list, shared by everybody who opens the shop.** There are no
sessions and no logins here. That is the shop's largest flaw and it is not marked, because it is
not a trap set for one lesson: it is the ordinary state of a lot of test environments, and lessons
15 and 19 meet it head on.
