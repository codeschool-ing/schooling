---
title: Service workers, and the page that opens offline
version: 1
---

A **progressive web app**, a PWA, is a web app the browser can install like a native one and that
keeps working when the network does not. The usual belief is that it is a kind of framework, or an
app store package. It is neither: it is an ordinary site with three things added. It is served over
HTTPS, or from `localhost`, which browsers treat as secure. It has a **manifest**, the small JSON
file you saved in the first section, which gives the installed app its name, the address it starts
at and how it opens. And it has a **service worker**, which is the part that changes testing.

## What a service worker is

A service worker is a script the browser runs **apart from the page, between the page and the
network**. Once it is installed, every request a page in its scope makes, `/spa/` and everything
under it in this case, goes to the worker first, and the worker decides whether to answer from a
copy it keeps, ask the network, or both. It outlives the page: it is still installed the next time
the browser opens the site, which is what lets an app open with no network at all. Quitanda's is
short:

```schooling-example
{"language": "javascript", "file": "app/public/spa/sw.js", "parts": [{"code": "// The service worker that makes the app open with no network. It keeps a\n// copy of the page, its script and its style, and answers from that copy\n// before asking the server.\nconst SHELL = ['/spa/', '/spa/spa.js', '/style.css'];\n", "note": "The comment says what it is for. The worker keeps a copy of three files, the **shell**: the page, its script and the stylesheet. Not the data."}, {"code": "self.addEventListener('install', (event) => {\n  event.waitUntil(caches.open('shell-v1').then((cache) => cache.addAll(SHELL)));\n});\n", "note": "When the browser installs the worker, it fetches the three files into a cache called `shell-v1`. `waitUntil` keeps the installation open until they are in."}, {"code": "self.addEventListener('fetch', (event) => {\n  const url = new URL(event.request.url);\n  if (event.request.method !== 'GET' || url.pathname.startsWith('/api/')) return;\n  event.respondWith(caches.match(event.request).then((hit) => hit ?? fetch(event.request)));\n});", "note": "Every request in scope passes through here. Anything that is not a `GET`, and anything under `/api/`, is left alone and goes to the network as usual. Everything else is answered from the cache if it is there, and fetched from the server only if it is not: **cache first**."}]}
```

Run `spa-look.mjs` a second time. The profile in `.spa-profile` still has the worker the first run
installed, so this is a returning visitor:

```
ana@laptop:~/quitanda$ node spa-look.mjs
   16 ms  document   /spa/  from the service worker
   26 ms  stylesheet /style.css  from the service worker
   31 ms  script     /spa/spa.js  from the service worker
   59 ms  fetch      /api/products  from the server
   79 ms  heading: Fruit
   87 ms  service worker ready; click Basket
  120 ms  fetch      /api/basket  from the server
  124 ms  heading: Basket, address: http://localhost:3000/spa/basket
```

Compare it with the first run. The document, the stylesheet and the script now come **from the
service worker**, and the server was not asked for them at all; the two fetches under `/api/` still
go to the server, because the worker lets them through.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three boxes: the page, the service worker and the server. Requests under /api/, such as /api/products and /api/basket, pass through the worker to the server, and offline nothing answers them. Requests for the shell go from the page to a cache inside the worker called shell-v1, holding /spa/, /spa/spa.js and /style.css, which answers them online or offline.\"><rect x=\"20\" y=\"40\" width=\"140\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"64\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">the page</text><rect x=\"220\" y=\"40\" width=\"280\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"236\" y=\"64\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">service worker</text><rect x=\"240\" y=\"120\" width=\"240\" height=\"76\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"256\" y=\"142\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">shell-v1</text><text x=\"256\" y=\"162\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/spa/  /spa/spa.js  /style.css</text><text x=\"256\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">answered from this copy</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"576\" y=\"64\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">the server</text><text x=\"576\" y=\"122\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/api/products</text><text x=\"576\" y=\"140\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/api/basket</text><path d=\"M160 100 L552 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M560 100 L550 94 L550 106 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">/api/… is passed through to the network</text><path d=\"M160 158 L232 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M240 158 L230 152 L230 164 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">online or offline, the same answer</text><text x=\"630\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">offline: nothing answers</text></svg>", "caption": "Two kinds of request, two different answers. Offline, the shell still arrives and the data does not."}
```

## Testing it with the network switched off

`context.setOffline(true)` makes Playwright's browser context behave as if the network were gone:
any request that reaches the network fails. With a worker installed, the shell should still open.
The test below loads the app once, waits for the worker to be ready, goes offline and reloads.
Save it as `tests/offline.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('the shell opens offline once the worker has it', async ({ page, context }) => {
  await page.goto('/spa/');
  await page.evaluate(() => navigator.serviceWorker.ready);
  await context.setOffline(true);
  const error = page.waitForEvent('pageerror');
  const response = await page.reload();
  expect(response.fromServiceWorker()).toBe(true);
  await expect(page.getByRole('link', { name: 'Basket' })).toBeVisible();
  // The fruit is not in the shell: /api/products goes to the network, and fails.
  expect((await error).message).toContain('Failed to fetch');
  await expect(page.locator('#view')).toBeEmpty();
});

test.describe('with service workers blocked', () => {
  test.use({ serviceWorkers: 'block' });

  test('the same reload finds nothing to answer it', async ({ page, context }) => {
    const messages = [];
    page.on('console', (message) => messages.push(message.text()));
    await page.goto('/spa/');
    await context.setOffline(true);
    await expect(page.reload()).rejects.toThrow('ERR_INTERNET_DISCONNECTED');
    expect(messages).toContain('Service Worker registration blocked by Playwright');
  });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/offline.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/offline.spec.js:3:1 › the shell opens offline once the worker has it (166ms)
  ✓  2 tests/offline.spec.js:19:3 › with service workers blocked › the same reload finds nothing to answer it (121ms)

  2 passed (1.9s)
```

Both pass. The first proves three things in order: the reload, with the network gone, was
answered by the worker, since `fromServiceWorker()` is true; the header and its links, which are in
the cached `index.html`, are on screen; and the page raised an uncaught `Failed to fetch`, leaving
`#view` empty. The second runs the same first steps with workers blocked, and there the reload
throws.

**The second line is the one that matters.** The worker installs in the background after the page
has loaded, and nothing on the page says when it is done. `navigator.serviceWorker.ready` is a
promise the browser keeps for exactly that, and `page.evaluate` waits for it. Here is the same file
with that line deleted:

```
ana@laptop:~/quitanda$ npx playwright test tests/offline.spec.js

Running 2 tests using 1 worker

  ✘  1 tests/offline.spec.js:3:1 › the shell opens offline once the worker has it (1.2s)
  ✓  2 tests/offline.spec.js:18:3 › with service workers blocked › the same reload finds nothing to answer it (111ms)


  1) tests/offline.spec.js:3:1 › the shell opens offline once the worker has it ────────────────────

    Error: page.reload: net::ERR_INTERNET_DISCONNECTED
    Call log:
      - waiting for navigation until "load"


       5 |   await context.setOffline(true);
       6 |   const error = page.waitForEvent('pageerror');
    >  7 |   const response = await page.reload();
         |                               ^
       8 |   expect(response.fromServiceWorker()).toBe(true);
       9 |   await expect(page.getByRole('link', { name: 'Basket' })).toBeVisible();
      10 |   // The fruit is not in the shell: /api/products goes to the network, and fails.
        at /home/ana/quitanda/tests/offline.spec.js:7:31

    Error: page.waitForEvent: Test ended.
    =========================== logs ===========================
    waiting for event "pageerror"
    ============================================================

      4 |   await page.goto('/spa/');
      5 |   await context.setOffline(true);
    > 6 |   const error = page.waitForEvent('pageerror');
        |                      ^
      7 |   const response = await page.reload();
      8 |   expect(response.fromServiceWorker()).toBe(true);
      9 |   await expect(page.getByRole('link', { name: 'Basket' })).toBeVisible();
        at /home/ana/quitanda/tests/offline.spec.js:6:22

  1 failed
    tests/offline.spec.js:3:1 › the shell opens offline once the worker has it ─────────────────────
  1 passed (3.5s)
```

The reload fails with `net::ERR_INTERNET_DISCONNECTED`, the error the blocked test expects,
because at that moment there was no worker yet to answer it. The second error underneath follows
from the first: the test ended while `waitForEvent('pageerror')` was still waiting, and Playwright
reports the promise left behind. Read a failure from the top.

**And the test says what offline means for this app**: the shell, and nothing else. The worker keeps
no copy of `/api/products`, so the script's fetch fails, the error goes uncaught, and `#view` stays
empty under a header that looks fine. Whether that is acceptable is a product decision, and it is
worth a question to whoever owns the app: an installed app that opens to a blank page without a
word is a defect to most people who meet it.

## Blocking the worker

Most tests are not about the service worker, and for those it is one more thing that can answer a
request. Playwright's documentation says so plainly about `page.route`, the interception the slow-network
test in the first section uses: it does not see requests a service worker answered, and the
documentation recommends **`serviceWorkers: 'block'`** when you intercept. The second test in the file uses it,
with `test.use` for its own `describe` block. With the worker blocked, the console says so, and the
same offline reload has nothing to answer it, so it fails the way any page fails offline,
`net::ERR_INTERNET_DISCONNECTED`.

Each Playwright test gets a **new browser context**, with empty storage and no worker installed,
so a worker installed by one test never answers a request in the next. That isolation is what the
`.spa-profile` folder of `spa-look.mjs` deliberately gives up.
