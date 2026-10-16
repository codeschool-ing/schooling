---
title: A window on a machine with no screen
version: 1
---

Headless is what a build server runs, and for most suites it is the right choice. **There are
cases where a test needs a real window on a machine that has no screen**, and they come in three
kinds:

- **a defect that only shows with a window.** Focus, a window resized by the page, a pop-up the
  site opens, anything that depends on the browser's own frame around the page. A test that
  passes headless and fails for a person is evidence that this is the case; running it headed on
  the server is how you reproduce it there;
- **something the shell cannot do.** Playwright's documentation says browser extensions need the
  full Chromium; a test of an extension runs headed, or in new headless with `channel: 'chromium'`;
- **the same browser your users run.** A suite that wants to measure what people get, rather than
  a headless approximation of it, runs with the window on.

## A screen that is not there

On Linux, programs draw windows by talking to a display server. **Xvfb is a display server that
draws into memory**: it accepts windows like any other, and nobody can see them. `xvfb-run` starts
one, points the `DISPLAY` variable at it, runs your command, and stops it again. On Ubuntu it comes
from the archive:

```sh
sudo apt-get install xvfb
```

The machine these lessons were recorded on already had Ubuntu's package, so the installation is
not shown:

```
ana@laptop:~/quitanda$ dpkg -s xvfb | grep ^Version
Version: 2:21.1.12-1ubuntu1.8
```

Without it, a headed test fails before its first line. The test runner shows the same box
`modes.mjs` did:

```
ana@laptop:~/quitanda$ npx playwright test --headed tests/smoke.spec.js 2>&1 | head -14

Running 1 test using 1 worker

  ✘  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (5ms)


  1) tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ──────────────────────────────────

    Error: browserType.launch: Target page, context or browser has been closed
    Browser logs:

    ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║ Looks like you launched a headed browser without having a XServer running.                     ║
    ║ Set either 'headless: true' or use 'xvfb-run <your-playwright-app>' before running Playwright. ║
```

With `xvfb-run` in front of the same command, the browser has its display and the test passes:

```
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed tests/smoke.spec.js

Running 1 test using 1 worker

  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (603ms)

  1 passed (2.2s)
```

**Nothing in the test or the configuration changed**; only the environment the browser started
in.

## The size of a screen nobody sees

Run `modes.mjs headed` through it and the window Chromium opens is sized to a screen again:

```
ana@laptop:~/quitanda$ xvfb-run node modes.mjs headed
headed 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  webdriver: true,
  ownWindow: '1050x917',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

The user agent has lost the word `HeadlessChrome`: this is plain `Chrome/141.0.0.0`, the browser
with a window. The window is 1050 by 917. `xvfb-run` makes a screen of 1280 by 1024 unless told
otherwise, and Chromium sizes its first window from the screen it finds. A different screen, given with `-s`, gives
a different window:

```
ana@laptop:~/quitanda$ xvfb-run -s "-screen 0 1920x1080x24" node modes.mjs headed
headed 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  webdriver: true,
  ownWindow: '945x973',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

**The viewport did not move**: 1280 by 720 in both, because Playwright sets it on the page whatever
the window is. Selenium sets nothing, so its page is the window, and the window follows the screen:

```
ana@laptop:~/quitanda$ xvfb-run node selenium/headless.mjs
[
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  '1050x865',
  'Weekly deals, in a table.'
]
```

Two practical notes from `xvfb-run`'s own help. It uses display number 99 unless told otherwise,
so two commands started at once on one machine ask for the same display; `xvfb-run -a` looks for a
free number instead. And the screen's size and
colour depth are worth writing into the command, as `-s "-screen 0 1920x1080x24"` does above,
because a default you did not choose is a default somebody else can change.
