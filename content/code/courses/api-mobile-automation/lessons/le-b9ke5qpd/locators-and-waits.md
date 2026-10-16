---
title: Locators and waits
version: 1
---

**Two habits decide whether an Appium test can be trusted**: how it finds an element, and how it
waits for one. A test that finds by position breaks when the layout moves, and a test that waits by
sleeping breaks when the device is slow. Both pass on the day they are written, which is why both
are common.

## Strategies, in order of preference

Lesson 14 ranked the handles a test can use on Android. These are the strategies Appium offers for
them, with the way WebdriverIO writes each:

| strategy | WebdriverIO | on Android it means | on iOS |
|---|---|---|---|
| **id** | `$('id=example.tickets:id/refresh')` | the resource id | the element's name, usually its accessibility identifier |
| **accessibility id** | `$('~Refresh the list')` | the content description | the accessibility identifier |
| **UiAutomator** | `$('android=new UiSelector().text("Refresh")')` | a query in Google's UiAutomator syntax, run on the device | does not exist |
| **predicate, class chain** | `$('-ios predicate string:…')` | does not exist | iOS's own query syntaxes |
| **class name** | `$('android.widget.Button')` | every element of that class | the XCUITest type, such as `XCUIElementTypeButton` |
| **XPath** | `$('//android.widget.ListView/android.widget.LinearLayout[3]')` | a path through the page source of section 04 | the same, over iOS's tree |

**Accessibility id is the strategy cross-platform suites lean on.** It reads an attribute both
platforms keep for accessibility. An app built for both can give one element the same name on each,
and one locator finds it on either. Tickets has none, because lesson 14 did not write any. That is
the accessibility defect lesson 14 told you to file: a screen reader reads out a button with text and
no content description as its text and nothing more.

**XPath is last, for two reasons.** It describes positions, which change. And UiAutomator has no
XPath of its own. To answer one, the driver's app on the device writes the whole screen out as XML,
the page source of section 04, and searches that. On a long screen it is the slowest find there is.

## Trying them on the model

The fake driver answers `id`, `accessibility id`, `class name` and `xpath`, among others. That is
enough to see each one work against the model of section 04 through WebdriverIO. With the server running and the
fake driver installed, save it as `appium/fake-session.mjs`:

```js
// appium/fake-session.mjs: a WebdriverIO session against Appium's fake driver
import path from 'node:path';
import { remote } from 'webdriverio';

const ID = 'id=example.tickets:id/';

const driver = await remote({
  hostname: '127.0.0.1',
  port: 4723,
  logLevel: 'warn',
  capabilities: {
    platformName: 'Fake',
    'appium:automationName': 'Fake',
    'appium:app': path.resolve('appium/tickets-model.xml'),
  },
});

try {
  const refresh = driver.$(ID + 'refresh');
  await refresh.click();
  console.log('by id, refresh clicked:', await refresh.getAttribute('clicks'));
  console.log('by id, rows:', (await driver.$$(ID + 'title')).length);
  console.log('by accessibility id, Refresh exists:', await driver.$('~Refresh').isExisting());
  console.log('by XPath, third row exists:',
    await driver.$('//android.widget.ListView/android.widget.LinearLayout[3]').isExisting());

  const banner = driver.$(ID + 'banner');
  console.log('banner displayed now:', await banner.isDisplayed());
  try {
    await banner.waitForDisplayed({ timeout: 3000 });
  } catch (error) {
    console.log('wait failed:', error.message);
  }
} finally {
  await driver.deleteSession();
}
```

```
ana@laptop:~/boxoffice$ node appium/fake-session.mjs
by id, refresh clicked: 1
by id, rows: 3
by accessibility id, Refresh exists: false
by XPath, third row exists: true
banner displayed now: false
wait failed: element ("id=example.tickets:id/banner") still not displayed after 3000ms
```

The id found the button and the three rows. The accessibility id found nothing, because the model,
like Tickets, has no descriptions. The XPath found the third row by counting. Then the banner,
which the model hides as Tickets hides it when the list is fresh.

## Waiting

**The wrong belief is that a test should wait a fixed time for the app.** `await driver.pause(3000)`
is how it is written, and it is wrong in both directions at once. On a fast emulator it wastes three
seconds on every step. On a slow phone, or with a list that took four seconds to load, it is not
enough, and the test fails on an element that would have appeared a moment later. A suite of two
hundred such steps is ten minutes slower than it needs to be and still flaky.

**An explicit wait asks for a condition and a deadline instead.** `waitForDisplayed({ timeout:
3000 })` asks the server again and again whether the element is displayed. It returns the moment it
is, or fails at the deadline with a message that names the element. The banner never appears, so
the last line of the run above is that failure. The server's terminal shows what the wait was doing
for those three seconds, the same request repeated:

```
[1a7caf83][HTTP] --> GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 
[1a7caf83][HTTP] <-- GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 200 1 ms - 15
[1a7caf83][HTTP] --> GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 
[1a7caf83][HTTP] <-- GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 200 1 ms - 15
[1a7caf83][HTTP] --> GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 
[1a7caf83][HTTP] <-- GET /session/1a7caf83-b179-4d8b-8b7b-3464377d2a3e/element/6/displayed 200 1 ms - 15
```

The deadline is not how long the test usually waits. It is how long it **may** wait before the app
is called broken. Set it from what a person would put up with. Fifteen seconds for the list to load
over a bad network is generous, and a test that needs more has found something lesson 22 cares
about.

The waits WebdriverIO offers:

| wait | succeeds when |
|---|---|
| `waitForExist()` | the element is in the tree, drawn or not |
| `waitForDisplayed()` | it is in the tree and visible |
| `waitForEnabled()` | it can be acted on |
| `waitForDisplayed({ reverse: true })` | it has gone, such as a progress indicator |
| `driver.waitUntil(fn, { timeout })` | a function of yours returns true, such as a text reaching a value |

WebdriverIO also waits a little on its own before acting on an element that is not there yet, and
Appium has an *implicit wait* setting that makes every find retry on the server. **Choose one
place to wait, and make it the explicit wait in the test.** Two layers of waiting multiply, and a
test whose implicit wait is ten seconds takes ten seconds to prove that something is absent.
