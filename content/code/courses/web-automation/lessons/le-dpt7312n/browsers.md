---
title: Projects, and running in more than one browser
version: 1
---

A test passes in Chromium. **That says nothing about Firefox or Safari**: three engines lay out,
time and parse the same page in slightly different ways, and `manual-testing` lesson 7 is about
what that costs a site. Playwright runs one suite in several of
them through **projects**: named sets of settings, each of which runs every test again.

## A separate configuration for it

`playwright.config.js` stays as lesson 1 wrote it; every lesson in this course runs against it.
The browsers go into a second file that imports the first and adds three projects. Each project
takes its settings from `devices`, Playwright's list of ready-made descriptions: a window size, a
user agent and the engine to use. Save it as `browsers.config.js`:

```javascript
import { defineConfig, devices } from '@playwright/test';
import base from './playwright.config.js';

// The project's own settings, run once per browser.
export default defineConfig(base, {
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
```

`defineConfig` accepts more than one configuration and merges them in order, so `testDir`, the
reporter, the `baseURL` and the `webServer` that starts the shop all come from the base file. A
config is chosen with `--config`, and `--list` shows what it would run without running anything:

```
%%CAP list%%
```

**One test became three.** Every test file in `tests/` is multiplied the same way, which is the
price of the coverage: a suite that takes four minutes in one browser takes about twelve in three.

## Choosing a project, and one trap

`--project` picks one or more projects by name. It takes **every word after it** as a project name,
so a file name placed after it is read as a project:

```
%%CAP project-greedy%%
```

Write the name with an equals sign, which ends the option, or put the files first. Here is the
Chromium project on its own, over the smoke test and the contexts test of the next section:

```
%%CAP chromium%%
```

The `[chromium]` in front of each line is the project, and in a run of all three it is how you
tell which browser failed.

## What Firefox prints when it is not there

The browsers are separate downloads, as lesson 1 found for Chromium. On your own computer,
`npx playwright install` with no argument fetches all three, and `npx playwright install firefox
webkit` fetches the two this configuration adds. **On the machine these lessons were recorded on,
those downloads are blocked**, so only Chromium is installed, and the Firefox project fails before
its first line:

```
%%CAP firefox%%
```

The path names `firefox-@@FFBUILD@@`: Playwright 1.56.0 looks for one particular build of its patched
Firefox, as it does for Chromium. **The Firefox and WebKit projects were not run for this course**,
so no transcript here shows a test passing in either. Run `npx playwright test --config
browsers.config.js` on your own machine after installing them and you should see every test three
times; where a test fails in one engine only, the failure is the finding.

Two more things a project can choose, from Playwright's documentation. `channel: 'chrome'` or
`channel: 'msedge'` runs the branded Google Chrome or Microsoft Edge installed on the computer
instead of Playwright's Chromium, which matters when the users of a site run Chrome and a defect
appears only there. And `devices['Pixel 7']`, or any of the phones on the list, sets a small window,
a touch screen and a mobile user agent, and names the engine that phone uses: Chromium for a Pixel,
WebKit for an iPhone. That is one way to point lesson 7's adaptive page at a phone. Neither was run
here.
