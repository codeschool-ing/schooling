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
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --list tests/smoke.spec.js
Listing tests:
  [chromium] › smoke.spec.js:3:1 › the shop opens and lists its fruit
  [firefox] › smoke.spec.js:3:1 › the shop opens and lists its fruit
  [webkit] › smoke.spec.js:3:1 › the shop opens and lists its fruit
Total: 3 tests in 1 file
```

**One test became three.** Every test file in `tests/` is multiplied the same way, which is the
price of the coverage: a suite that takes four minutes in one browser takes about twelve in three.

## Choosing a project, and one trap

`--project` picks one or more projects by name. It takes **every word after it** as a project name,
so a file name placed after it is read as a project:

```
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --project chromium tests/smoke.spec.js
Error: Project(s) "tests/smoke.spec.js" not found. Available projects: "chromium", "firefox", "webkit"
    at filterProjects (/home/ana/quitanda/node_modules/playwright/lib/runner/projectUtils.js:80:11)
    at runTests (/home/ana/quitanda/node_modules/playwright/lib/program.js:217:42)
    at i.<anonymous> (/home/ana/quitanda/node_modules/playwright/lib/program.js:71:7)
```

Write the name with an equals sign, which ends the option, or put the files first. Here is the
Chromium project on its own, over the smoke test and the contexts test of the next section:

```
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --project=chromium tests/smoke.spec.js tests/contexts.spec.js

Running 5 tests using 2 workers

  ✓  1 [chromium] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (278ms)
Ana's page reads ana
Bia's page reads null
  ✓  2 [chromium] › tests/contexts.spec.js:8:1 › two contexts share nothing in the browser (458ms)
cookies: Ana [], Bia []
Ana's total after Bia's mango: R$ 10,40
  ✓  3 [chromium] › tests/contexts.spec.js:31:1 › two shoppers, one basket: the shop's flaw (400ms)
  ✓  4 [chromium] › tests/contexts.spec.js:57:1 › the page fixture: storage written in one test (100ms)
  ✓  5 [chromium] › tests/contexts.spec.js:63:1 › the next test in the same browser starts without it (89ms)

  5 passed (2.5s)
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
ana@laptop:~/quitanda$ npx playwright test --config browsers.config.js --project=firefox tests/smoke.spec.js

Running 1 test using 1 worker

  ✘  1 [firefox] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (4ms)


  1) [firefox] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ──────────────────────

    Error: browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/firefox-1495/firefox/firefox
    ╔═════════════════════════════════════════════════════════════════════════╗
    ║ Looks like Playwright Test or Playwright was just installed or updated. ║
    ║ Please run the following command to download new browsers:              ║
    ║                                                                         ║
    ║     npx playwright install                                              ║
    ║                                                                         ║
    ║ <3 Playwright Team                                                      ║
    ╚═════════════════════════════════════════════════════════════════════════╝

  1 failed
    [firefox] › tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ───────────────────────
```

The path names `firefox-1495`: Playwright 1.56.0 looks for one particular build of its patched
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
