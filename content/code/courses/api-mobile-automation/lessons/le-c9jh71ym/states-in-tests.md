---
title: The states, as tests
version: 1
---

**Section 04 predicted what Tickets keeps, and this section writes the tests that check the
prediction**, from inside with Espresso and from outside with Appium. They split the work the way
the tools allow. Espresso can recreate an activity and move it through its lifecycle, inside one
process. Appium can kill the process and answer the permission dialog. Only Appium can test the row
of the table that said *lost*.

## From inside: `ActivityScenario`

Lesson 16 opened activities with `ActivityScenario.launch`. The scenario it returns can also drive
the activity's life:

- `recreate()` destroys the activity and creates a new one with the state the old one saved.
  That is exactly what a rotation does, without rotating anything;
- `moveToState(Lifecycle.State.CREATED)` stops it, as Home does, and
  `moveToState(Lifecycle.State.RESUMED)` brings it back.

Three tests: the list survives a rotation, the list is still there after the background, and the
reminder switch stays on after a rotation. The third needs the permission granted first. Otherwise a dialog Espresso cannot answer would
appear, as section 03 showed. Android's own `UiAutomation`, which every instrumented test can reach
without a new library, grants it.
Save it as `tickets/app/src/androidTest/java/example/tickets/StatesTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/StatesTest.kt
package example.tickets

import android.Manifest
import android.content.Intent
import android.os.Build
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.IdlingRegistry
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isChecked
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class StatesTest {
    private val loads = ShowsIdlingResource()

    @Before
    fun waitForLoads() {
        IdlingRegistry.getInstance().register(loads)
    }

    @After
    fun stopWaitingForLoads() {
        IdlingRegistry.getInstance().unregister(loads)
    }

    @Test
    fun theListComesBackAfterARotation() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.recreate()
            onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun theListIsStillThereAfterTheBackground() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.moveToState(Lifecycle.State.CREATED)
            scenario.moveToState(Lifecycle.State.RESUMED)
            onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))
        }
    }

    @Test
    fun theReminderStaysOnAfterARotation() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        if (Build.VERSION.SDK_INT >= 33) {
            instrumentation.uiAutomation.grantRuntimePermission(
                instrumentation.targetContext.packageName, Manifest.permission.POST_NOTIFICATIONS)
        }
        val show = Intent(ApplicationProvider.getApplicationContext(), ShowActivity::class.java)
            .putExtra("title", "O Pagador de Promessas")
            .putExtra("seats", 4)
        ActivityScenario.launch<ShowActivity>(show).use { scenario ->
            onView(withId(R.id.remind)).perform(click()).check(matches(isChecked()))
            scenario.recreate()
            onView(withId(R.id.remind)).check(matches(isChecked()))
        }
    }
}
```

```schooling-example
{
 "language": "kotlin",
 "file": "StatesTest.kt",
 "parts": [
  {
   "code": "        ActivityScenario.launch(MainActivity::class.java).use { scenario ->\n            scenario.recreate()",
   "note": "Open the list, then rebuild it as a rotation would. The new `onCreate` starts a second load, and the idling resource of lesson 16 makes the next line wait for it."
  },
  {
   "code": "            onData(showWithId(\"sh-103\")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))",
   "note": "`onData` with a `check` instead of a `perform`: the row holding `sh-103` is on screen. `showWithId` is lesson 16's matcher, in `ListTest.kt`, and visible here because both files are in one package."
  },
  {
   "code": "            scenario.moveToState(Lifecycle.State.CREATED)\n            scenario.moveToState(Lifecycle.State.RESUMED)",
   "note": "Stopped, as in the background, then in front again. `Lifecycle` comes from AndroidX's lifecycle library, which AndroidX Test already brings."
  },
  {
   "code": "        if (Build.VERSION.SDK_INT >= 33) {\n            instrumentation.uiAutomation.grantRuntimePermission(\n                instrumentation.targetContext.packageName, Manifest.permission.POST_NOTIFICATIONS)\n        }",
   "note": "Grant the permission before the tap, on the versions that have it, so no dialog appears. This is what `GrantPermissionRule` does underneath."
  },
  {
   "code": "        val show = Intent(ApplicationProvider.getApplicationContext(), ShowActivity::class.java)\n            .putExtra(\"title\", \"O Pagador de Promessas\")\n            .putExtra(\"seats\", 4)",
   "note": "The show's screen opened directly, with the extras the list would have put in its intent. The ones left out, id, time and price, come out empty, which this test does not look at."
  },
  {
   "code": "            onView(withId(R.id.remind)).perform(click()).check(matches(isChecked()))\n            scenario.recreate()\n            onView(withId(R.id.remind)).check(matches(isChecked()))",
   "note": "On, rebuilt, still on: the `Switch` saved its own state, as section 04 predicted."
  }
 ]
}
```

**`recreate()` is not a process death**, and it is easy to believe it is. The new activity is built
in the same process, so `Shows`, its `baseUrl` and its `busy` counter are exactly as they were.
After a real process death they start again. An instrumented test cannot kill its own
process and go on running, so the process half belongs to the outside.

## From outside: Appium

Two tests in one file. The show's screen comes back after Android kills the app in the background,
and the sentence about refused notifications is still there after a rotation. The first needs the
server started with `--allow-insecure uiautomator2:adb_shell`, as section 04 showed.
Save it as `appium/states.test.mjs`:

```js
// appium/states.test.mjs: what the show's screen keeps when Android recreates it
// Needs the server started with --allow-insecure uiautomator2:adb_shell, for `am kill`.
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, afterEach, before, beforeEach, test } from 'node:test';
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

beforeEach(async () => {
  await driver.execute('mobile: removeApp', { appId: APP });
  await driver.execute('mobile: installApp', { appPath: APK });
  await driver.execute('mobile: activateApp', { appId: APP });
});

afterEach(async () => {
  await driver.setOrientation('PORTRAIT');
});

test('the show comes back after Android kills the app in the background', async () => {
  const show = await new ListScreen(driver).open(2);

  await driver.execute('mobile: backgroundApp', { seconds: -1 });
  await driver.execute('mobile: shell', { command: 'am', args: ['kill', APP] });
  assert.equal(await driver.execute('mobile: queryAppState', { appId: APP }), 1);

  await driver.execute('mobile: activateApp', { appId: APP });
  await show.waitUntilShown();
  assert.equal(await show.title(), 'O Pagador de Promessas');
});

test('a refusal is still explained after a rotation', {
  todo: 'defect: remind_denied is hidden again when ShowActivity is recreated',
}, async () => {
  const show = await new ListScreen(driver).open(2);
  await show.tapRemind();
  await (await new PermissionDialog(driver).waitUntilShown()).deny();
  assert.equal(await show.explainsTheDenial(), true);

  await driver.setOrientation('LANDSCAPE');
  await show.waitUntilShown();
  assert.equal(await show.reminderIsOn(), false);
  assert.equal(await show.explainsTheDenial(), true);
});
```

The process death is the four `execute` calls in the middle. First come Home with no return and
`am kill` through the shell. Then `queryAppState` answers `1`, *not running*, which proves the kill
happened rather than assuming it. Last, `activateApp` comes back. The test then waits for the show's
screen and checks its title, which the new process can only know from the saved intent.

**The second test is marked `todo`**, an option of `node:test`. It runs and its result is
printed, with `# TODO` and the reason beside it, but it does not fail the suite. That is the honest way to
keep a test for a defect that is known and not yet fixed. The day the fix lands, the test passes and
the report says so, and the mark comes off. Without the mark, the suite is red until the fix and everybody learns to ignore it. The next real
failure then arrives in a suite nobody reads.

**Neither file was run for this course**: no device, as before. The defect the second test is
written for comes from reading the code in section 04. The first thing to do on your emulator is to
see it with your own eyes. Refuse the permission, turn the emulator with its rotate button, and look
under the switch.

## The defect, written up

The report `manual-testing` taught, with what a developer needs to reproduce it and nothing else:

> **The reason for a refused reminder disappears when the phone is turned**
>
> **Steps.** On Android 13 or newer, with Tickets freshly installed: open *O Pagador de
> Promessas*, turn on *Remind me on the day*, press *Don't allow* in Android's dialog. Turn the
> phone to landscape.
>
> **Expected.** The switch is off and *Notifications are off for Tickets, so no reminder can be
> sent.* is shown, as before the turn.
>
> **Actual, predicted from the code and not yet seen on a device.** The switch is off and the
> sentence is gone. The same would follow from switching to the dark theme or changing the font
> size.
>
> **Cause, from the code.** `ShowActivity` shows the sentence only in `onRequestPermissionsResult`;
> a recreated activity never runs it, and a `TextView`'s visibility is not saved. Saving whether it
> was shown in `onSaveInstanceState`, and showing it again in `onCreate`, would keep it.
>
> **Test.** `appium/states.test.mjs`, *a refusal is still explained after a rotation*, marked todo.

A report says whether its *Actual* was seen or worked out, because a developer reads the two
differently. On your emulator you can replace the prediction with a sighting, and the heading with
plain *Actual*.
