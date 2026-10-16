---
title: Teaching Espresso to wait for the load
version: 1
---

**The test class of section 03 has a race in it, and on a fast machine it will often pass anyway.** When the rule
opens `MainActivity`, its `onCreate` starts a thread that asks boxoffice for the shows, and returns.
The main thread is then idle, so Espresso goes straight on to `onData(showWithId("sh-103"))`. If
the answer from boxoffice has already arrived and the list is filled, the test passes. If it has
not, the list has no data yet, and the test fails, having found no show to tap.

On an emulator talking to boxoffice on the same computer, the answer is likely to win. On a slower
machine, a busy CI runner or a phone on Wi-Fi, it sometimes loses, and the test fails now and then
with nothing in the report that points at the cause:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 332\" role=\"img\" aria-label=\"Four lanes against time. On the main thread, onCreate raises busy and starts the load, and much later busy is lowered once the list is drawn. On the load thread in between, the request GET /v1/shows waits for boxoffice. A test without an idling resource calls onData while the request is still out and finds no data. A test with the idling resource waits for as long as busy is above zero and calls onData after the list is drawn.\"><defs><marker id=\"f16race-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main thread</text><line x1=\"160\" y1=\"70\" x2=\"690\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"150\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load thread</text><line x1=\"160\" y1=\"130\" x2=\"690\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"150\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test, no idling</text><line x1=\"160\" y1=\"190\" x2=\"690\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"150\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test, with idling</text><line x1=\"160\" y1=\"250\" x2=\"690\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"425\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text><line x1=\"380\" y1=\"30\" x2=\"410\" y2=\"30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"440\" y1=\"30\" x2=\"470\" y2=\"30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#f16race-ah)\"></line><rect x=\"165\" y=\"52\" width=\"120\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">busy++</text><text x=\"225\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">starts the load</text><rect x=\"295\" y=\"112\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /v1/shows</text><text x=\"395\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">waiting for boxoffice</text><rect x=\"505\" y=\"52\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">busy--</text><text x=\"580\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the list is drawn</text><line x1=\"285\" y1=\"76\" x2=\"300\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f16race-ah)\"></line><line x1=\"495\" y1=\"130\" x2=\"510\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f16race-ah)\"></line><rect x=\"295\" y=\"172\" width=\"160\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onData</text><text x=\"375\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">no data yet: fails</text><rect x=\"295\" y=\"236\" width=\"360\" height=\"28\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"475\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">Espresso waits while busy is above zero</text><rect x=\"590\" y=\"272\" width=\"95\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"637.5\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">onData</text><line x1=\"637\" y1=\"264\" x2=\"637\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f16race-ah)\"></line><text x=\"425\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the main thread is idle the whole time the load is out, so Espresso alone does not wait</text></svg>", "caption": "Between busy++ and busy-- the main thread has nothing to do, so Espresso sees an idle app; the idling resource makes it wait for the load."}
```

## Where the app counts its loads

Lesson 14 wrote Tickets with this test in mind. `Shows.busy` counts the loads in flight, and the
list screen raises it before starting a load and lowers it after the result is on the screen:

```
ana@laptop:~/boxoffice$ grep -n busy tickets/app/src/main/java/example/tickets/*.kt
tickets/app/src/main/java/example/tickets/MainActivity.kt:39:        Shows.busy++
tickets/app/src/main/java/example/tickets/MainActivity.kt:44:                Shows.busy--
tickets/app/src/main/java/example/tickets/Shows.kt:39:    var busy = 0
```

Line 39 of `MainActivity.kt` raises it on the main thread, before the thread starts; line 44 lowers
it on the main thread too, inside `runOnUiThread`, after `display` has filled the list. So **while
`busy` is above zero, the screen is not finished**, and when it is back to zero, it is.

## An idling resource

Espresso's way of being told about work it cannot see is an **idling resource**: an object with a
name that answers one question, *are you idle now?*, and that calls Espresso back when the answer
turns to yes. Espresso asks every registered resource before every step, and waits while any of
them says no. Save it as `tickets/app/src/androidTest/java/example/tickets/ShowsIdlingResource.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/ShowsIdlingResource.kt
package example.tickets

import android.os.Handler
import android.os.Looper
import androidx.test.espresso.IdlingResource

/** Tells Espresso that Tickets is busy while a load of the shows is running. */
class ShowsIdlingResource : IdlingResource {
    private val mainThread = Handler(Looper.getMainLooper())
    private var callback: IdlingResource.ResourceCallback? = null

    override fun getName() = "Shows.busy"

    override fun isIdleNow(): Boolean {
        val idle = Shows.busy == 0
        if (idle) {
            callback?.onTransitionToIdle()
        } else {
            mainThread.postDelayed({ isIdleNow() }, 100)
        }
        return idle
    }

    override fun registerIdleTransitionCallback(callback: IdlingResource.ResourceCallback) {
        this.callback = callback
    }
}
```

`isIdleNow` answers from `Shows.busy`. Nothing in the app tells the resource when `busy` drops, so
while it is busy the resource asks itself again a tenth of a second later, on the main thread, and
calls Espresso back the first time the answer is zero. The name is what Espresso prints if it ever
gives up waiting.

The test class registers the resource before each test and removes it after. Replace the file;
save it as `tickets/app/src/androidTest/java/example/tickets/ListTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/ListTest.kt
package example.tickets

import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.IdlingRegistry
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.BoundedMatcher
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.hamcrest.Description
import org.hamcrest.Matcher
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** A row of the list, chosen by the show it holds rather than by its position. */
fun showWithId(id: String): Matcher<Any> =
    object : BoundedMatcher<Any, Show>(Show::class.java) {
        override fun describeTo(description: Description) {
            description.appendText("a show with id $id")
        }

        override fun matchesSafely(item: Show) = item.id == id
    }

@RunWith(AndroidJUnit4::class)
class ListTest {
    @get:Rule
    val activity = ActivityScenarioRule(MainActivity::class.java)

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
    fun theRefreshButtonIsShown() {
        onView(withId(R.id.refresh)).check(matches(isDisplayed()))
    }

    @Test
    fun aShowOpensWithItsTitleAndPrice() {
        onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).perform(click())
        onView(withId(R.id.title)).check(matches(withText("O Pagador de Promessas")))
        onView(withId(R.id.price)).check(matches(withText("R$ 65,00")))
    }
}
```

`IdlingRegistry` is Espresso's list of resources. **Unregistering matters as much as registering**:
a resource left behind keeps answering, through every test class that runs after it, for a test
that has finished.

## Why not `Thread.sleep`

`Thread.sleep(2000)` before the first `onData` fixes the race on the day it is written, and it
is the same mistake as lesson 15's fixed pause. It makes every run two seconds
slower whether the load took fifty milliseconds or none; it still fails the day a load takes two
and a half; and it hides from the reader *what* the test waits for. The idling resource waits
exactly as long as the load takes, fails with a name when it never ends, and says in the code what
the app is doing.

**If the app's developers can change the app, there is a tidier way.** Espresso publishes a small
library, `espresso-idling-resource`, with a `CountingIdlingResource` the app itself raises and
lowers around its work, which calls Espresso back the moment it reaches zero. Tickets uses only
Android's own classes, so this course keeps the counter in the app and the resource in the tests;
in a team, asking the developers for the counting resource is a fair request, and the same
argument as lesson 14's about ids: the app helps its tests, on purpose.
