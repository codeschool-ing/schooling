---
title: A first test for Tickets
version: 1
---

**A test is the session of section 04 written in code, with checks between the steps.** WebdriverIO
sends the same requests curl sent, and adds waiting, error messages and a little syntax. The test
runner is the one Node already carries, `node:test`, which lesson 12 uses for the API half. A test is
a function, `before` and `after` run around them, and `assert` checks a value.

The test opens Tickets on the emulator, waits for the list, taps the third show and checks that the
show's screen says how many seats are left. That number is not written into the test. **It asks
boxoffice**, because the seats of `sh-103` depend on what earlier tests bought. A test that expected
`4` would pass after a restart and fail after an order. The screen and the API must agree,
whatever the number is, and that agreement is what the test is for.

## What it needs

- boxoffice running, as in every lesson of this half;
- the emulator running, with nothing else attached, or `appium:udid` added to say which device;
- Tickets built. A Run from lesson 14 builds it, and so does `./gradlew assembleDebug` typed in the
  `tickets` folder, or `.\gradlew.bat assembleDebug` in PowerShell. Either writes the debug APK to
  `tickets/app/build/outputs/apk/debug/app-debug.apk`, which is where the capabilities point.
  Appium installs it on the device when the session starts;
- the Appium server of section 03, running.

## The test

Save it as `appium/tickets.test.mjs`:

```js
// appium/tickets.test.mjs: Tickets on the emulator, driven from outside by Appium
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { remote } from 'webdriverio';

const ID = 'id=example.tickets:id/';
let driver;

before(async () => {
  driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    logLevel: 'warn',
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:app': path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk'),
    },
  });
});

after(async () => {
  await driver?.deleteSession();
});

test('the third show opens with the seats boxoffice reports', async () => {
  await driver.$(ID + 'title').waitForDisplayed({ timeout: 15000 });
  const titles = await driver.$$(ID + 'title');
  assert.equal(titles.length, 3);
  await titles[2].click();

  const seats = driver.$(ID + 'seats');
  await seats.waitForDisplayed({ timeout: 5000 });
  assert.equal(await driver.$(ID + 'title').getText(), 'O Pagador de Promessas');

  const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();
  assert.equal(await seats.getText(), `${show.seats_left} seats left`);
});
```

```schooling-example
{
 "language": "js",
 "file": "tickets.test.mjs",
 "parts": [
  {
   "code": "const ID = 'id=example.tickets:id/';",
   "note": "WebdriverIO reads the strategy from the front of the string: `id=` is the resource id. The package name is part of the id, as lesson 14 said, so it goes in once here."
  },
  {
   "code": "before(async () => {\n  driver = await remote({\n    hostname: '127.0.0.1',\n    port: 4723,\n    logLevel: 'warn',",
   "note": "`remote` is the `POST /session` of section 04. It returns when the server has a session, which on Android means the app is installed and open. `logLevel: 'warn'` keeps WebdriverIO from printing every request."
  },
  {
   "code": "    capabilities: {\n      platformName: 'Android',\n      'appium:automationName': 'UiAutomator2',\n      'appium:app': path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk'),\n    },\n  });\n});",
   "note": "The capabilities of section 02. The path is made absolute because the test and the server could have been started in different folders."
  },
  {
   "code": "after(async () => {\n  await driver?.deleteSession();\n});",
   "note": "The `DELETE` of section 04, in `after`, which runs whether the test passed or failed. The `?.` skips it when the session never started."
  },
  {
   "code": "  await driver.$(ID + 'title').waitForDisplayed({ timeout: 15000 });\n  const titles = await driver.$$(ID + 'title');\n  assert.equal(titles.length, 3);\n  await titles[2].click();",
   "note": "Wait until the first row's title is on screen, then take all of them. `$` finds one element, `$$` every element that matches. Rows count from 0, so `titles[2]` is the third show."
  },
  {
   "code": "  const seats = driver.$(ID + 'seats');\n  await seats.waitForDisplayed({ timeout: 5000 });\n  assert.equal(await driver.$(ID + 'title').getText(), 'O Pagador de Promessas');",
   "note": "The show's screen is a new screen, so wait for it too. Its title has the id `title` as well, and now that the list is gone, it is the only one."
  },
  {
   "code": "  const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();\n  assert.equal(await seats.getText(), `${show.seats_left} seats left`);",
   "note": "The expected text is built from boxoffice's answer, with the words of `strings.xml`. `getText` is a request too: Appium reads the text off the device at that moment."
  }
 ]
}
```

Run it with Node's test runner, from `~/boxoffice`. `--test-reporter=tap` asks for the plain TAP
report, which is what the transcripts of this course print. Without it Node draws its own report
with symbols, and says the same things:

```sh
node --test --test-reporter=tap appium/tickets.test.mjs
```

On your computer, with the emulator open, the app appears on it and the list loads. The third row is
tapped, the show's screen opens, and the runner reports one test passed. **That run was not
recorded for this course.** The app was never built on the recording machine, and lesson 14 showed
that no emulator can start there. What was recorded is the same command on that machine, where Appium had
nowhere to install the app:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap appium/tickets.test.mjs
TAP version 13
# 2026-10-16T01:20:41.067Z WARN webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:01.613Z WARN webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:22.653Z WARN webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:42.685Z ERROR webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:42.686Z ERROR webdriver: unknown error: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
#     at FetchRequest._request (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:2316:19)
#     at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
#     at async startWebDriverSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1376:16)
#     at async _WebDriver.newSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1805:41)
#     at async remote (file:///home/ana/boxoffice/node_modules/webdriverio/build/node.js:10947:20)
#     at async TestContext.<anonymous> (file:///home/ana/boxoffice/appium/tickets.test.mjs:11:12)
#     at async TestHook.run (node:internal/test_runner/test:1054:7)
# Subtest: the third show opens with the seats boxoffice reports
not ok 1 - the third show opens with the seats boxoffice reports
  ---
  duration_ms: 84717.075108
  type: 'test'
  location: '/home/ana/boxoffice/appium/tickets.test.mjs:27:1'
  failureType: 'hookFailed'
  error: 'WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"'
  code: 'ERR_TEST_FAILURE'
  stack: |-
    startWebDriverSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1380:11)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async _WebDriver.newSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1805:41)
    async remote (file:///home/ana/boxoffice/node_modules/webdriverio/build/node.js:10947:20)
    async TestContext.<anonymous> (file:///home/ana/boxoffice/appium/tickets.test.mjs:11:12)
    async TestHook.run (node:internal/test_runner/test:1054:7)
  ...
1..1
# tests 1
# suites 0
# pass 0
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 85108.994189
```

**The failure is the session, not the test**, and the report says so: `failureType: 'hookFailed'`,
the `before` hook that calls `remote`. The UiAutomator2 driver asked adb for a device and found
none in 20 seconds. WebdriverIO retries a session that fails to start, and tried three more times.
Those are the first four lines, about twenty seconds apart, and the reason the run took 85 seconds
to fail. In a pipeline, where nobody is going to start the emulator halfway through,
`connectionRetryCount: 0` beside `logLevel` makes it fail on the first answer.

**This is the first error most people meet with a real device as well.** Its cause is nearly
always that the emulator was not running when the test started, or that `adb devices` lists
nothing although it is. Lesson 14's section on failures has the fix for both.

## On iOS

The same test on an iPhone simulator needs a Mac, Xcode and Appium's XCUITest driver, and an app
whose elements carry accessibility identifiers. The capabilities change and the requests do not.
This was not run for this course, which has no Mac:

```js
capabilities: {
  platformName: 'iOS',
  'appium:automationName': 'XCUITest',
  'appium:deviceName': 'iPhone 16',
  'appium:app': path.resolve('Tickets.app'),
},
```

Lesson 18 is about testing on iOS, and says what a Mac costs.
