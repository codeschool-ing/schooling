---
title: Two headless Chromiums
version: 1
---

The obvious picture is one browser with a switch on it: window on, window off. **For Chromium
that picture is out of date, and Playwright installs two separate programs to cover the two
modes.** Chrome's headless mode began as a second, smaller implementation built into the same
program, sharing the engine but not the browser around it. Later Chrome rebuilt headless as the
real browser with its window switched off, and took the old one out. Ask Chrome 141 for the old
mode and it says so itself:

```
%%CAP chrome-old%%
```

The **new headless** mode is the whole browser without a window. The **headless shell** is the
old implementation, kept alive as a separate, smaller program for automation.
Both are Chromium 141 here, and both answer to `headless: true`, so the question is which one
Playwright starts.

## Which program runs

Playwright prints the command it launches when the `DEBUG` variable names `pw:browser`. The line
is several hundred characters long; `grep -o` keeps the program's path:

```
%%CAP launching%%
```

**Headless with no channel starts the shell; `channel: 'chromium'` starts the full browser in new
headless.** The full browser is also the one that runs whenever there is a window, which makes it
the only one of the two that can run with `--headed`. Both are in Playwright's cache, and the
shell is about half the size:

```
%%CAP du%%
```

`npx playwright install chromium` downloads both. Two options choose one of them:

```
%%CAP install-help%%
```

A build server that only ever runs headless with the default settings can take `--only-shell`
and save the larger download. A machine that runs headed, or uses `channel: 'chromium'`, needs the
full browser, which is what `--no-shell` keeps.

## What a site can tell apart

Run `modes.mjs` with `new`, the full browser in new headless:

```
%%CAP modes-new%%
```

The same build, `141.0.7390.37`, and three answers that differ from the shell's:

| | headless shell | new headless |
|---|---|---|
| the user agent's version | `HeadlessChrome/141.0.7390.37` | `HeadlessChrome/141.0.0.0` |
| the window it invents | 800 by 600 | 780 by 493 |
| the page a test gets | 1280 by 720 | 1280 by 720 |

The shorter version number is the full browser's own reduced user agent, the form Chrome sends
when it has a window as well; the shell still sends every digit. **Both still say
`HeadlessChrome`**, so a site that looks for that word finds it in either mode. The viewport row is
the reassuring one: Playwright's 1280 by 720 is the same in both, so a test that leaves it alone
sees the same page. The invented windows only matter to a test that turns the viewport off, and
the section on differences that bite is that test.

To run the project's tests in each of them, a second configuration adds two projects, the way
lesson 10's `browsers.config.js` added three browsers. Save it as `headless.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The project's own settings, run in Playwright's two headless Chromiums.
export default defineConfig(base, {
  projects: [
    { name: 'shell', use: { headless: true } },
    { name: 'new-headless', use: { headless: true, channel: 'chromium' } },
  ],
});
```

## Selenium asks Chrome directly

Selenium has no headless option of its own. It starts Chrome through chromedriver with the
arguments you give it, and `--headless=new` is Chrome's switch, as lesson 8's first test used it.
This script opens the deals page and reports the same three things; save it as
`selenium/headless.mjs`:

```javascript
import { Builder } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

// node selenium/headless.mjs [--headless=new]; the shop must be running.
const options = new chrome.Options();
if (process.argv[2]) options.addArguments(process.argv[2]);
const driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
try {
  await driver.get('http://localhost:3000/deals');
  console.log(await driver.executeScript(
    'return [navigator.userAgent, innerWidth + "x" + innerHeight, document.querySelector("p").textContent]'));
} finally {
  await driver.quit();
}
```

```
%%CAP selenium-new%%
```

**Plain `--headless` and `--headless=new` are the same mode now**, the full browser, because the
other one is gone. The window is 780 wide, like Playwright's new headless, and nothing sets a
viewport for it: Selenium gives the page whatever window Chrome opened, which is one reason
Selenium suites set a window size themselves. Older guides still say `--headless=old`, and this is
what that costs today:

```
%%CAP selenium-old%%
```

**The message blames a user data directory, and the cause is something else.** Chrome refused the
mode and exited, and chromedriver, which only saw a browser that never answered, guessed. When a
driver's error does not fit what you did, start the browser by hand with the same arguments, the
way the first transcript of this section did; Chrome's own message named the cause in one line.
