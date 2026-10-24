---
title: Playwright, and a browser of its own
version: 1
---

**Playwright is a library that drives a real browser from a program, and Playwright Test is the
runner built around it.** Lessons 2 and 3 ran the planner in a document simulated in Node; from here
the planner runs in Chromium, the browser Chrome is built from, with layout, CSS, a network and a
clock. The runner is one package, at the version this course pins, 1.63.0:

```
ana@dev:~/planner$ npm install --save-exact -D @playwright/test@1.63.0

added 3 packages, and audited 114 packages in 940ms

found 0 vulnerabilities
```

## The browser

The package does not contain a browser. Each release of Playwright is tested against one build of
each browser, and it downloads that build into a folder of its own, apart from any browser you
browse with. This asks it where, and what, without downloading anything:

```
ana@dev:~/planner$ env -u PLAYWRIGHT_BROWSERS_PATH npx playwright install --dry-run chromium
Chrome for Testing 153.0.8010.12 (playwright chromium v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-linux64.zip

FFmpeg (playwright ffmpeg v1011)
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip

Chrome Headless Shell 153.0.8010.12 (playwright chromium-headless-shell v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-headless-shell-linux64.zip
```

**Chromium 153.0.8010.12** is the build 1.63.0 names, and the headless shell is the same browser
compiled to run with no window, which is how tests run by default. On your machine the download is
one command, run in the project:

```sh
npx playwright install --with-deps chromium
```

`chromium` limits it to the one browser this course uses; Playwright can also drive Firefox and
WebKit, the engine of Safari, and a project that supports those should test in them too.
`--with-deps` installs the system libraries Chromium needs, and on Linux asks for your password to do
it. On Windows and on a Mac nothing extra is needed.

*That command was not run where this course was recorded: the recording machine could not reach
Playwright's download server, and already had this exact build, 1243, which every transcript in the
course used.* That is also why the course pins 1.63.0 rather than the newest release: a newer
Playwright names a newer build, and the transcripts would have come from a browser it was not tested
with.

## In a virtual machine

The browser runs with no window, so a server with no desktop runs these tests exactly as a laptop
does. What it cannot do is show you the page, and two things in this lesson are about seeing it: the
trace viewer and the report, which open in a browser of your own. On a virtual machine, copy the
report folder to your own computer and open it there.
