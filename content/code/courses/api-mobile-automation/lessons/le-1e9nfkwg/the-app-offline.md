---
title: Tickets without a network, and on a bad one
version: 1
---

**There are two ways to give the app a bad network: take the phone's network away, or put the slow
proxy between the app and boxoffice.** The first is what a person in a lift has; the second is what
a person on a train has, and only the second is the same on every run. A test plan needs both.

## What Tickets does, read from its code

Lesson 14 wrote the app's whole network behaviour into `Shows.load`:

```
ana@laptop:~/boxoffice$ grep -n 'Timeout\|catch\|return Loaded\|Loaded\.\(Fresh\|Offline\)(' tickets/app/src/main/java/example/tickets/Shows.kt
55:            connection.connectTimeout = 5000
56:            connection.readTimeout = 5000
61:            Loaded.Fresh(shows)
62:        } catch (e: Exception) {
63:            val body = saved.getString("body", null) ?: return Loaded.Failed
64:            Loaded.Offline(parse(body), saved.getString("at", "") ?: "")
```

Read with section 02's two limits in mind: five seconds to connect (line 55), five seconds of
silence while reading (line 56). Within them, a fresh list (line 61). Past either, or on any other
error, the `catch` on line 62: the saved copy with its time if there is one (line 64), and if there
is none, `Failed`, which the list screen shows as the error line (line 63). Three things follow that
no line says outright, and each is a question for a test:

- **Nothing is shown while a load runs.** The list keeps its old rows, or none, until `display` is
  called; there is no indicator, so a refresh that waits five seconds looks like a refresh that did
  nothing.
- **"Offline" means "it did not work".** A six-second answer, through a network that works, ends
  in the banner *Offline: showing the list from…*: true about the list, false about the phone.
- **The read limit is for silence, not for the whole answer.** Java's `readTimeout` fires when no
  data arrives for that long, so an answer that trickles in a few bytes at a time can take a
  minute and never trip it.

## Taking the network away

On the emulator, from a terminal. Like everything on the device side of this lesson, these were
not run for this course, for want of an emulator (lesson 14):

```sh
adb shell svc wifi disable
adb shell svc data disable
adb shell cmd connectivity airplane-mode enable
adb shell cmd connectivity airplane-mode disable
adb shell svc wifi enable
adb shell svc data enable
```

`svc` switches Wi-Fi and mobile data separately, which is how you test a phone that falls back from
one to the other; airplane mode switches every radio at once. After each, open Tickets and press
Refresh, and compare the screen with the three outcomes above. Before trusting a test built on one
of these switches, check by hand that the request really fails on your emulator: its link to your
computer is not a real radio, and this course could not check what each switch cuts.

From Appium, the UiAutomator2 driver has the same switches: `mobile: setConnectivity`, with `{ wifi:
false, data: false }` or `{ airplaneMode: true }`, and `mobile: getConnectivity` to read them back.

## A slow network on the emulator

The emulator can slow its own network down. It can start that way, with `-netspeed` and
`-netdelay`, and its help text, which needs no emulator running, lists the profiles:

```
ana@laptop:~/boxoffice$ emulator -help-netspeed

  the Android emulator supports network throttling, i.e. slower network
  bandwidth as well as higher connection latencies. this is done either through
  skin configuration, or with '-netspeed <speed>' and '-netdelay <delay>'.

  the format of -netspeed is one of the following (numbers are kbits/s):

    -netspeed gsm          GSM/CD           (up: 1.8 KiB/s, down: 1.8 KiB/s)
    -netspeed hscsd        HSCSD            (up: 1.8 KiB/s, down: 7.0 KiB/s)
    -netspeed gprs         GPRS             (up: 3.5 KiB/s, down: 7.0 KiB/s)
    -netspeed umts         UMTS/3G          (up: 46.9 KiB/s, down: 46.9 KiB/s)
    -netspeed edge         EDGE/EGPRS       (up: 57.8 KiB/s, down: 57.8 KiB/s)
    -netspeed hsdpa        HSDPA            (up: 703.1 KiB/s, down: 1706.5 KiB/s)
    -netspeed lte          LTE              (up: 7080.1 KiB/s, down: 21118.2 KiB/s)
    -netspeed evdo         EVDO             (up: 9155.3 KiB/s, down: 34179.7 KiB/s)
    -netspeed 5g           no limit         (up: 0.0 KiB/s, down: 0.0 KiB/s)
    -netspeed full         no limit         (up: 0.0 KiB/s, down: 0.0 KiB/s)

    -netspeed <num>        select both upload and download speed
    -netspeed <up>:<down>  select individual up and down speed

  The format of -netdelay is one of the following (numbers are msec):

    -netdelay gsm          GSM/CD           (min 150, max 550)
    -netdelay hscsd        HSCSD            (min 80, max 400)
    -netdelay gprs         GPRS             (min 35, max 200)
    -netdelay umts         UMTS/3G          (min 35, max 200)
    -netdelay edge         EDGE/EGPRS       (min 80, max 400)
    -netdelay hsdpa        HSDPA            (min 0, max 0)
    -netdelay lte          LTE              (min 0, max 0)
    -netdelay evdo         EVDO             (min 0, max 0)
    -netdelay 5g           no latency       (min 0, max 0)
    -netdelay none         no latency       (min 0, max 0)
    -netdelay <num>        select exact latency
    -netdelay <min>:<max>   select min and max latencies

  the emulator uses the following defaults:

    Default network speed   is 'full'
    Default network latency is 'none'
```

So `emulator -avd Pixel_8_API_35 -netspeed edge -netdelay gprs` starts lesson 14's device on an
EDGE link with a GPRS delay. A running emulator takes the same profiles through its console:
`adb emu network speed edge` and `adb emu network delay gprs`, and Appium's `mobile: networkSpeed`,
`{ speed: 'edge' }`, does the same. The header of that help text says the numbers are kbits/s and
the table writes KiB/s; read the profile names, which are what you type, and measure the effect
rather than trusting either unit.

**The emulator's throttling is broad**: it slows everything the device does, the
system included. The slow proxy slows one server's answers, by exactly the amount you set, and can
lose them, which the emulator's settings cannot. For a test that must end the same way every time,
the proxy is the better instrument.

## The proxy in an Espresso test

The emulator reaches your computer at `10.0.2.2` (lesson 14), so it reaches the proxy at
`http://10.0.2.2:8070`, and lesson 14's network security file already allows plain HTTP to that
address on any port. Lesson 16's `OfflineTest` pointed `Shows.baseUrl` at a port where nothing
answers; this test points it at proxies that do answer, too late and just in time. Start two in two
terminals, both in front of boxoffice:

```sh
DELAY=6000 node slow-proxy.mjs
PORT=8071 DELAY=3000 node slow-proxy.mjs
```

Six seconds is past Tickets's read limit and three is inside it.
Save it as `tickets/app/src/androidTest/java/example/tickets/SlowNetworkTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/SlowNetworkTest.kt
package example.tickets

import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.IdlingRegistry
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.hamcrest.CoreMatchers.not
import org.hamcrest.CoreMatchers.startsWith
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** Two slow proxies on the computer, started before the tests:
 *  `DELAY=6000 node slow-proxy.mjs` and `PORT=8071 DELAY=3000 node slow-proxy.mjs`. */
private const val SLOWER_THAN_THE_TIMEOUT = "http://10.0.2.2:8070"
private const val SLOW_BUT_IN_TIME = "http://10.0.2.2:8071"

@RunWith(AndroidJUnit4::class)
class SlowNetworkTest {
    private val loads = ShowsIdlingResource()
    private val boxoffice = Shows.baseUrl

    @Before
    fun waitForLoads() {
        IdlingRegistry.getInstance().register(loads)
    }

    @After
    fun putBoxofficeBack() {
        Shows.baseUrl = boxoffice
        IdlingRegistry.getInstance().unregister(loads)
    }

    @Test
    fun anAnswerSlowerThanTheTimeoutShowsTheSavedCopy() {
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.shows)).check(matches(isDisplayed()))
            Shows.baseUrl = SLOWER_THAN_THE_TIMEOUT
            onView(withId(R.id.refresh)).perform(click())
            onView(withId(R.id.banner))
                .check(matches(isDisplayed()))
                .check(matches(withText(startsWith("Offline: showing the list from"))))
        }
    }

    @Test
    fun aSlowAnswerInTimeIsShownFresh() {
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.shows)).check(matches(isDisplayed()))
            Shows.baseUrl = SLOW_BUT_IN_TIME
            onView(withId(R.id.refresh)).perform(click())
            onView(withId(R.id.banner)).check(matches(not(isDisplayed())))
            onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).check(matches(isDisplayed()))
        }
    }
}
```

Both tests let the first load reach boxoffice directly, so a copy is saved, then move `baseUrl`
behind a proxy and press Refresh. The idling resource of lesson 16 keeps Espresso waiting while
`Shows.busy` is above zero, through the whole delay, so neither test needs a wait of its own. The
first expects the banner, after five seconds of silence; the second expects no banner and the list,
after three. **Together they pin the timeout from both sides**: if somebody raises it to ten
seconds, the first fails; if somebody lowers it to two, the second does. A test on one side only
would let the limit move in the other direction unnoticed.

**This class was not compiled or run for this course**, for the reasons lesson 16 gives. On your
computer it runs with the other instrumented tests, `./gradlew connectedDebugAndroidTest`, with
boxoffice and both proxies running.
