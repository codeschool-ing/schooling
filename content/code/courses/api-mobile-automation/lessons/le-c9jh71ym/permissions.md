---
title: Permissions, and the dialog that is not the app's
version: 1
---

**On a phone, what an app may do is decided by the person holding it, one permission at a time, at
the moment the app first needs it.** Since Android 6 the permissions that touch somebody's private
life, such as the camera, the location and the contacts, are asked for at runtime with a dialog,
and the person can say no. Android 13 added notifications to that list, as `POST_NOTIFICATIONS`.
So a feature behind a permission has at least two paths, and the one where the person says no is
the one nobody tries by hand twice.

The belief to drop first is that the dialog is part of the app. **It is drawn by Android**, by a
system app called the permission controller, on top of the app's window. The app only asks, and
hears the answer afterwards.

## Where Tickets asks

Lesson 14 put one permission behind the reminder switch. The manifest declares it, and the show's
screen asks for it when the switch is turned on:

```
ana@laptop:~/boxoffice$ grep -n 'POST_NOTIFICATIONS' tickets/app/src/main/AndroidManifest.xml
7:    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
ana@laptop:~/boxoffice$ grep -n 'SDK_INT\|POST_NOTIFICATIONS\|granted' tickets/app/src/main/java/example/tickets/ShowActivity.kt
32:        if (Build.VERSION.SDK_INT < 33) return
33:        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
34:        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), ASK)
40:        val granted = results.firstOrNull() == PackageManager.PERMISSION_GRANTED
41:        remind.isChecked = granted
42:        denied.visibility = if (granted) View.GONE else View.VISIBLE
```

Read in order: below Android 13 (`SDK_INT < 33`) there is nothing to ask, and the switch simply
stays on; if the permission is already granted, the same; otherwise the app asks, and when the
answer comes back, line 41 sets the switch to the answer and line 42 shows the line
`remind_denied` if it was no. That is three outcomes from one tap, and the version of Android
decides which are possible:

| Android | before the tap | the person | what Tickets should show |
|---|---|---|---|
| 12 or older | anything | nothing is asked | the switch on |
| 13 or newer | never asked | *Allow* | the dialog, then the switch on |
| 13 or newer | never asked | *Don't allow* | the dialog, then the switch off and the line saying notifications are off |
| 13 or newer | already granted | nothing is asked | the switch on |
| 13 or newer | refused twice before | nothing is asked: Android answers no for them | the switch off and the line, with no dialog |

The last row is Android's rule since version 11: **after a person refuses the same permission
twice, the dialog stops appearing** and every later request is refused at once. An app that offers
no way to the settings at that point leaves the person with a switch that turns itself off and no
idea why; Tickets at least says why, and a test should hold it to that.

## Setting the state before a test

A test of these paths has to start from a known answer, and adb can set it from outside. These
commands, like every one in this lesson that needs a device, were not run for this course:

```sh
adb shell pm grant example.tickets android.permission.POST_NOTIFICATIONS
adb shell pm revoke example.tickets android.permission.POST_NOTIFICATIONS
adb shell pm reset-permissions
adb install -r -g tickets/app/build/outputs/apk/debug/app-debug.apk
```

`grant` and `revoke` set one permission of one app. `reset-permissions` puts every app on the
device back to its defaults, which is heavy on a phone you use. `install -r -g` reinstalls the app with everything
its manifest asks for granted. **The only state that is certainly *never asked* is a fresh
install**, with no memory of earlier refusals, so the tests below remove and reinstall the app
before each one. That costs a few seconds a test, and it buys a starting point nobody has to
reason about.

Appium has the same switches. The capability `appium:autoGrantPermissions: true` installs the app
with every permission granted, which is right for a suite that is not about permissions and wrong
for this one, since it removes the dialog under test. `driver.execute('mobile: changePermissions',
{ permissions: 'android.permission.POST_NOTIFICATIONS', appPackage: 'example.tickets', action:
'revoke' })` changes one, and `mobile: getPermissions` with `type: 'granted'` lists them.

## Which tool can press *Don't allow*

**Appium can, because it sees the whole screen.** UiAutomator, underneath the UiAutomator2 driver,
reads every window on the display, the permission controller's included, so its buttons are
elements like any other; they simply carry that app's package in their ids. The dialog gets a
screen object of its own; save it as `appium/screens/permission.mjs`:

```js
// appium/screens/permission.mjs: Android's permission dialog, drawn over the app by Android
// These ids belong to Android's permission controller, not to Tickets, and a new Android
// version may change them: read them from the page source on your emulator.
const ID = 'id=com.android.permissioncontroller:id/';

export class PermissionDialog {
  constructor(driver) {
    this.driver = driver;
  }

  async waitUntilShown() {
    await this.driver.$(ID + 'permission_allow_button').waitForDisplayed({ timeout: 5000 });
    return this;
  }

  allow() {
    return this.driver.$(ID + 'permission_allow_button').click();
  }

  deny() {
    return this.driver.$(ID + 'permission_deny_button').click();
  }
}
```

**Espresso cannot.** Its test runs inside Tickets's process and acts on Tickets's windows, and the
dialog is a window of another app, so no `onView` can find its buttons. An instrumented test has two
ways round it. It can grant the permission before the test starts, through Android's own
`UiAutomation`, which `GrantPermissionRule` in `androidx.test:rules` wraps; then no dialog appears,
and no refusal can be tested either. Or it can drive the dialog with Google's **UI Automator**
library, a dependency the template of lesson 14 does not declare. So in this course the dialog's
paths belong to Appium, and section 05 has Espresso check what happens after a grant.

## The test

The show's screen object from lesson 15 grows the switch and the line under it. Replace the file;
save it as `appium/screens/show.mjs`:

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

  // The reminder switch. On Android 13 and later its first tap opens Android's permission dialog.
  async tapRemind() {
    await this.driver.$(ID + 'remind').click();
  }

  async reminderIsOn() {
    return (await this.driver.$(ID + 'remind').getAttribute('checked')) === 'true';
  }

  explainsTheDenial() {
    return this.driver.$(ID + 'remind_denied').isDisplayed();
  }
}
```

`getAttribute('checked')` reads the attribute of the same name in the page source, which
UiAutomator2 reports as the string `true` or `false`, so the method compares it with a string.
Then the two paths through the dialog. Save it as `appium/reminder.test.mjs`:

```js
// appium/reminder.test.mjs: the reminder switch and Android's permission dialog
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, before, beforeEach, test } from 'node:test';
import { remote } from 'webdriverio';
import { ListScreen } from './screens/list.mjs';
import { PermissionDialog } from './screens/permission.mjs';

const APP = 'example.tickets';
const APK = path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk');
let driver;

before(async () => {
  driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    logLevel: 'warn',
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:app': APK,
    },
  });
});

after(async () => {
  await driver?.deleteSession();
});

// A fresh install before each test, so the permission has never been asked for.
beforeEach(async () => {
  await driver.execute('mobile: removeApp', { appId: APP });
  await driver.execute('mobile: installApp', { appPath: APK });
  await driver.execute('mobile: activateApp', { appId: APP });
});

test('Allow turns the reminder on', async () => {
  const show = await new ListScreen(driver).open(2);
  await show.tapRemind();
  await (await new PermissionDialog(driver).waitUntilShown()).allow();
  assert.equal(await show.reminderIsOn(), true);
  assert.equal(await show.explainsTheDenial(), false);
});

test("Don't allow turns it off and says why", async () => {
  const show = await new ListScreen(driver).open(2);
  await show.tapRemind();
  await (await new PermissionDialog(driver).waitUntilShown()).deny();
  assert.equal(await show.reminderIsOn(), false);
  assert.equal(await show.explainsTheDenial(), true);
});
```

```schooling-example
{
 "language": "js",
 "file": "reminder.test.mjs",
 "parts": [
  {
   "code": "beforeEach(async () => {\n  await driver.execute('mobile: removeApp', { appId: APP });\n  await driver.execute('mobile: installApp', { appPath: APK });\n  await driver.execute('mobile: activateApp', { appId: APP });\n});",
   "note": "A fresh install before each test: the permission has never been asked for, and no earlier refusal counts. `activateApp` opens the app the way its icon would."
  },
  {
   "code": "  const show = await new ListScreen(driver).open(2);\n  await show.tapRemind();",
   "note": "The path of lesson 15: open the third show, then the one tap that makes the app ask."
  },
  {
   "code": "  await (await new PermissionDialog(driver).waitUntilShown()).deny();",
   "note": "Wait for Android's dialog, then press *Don't allow*. The wait matters: the dialog is drawn by another process, a moment after the tap."
  },
  {
   "code": "  assert.equal(await show.reminderIsOn(), false);\n  assert.equal(await show.explainsTheDenial(), true);",
   "note": "Back on Tickets's screen, the two things a person would see: the switch off, and the sentence saying why."
  }
 ]
}
```

Run it like lesson 15's test, with the emulator of lesson 14, which runs Android 15, and the server
running: `node --test --test-reporter=tap appium/reminder.test.mjs`. On an emulator running Android
12 or older there is no dialog, and both tests fail at the wait for it, which is the table above
telling you which device the test was written for. **These tests were not run for this course**,
for the reason lesson 15 gives: no device and no app on the recording machine.
