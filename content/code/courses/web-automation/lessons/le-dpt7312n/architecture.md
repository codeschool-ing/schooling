---
title: One process, one connection, a browser at the other end
version: 1
---

Every test so far began with `import { test, expect } from '@playwright/test'` and a `page` that
did what it was told. **That `page` is not inside the browser.** Your test file runs in Node, in a
process of its own, and the browser is a second program Playwright starts beside it. Everything
the test does to the shop crosses from one to the other, and how it crosses is what makes
Playwright behave differently from the two tools before it.

## Three ways to reach a browser

Lesson 8 drove the same Chromium with Selenium. There, every command becomes an **HTTP request**
to a separate driver program, `chromedriver`, which translates it for the browser and answers when
it is done. The browser cannot speak first: a test that wants to know whether something happened
has to ask, and ask again.

Lesson 9 ran Cypress, which goes the other way. The test is loaded **into the browser**, beside the
page under test, and runs in the same JavaScript world. Nothing crosses a process boundary, which
is fast, and it is also why Cypress's own documentation lists a second tab among the things it
does not support: the test lives in one.

Playwright sits between the two. The test stays outside, in Node, and Playwright keeps **one
connection open** to the browser for as long as it runs. Commands go down it; the browser sends
**events** back up it unasked: a request went out, a response came in, the page wrote to its
console, a frame navigated. `look.mjs` in lesson 1 listened to exactly those events.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Three ways a test reaches a browser. WebDriver: the test sends one HTTP request per command to a driver program, chromedriver, which drives the browser. Cypress: the test runs inside the browser beside the page under test. Playwright: one Node process holds one connection to the browser, sending commands and receiving events; the protocol is CDP for Chromium and a patched one for Firefox and WebKit.\"><text x=\"120\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">WebDriver, lesson 8</text><rect x=\"40\" y=\"40\" width=\"160\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"65\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">your test</text><path d=\"M120 80 L120 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M120 128 L115 119 L125 119 Z\" fill=\"var(--phosphor)\"></path><text x=\"126\" y=\"100\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one HTTP request</text><text x=\"126\" y=\"114\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">per command</text><rect x=\"40\" y=\"130\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a driver program</text><text x=\"120\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">chromedriver</text><path d=\"M120 180 L120 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M120 228 L115 219 L125 219 Z\" fill=\"var(--phosphor)\"></path><rect x=\"40\" y=\"230\" width=\"160\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"255\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the browser</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">Cypress, lesson 9</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"230\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"360\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the browser</text><rect x=\"286\" y=\"80\" width=\"148\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"360\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">your test</text><text x=\"360\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in the same tab</text><rect x=\"286\" y=\"160\" width=\"148\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"360\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the page under test</text><text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the shop</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">both inside one browser</text><text x=\"600\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">Playwright, this lesson</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"600\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one Node process</text><text x=\"600\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">your test + Playwright</text><path d=\"M600 100 L600 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M600 168 L595 159 L605 159 Z\" fill=\"var(--phosphor)\"></path><path d=\"M600 100 L595 109 L605 109 Z\" fill=\"var(--phosphor)\"></path><text x=\"608\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">one connection</text><text x=\"608\" y=\"136\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">commands go down,</text><text x=\"608\" y=\"150\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">events come up</text><rect x=\"510\" y=\"170\" width=\"180\" height=\"100\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"600\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the browser</text><text x=\"600\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">CDP</text><text x=\"600\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">for Chromium</text><text x=\"600\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a patched protocol</text><text x=\"600\" y=\"263\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">for Firefox and WebKit</text></svg>", "caption": "The same click, three ways. Only Playwright keeps one connection open and hears what the browser says without asking."}
```

## What travels on the connection

For Chromium, the language on that line is the **Chrome DevTools Protocol**, CDP: the protocol the
developer tools of lesson 1 use to talk to the page they inspect. Playwright prints what it sends
when the `DEBUG` variable asks for it. Here are the first commands of the smoke test from lesson 1:

```
%%CAP protocol-methods%%
```

Each `SEND` is a command with a number; the browser's answer comes back as a `RECV` carrying the
same number, and events come back as `RECV` lines with no number at all. Counted over the whole
run:

```
%%CAP protocol-count%%
```

@@COUNT@@ The third command on the list, `Target.createBrowserContext`, is worth remembering for the
section on contexts: a context is something the browser itself provides, not a trick of
Playwright's.

**The connection is a pipe here, not a network socket.** When Playwright launches the browser
itself, it hands it a pair of pipes and tells it so on the command line:

```
%%CAP pipe%%
```

When the browser runs somewhere else, on another machine or in a container, Playwright reaches it
over a **WebSocket** instead, and the conversation is the same. Neither needs a driver program in
the middle, which is one fewer thing to install and keep at the right version than lesson 8 had.

## Firefox and WebKit are Playwright's own builds

CDP belongs to Chromium. Firefox and WebKit do not speak it, so **Playwright ships patched builds
of both**, each extended with a protocol Playwright can drive the same way. Its documentation says
this plainly, and it has a consequence you will meet in the next section: `npx playwright install
firefox` downloads Playwright's Firefox, not the Firefox you browse with, and WebKit is the engine
inside Safari, not Safari itself.

**The same test code drives all three.** `page.click`, `expect(...).toHaveText` and the rest are
written once; the protocol underneath changes per browser and the test never sees it. That is what
makes the next section's three projects possible with one configuration file and no change to a
single test.
