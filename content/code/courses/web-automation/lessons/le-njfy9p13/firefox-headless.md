---
title: Firefox without a window
version: 1
---

**Firefox has one headless mode, and nothing in this section was run.** Playwright's download of
its Firefox is blocked on the machine these lessons were recorded on, as lesson 10 found when its
Firefox project failed before the first line, and no other Firefox is installed there. What follows
is the code a student would write and what Firefox's and Playwright's documentation say it does.
On your own computer, `npx playwright install firefox` fetches the build and every command here
can be run.

There is no shell and no second program to choose between. Mozilla's documentation describes one
switch, the `-headless` command-line argument, and an environment variable, `MOZ_HEADLESS=1`, that
does the same for a Firefox started by something else. The engine, the layout and the painting are
the ones Firefox uses with a window.

## In Playwright

Playwright treats Firefox the way it treats Chromium: headless unless asked otherwise, with the
same `headless` option and the same `--headed` flag. The browser it starts is its own patched build
of Firefox, downloaded for its version, not the Firefox installed on the computer. A launch is one
line different from `modes.mjs`:

```javascript
import { firefox } from '@playwright/test';

const browser = await firefox.launch();                      // headless
const watched = await firefox.launch({ headless: false });   // a window
```

In a test project the same choice is a project, as lesson 10's `browsers.config.js` has it:
`devices['Desktop Firefox']` names the engine, and `--headed` on the command line gives every
project a window. **Both were not run for this course.**

## In Selenium

Selenium starts Firefox through **geckodriver**, Mozilla's WebDriver server, which plays the part
chromedriver plays for Chrome in lesson 8. The headless switch is Firefox's own argument, handed
over in the options:

```javascript
import { Builder } from 'selenium-webdriver';
import firefox from 'selenium-webdriver/firefox.js';

const options = new firefox.Options().addArguments('-headless');
const driver = await new Builder().forBrowser('firefox').setFirefoxOptions(options).build();
```

**Note the single hyphen**: `-headless` is how Firefox spells its arguments, where Chrome writes
`--headless=new`. Selenium does not translate one into the other. Building the options needs no
browser, so this much can be checked here: the argument goes into the `moz:firefoxOptions`
capability, which is what geckodriver reads when it starts Firefox.

```
%%CAP firefox-options%%
```

Starting the session needs geckodriver and Firefox, and neither was available, so the test that
would follow was not run. Older guides call a `headless()` method on the options instead. Selenium's
own changelog, in `node_modules/selenium-webdriver/CHANGES.md`, deprecates it in 4.8.0 and removes
it in 4.17.0, so on this project's 4.51.0 that line is an error.

## What to expect when you run it

Two things from the Chromium sections carry over and are worth checking in Firefox for yourself,
with a version of `modes.mjs` that imports `firefox`: **the window Firefox invents with no screen**,
and **what its user agent says**. This lesson does not tell you the answers, because the only way
to know them is a run, and none was possible here. Lesson 7's adaptive page reads only `Mobile`,
so a desktop Firefox gets the desktop deals page whatever the rest of the string says.
