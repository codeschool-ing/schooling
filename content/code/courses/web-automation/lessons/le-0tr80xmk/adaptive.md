---
title: Adaptive pages, chosen by the server
version: 1
---

An **adaptive** site makes the decision before the page leaves the server. It reads the request's
`User-Agent` header, the name the browser gives itself, guesses what kind of device sent it, and
sends one of two or more different pages. A responsive page is the same HTML everywhere and the
stylesheet decides; an adaptive page is different HTML, and **the width of the window decides
nothing**, because nothing in the request tells this server what it is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two boxes. The browser holds the window's width, 390, and the User-Agent string. Only the User-Agent crosses an arrow to the server, sent with every request; the width is not sent. Responsive pages decide in the browser, adaptive pages on the server.\"><rect x=\"20\" y=\"30\" width=\"300\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">the browser</text><rect x=\"36\" y=\"72\" width=\"268\" height=\"44\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"48\" y=\"99\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the window's width, 390</text><rect x=\"36\" y=\"128\" width=\"268\" height=\"44\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"48\" y=\"155\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">User-Agent: …Mobile…</text><text x=\"36\" y=\"203\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">responsive pages decide here</text><text x=\"385\" y=\"99\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the width is not sent</text><path d=\"M306 150 L440 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M448 150 L438 144 L438 156 Z\" fill=\"var(--phosphor)\"></path><text x=\"385\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sent with every request</text><rect x=\"450\" y=\"30\" width=\"250\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"466\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">the server</text><rect x=\"466\" y=\"128\" width=\"218\" height=\"44\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"478\" y=\"155\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reads it and picks a page</text><text x=\"466\" y=\"203\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">adaptive pages decide here</text></svg>", "caption": "Each kind of page decides with what it can see. The shop's server never learns the width, so no window size can test an adaptive page."}
```

## The deals page

The shop's deals page is adaptive in the smallest way possible: two pages, one test of a string.
Save it as `app/routes/deals.js`:

```javascript
import { send } from '../http.js';

// Adaptive: the server picks one of two pages from the User-Agent header.
// A narrow window on a desktop browser still gets the desktop page.
export const routes = [
  {
    method: 'GET', path: '/deals',
    handle: ({ req, res }) => {
      const phone = /Mobile/.test(req.headers['user-agent'] ?? '');
      const body = phone
        ? '<!doctype html><title>Deals</title><h1>Deals</h1><p>Tap a deal to call the shop.</p>'
        : '<!doctype html><title>Deals</title><h1>Deals</h1><p>Weekly deals, in a table.</p>';
      send(res, 200, body, { 'Content-Type': 'text/html; charset=utf-8', Vary: 'User-Agent' });
    },
  },
];
```

The server reads every file in `app/routes/` when it starts, so restart the shop. A request from
`curl`, which calls itself `curl` and a version number, gets the desktop page:

```
ana@laptop:~/quitanda$ curl -si http://localhost:3000/deals
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Vary: User-Agent
Date: Sat, 10 Oct 2026 19:36:08 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<!doctype html><title>Deals</title><h1>Deals</h1><p>Weekly deals, in a table.</p>
```

and the same request carrying the iPhone 13's name, read out of Playwright's descriptor, gets the
other one:

```
ana@laptop:~/quitanda$ curl -s -A "$(node -p "require('@playwright/test').devices['iPhone 13'].userAgent")" http://localhost:3000/deals
<!doctype html><title>Deals</title><h1>Deals</h1><p>Tap a deal to call the shop.</p>
```

**Same address, same server, a different page**, chosen by the word `Mobile` somewhere in a
string. The `viewport` section showed the other half: a desktop window 390 pixels wide was given
*Weekly deals, in a table*, and the iPhone descriptor at the same width was given *Tap a deal to
call the shop*. Narrowing a window, which is the whole of testing a responsive page, does not test
an adaptive one at all.

## `Vary`, the header that keeps the two apart

Look again at the headers: `Vary: User-Agent`. It tells every cache between the server and the
browser that this answer depends on that request header, so a copy kept for one `User-Agent` must
not be handed to another. Without it, a cache that stored the phone page could serve it to the next
desktop that asked, and the defect would come and go with whoever asked first. Lesson 4 is about
caches; for an adaptive page, the `Vary` header is part of what to check.

## The test, and an error worth meeting

A first attempt puts the descriptor in a `describe` block, the way the last section put each
width. Save it as `tests/deals.spec.js`:

```javascript
import { test, expect, devices } from '@playwright/test';

test.describe('an iPhone', () => {
  test.use(devices['iPhone 13']);

  test('gets the page for a phone', async ({ page }) => {
    await page.goto('/deals');
    await expect(page.getByText('Tap a deal to call the shop.')).toBeVisible();
  });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/deals.spec.js
Cannot use({ defaultBrowserType }) in a describe group, because it forces a new worker.
Make it top-level in the test file or put in the configuration file.

   at deals.spec.js:4

  2 |
  3 | test.describe('an iPhone', () => {
> 4 |   test.use(devices['iPhone 13']);
    |        ^
  5 |
  6 |   test('gets the page for a phone', async ({ page }) => {
  7 |     await page.goto('/deals');
```

The descriptor carries `defaultBrowserType: 'webkit'`, and a browser engine is chosen when a worker
starts, not per block. Playwright's answer, *put it in the configuration file*, means a
**project**, which lesson 10 covers with the rest of the configuration. Here the file keeps everything else the descriptor sets and
leaves the engine out, which is what `viewport.mjs` did too. It also checks the `Vary` header, and
adds the narrow desktop window that must get the desktop page. Save it as `tests/deals.spec.js`:

```javascript
import { test, expect, devices } from '@playwright/test';

// The iPhone 13 descriptor asks for WebKit, and a browser type cannot
// change inside a describe block. Keep the rest of it, in Chromium.
const { defaultBrowserType, ...iPhone13 } = devices['iPhone 13'];

test.describe('an iPhone, emulated in Chromium', () => {
  test.use(iPhone13);

  test('gets the page for a phone', async ({ page }) => {
    const response = await page.goto('/deals');
    await expect(page.getByText('Tap a deal to call the shop.')).toBeVisible();
    expect(response.headers()['vary']).toBe('User-Agent');
  });
});

test.describe('a desktop browser in a phone-sized window', () => {
  test.use({ viewport: { width: 390, height: 664 } });

  test('gets the page for a desktop', async ({ page }) => {
    await page.goto('/deals');
    await expect(page.getByText('Weekly deals, in a table.')).toBeVisible();
  });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/deals.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/deals.spec.js:10:3 › an iPhone, emulated in Chromium › gets the page for a phone (122ms)
  ✓  2 tests/deals.spec.js:20:3 › a desktop browser in a phone-sized window › gets the page for a desktop (86ms)

  2 passed (1.7s)
```

## A guess has edges

The server's rule is a guess about devices, and a guess can be tested for where it goes wrong.
Playwright's own list marks some devices `isMobile` whose `User-Agent` has no `Mobile` in it:

```
ana@laptop:~/quitanda$ node -p "Object.entries(require('@playwright/test').devices).filter(([name, d]) => d.isMobile && !/Mobile/.test(d.userAgent)).map(([name]) => name)"
[
  'Blackberry PlayBook',
  'Blackberry PlayBook landscape',
  'Galaxy Tab S4',
  'Galaxy Tab S4 landscape',
  'Galaxy Tab S9',
  'Galaxy Tab S9 landscape',
  'Kindle Fire HDX',
  'Kindle Fire HDX landscape',
  'Nexus 10',
  'Nexus 10 landscape',
  'Nexus 7',
  'Nexus 7 landscape'
]
```

Twelve entries, six tablets held two ways each, and every one of them gets the desktop page. That may be what the shop wants, a
tablet being nearly a laptop, or it may be a defect; the code does not say, so somebody decides,
and the decision becomes a test. **The descriptors worth testing an adaptive page with are the
ones on either side of the server's rule**, the way the widths worth testing a responsive page
with are on either side of its breakpoints.

## What emulation is not

Everything above ran in **Chromium wearing an iPhone's name**. It had the iPhone's window, pixel
ratio, touch and `User-Agent`, and it was still Chromium. It is not Safari: the iPhone's engine is
WebKit, which draws, scrolls and fails differently, and Playwright can run its own build of WebKit
for a much closer answer. **WebKit was not run for this course**: the machine these transcripts
come from cannot reach Playwright's download of it, so nothing here claims what WebKit does.

And no emulation is a phone in somebody's hand: not its processor, its memory, its network on a
bus, its on-screen keyboard covering half the form, or the browser's own address bar appearing and
disappearing as the page scrolls. Emulation answers *what does this page do at this size, under
this name*; a real device answers the rest, which is `api-mobile-automation`'s subject and, for
looking at it by hand, `manual-testing` lesson 7.
