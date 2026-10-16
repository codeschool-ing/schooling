---
title: Screen objects
version: 1
---

**A test should say what a person does, and a screen object should say how.** The test of section
05 mixes the two: the resource ids, the waits and the row positions sit in the same lines as the
thing being checked. With one test that is fine. With thirty, the id `example.tickets:id/title` is
written thirty times, and the day a developer renames it, thirty tests fail for one reason and
somebody edits thirty files.

The pattern that fixes it is called the **page object** on the web, and `web-automation` will have
shown it there if you took it; on a phone it is a **screen object**. Each screen of the app gets
one class. The class knows the screen's ids and waits, and offers the test what a person can do
there. When the app changes, one class changes.

## Two screens

The list. `open` taps a row and returns the screen it leads to, already waited for, so a test
cannot forget the wait. Save it as `appium/screens/list.mjs`:

```js
// appium/screens/list.mjs: Tickets's list screen, as a test sees it
import { ShowScreen } from './show.mjs';

const ID = 'id=example.tickets:id/';

export class ListScreen {
  constructor(driver) {
    this.driver = driver;
  }

  get banner() {
    return this.driver.$(ID + 'banner');
  }

  async waitUntilLoaded() {
    await this.driver.$(ID + 'title').waitForDisplayed({ timeout: 15000 });
    return this;
  }

  async rows() {
    await this.waitUntilLoaded();
    return this.driver.$$(ID + 'title');
  }

  async open(position) {
    const rows = await this.rows();
    await rows[position].click();
    return new ShowScreen(this.driver).waitUntilShown();
  }
}
```

The show. It answers questions and does nothing else, because nothing on it is tapped yet; the
reminder switch arrives in lesson 21. Save it as `appium/screens/show.mjs`:

```js
// appium/screens/show.mjs: the screen of one show, as a test sees it
const ID = 'id=example.tickets:id/';

export class ShowScreen {
  constructor(driver) {
    this.driver = driver;
  }

  async waitUntilShown() {
    await this.driver.$(ID + 'seats').waitForDisplayed({ timeout: 5000 });
    return this;
  }

  title() {
    return this.driver.$(ID + 'title').getText();
  }

  seats() {
    return this.driver.$(ID + 'seats').getText();
  }
}
```

## The test, rewritten

The test of section 05 becomes two, and neither mentions an id. Replace the file; save it as
`appium/tickets.test.mjs`:

```js
// appium/tickets.test.mjs: the same test, written against two screen objects
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { remote } from 'webdriverio';
import { ListScreen } from './screens/list.mjs';

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

test('the list shows the three shows', async () => {
  const rows = await new ListScreen(driver).rows();
  assert.equal(rows.length, 3);
});

test('the third show opens with the seats boxoffice reports', async () => {
  const show = await new ListScreen(driver).open(2);
  assert.equal(await show.title(), 'O Pagador de Promessas');

  const api = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();
  assert.equal(await show.seats(), `${api.seats_left} seats left`);
});
```

Read the second test aloud and it is the sentence a manual test case of `manual-testing` would have
been: open the third show; its title is *O Pagador de Promessas*; its seats are what boxoffice says.
The ids, the deadlines and the order of the rows are in the screens, said once.

**This version was not run**, for the reason section 05 gives: no device. The screens use only the
WebdriverIO calls that file used, and the command to run it is the same.

## What does not belong in a screen object

- **Assertions.** The screen answers `seats()`; the test decides what the answer should be. A
  screen that asserted would carry one test's expectations into every test that used it.
- **Sleeps**, for the reasons of section 06. A screen is the natural home for waits, and the
  explicit ones belong there.
- **Data.** Which show to open is the test's business, given as an argument.

Two habits keep screen objects honest. Return the next screen from an action that leads to one,
as `open` does, so the test follows the app's own path. And keep them small: a screen object with
forty methods is usually three screens, or one screen and somebody's whole suite.
