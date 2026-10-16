---
title: Testing the offline banner
version: 1
---

**Tickets has two ways to fail and one way to cope, and each is a screen a test should check.**
Lesson 14 wrote them. When boxoffice cannot be reached and the app has a saved copy of the list, it
shows that copy with the banner *Offline: showing the list from HH:mm*. When it has no copy, it
shows the error line instead. Both depend on boxoffice being gone, which a person holding the phone
cannot arrange on demand. They also depend on whether a copy was saved, which that person cannot see.

A test can arrange both, from inside, and that is the gray box of section 02 earning its keep:

- for boxoffice gone, `Shows.baseUrl` is a `var`, so the test points it at an address where
  nothing answers, before the load that should fail;
- for no saved copy, the test clears the app's `SharedPreferences` file called `shows`, where the
  copy lives, before it starts.

## Which address nobody answers

"An address where nothing answers" can mean two different things, and they cost different amounts
of time. On the computer, with curl and the same five-second limit Tickets puts on its connection:

```
ana@laptop:~/boxoffice$ curl -sS --connect-timeout 5 http://localhost:9/v1/shows; echo "exit $?"
curl: (7) Failed to connect to localhost port 9 after 0 ms: Couldn't connect to server
exit 7
```

```
ana@laptop:~/boxoffice$ curl -sS --connect-timeout 5 http://10.255.255.1:8080/v1/shows; echo "exit $?"
curl: (28) Failed to connect to 10.255.255.1 port 8080 after 5002 ms: Timeout was reached
exit 28
```

**A port nothing listens on is refused at once**: the computer answers immediately that there is
nobody there, after 0 ms. **An address nobody answers at all waits for the timeout**, 5002 ms here,
because nothing ever says no. `10.255.255.1` is a private address that no machine on the recording
machine's network has. The app would behave the same way, since `Shows.load` gives its connection
5000 ms. So the test uses the first kind. From inside the emulator, `10.0.2.2` is your computer, as
lesson 14 showed. On most computers nothing listens on port 9, which makes `http://10.0.2.2:9` a
boxoffice that is down and says so at once. If your computer does run something on port 9, pick any
other port with nothing behind it.

## The test

Save it as `tickets/app/src/androidTest/java/example/tickets/OfflineTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/OfflineTest.kt
package example.tickets

import android.content.Context
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
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

/** Port 9 of the computer: nothing listens there, so a connection is refused at once. */
private const val NOBODY = "http://10.0.2.2:9"

@RunWith(AndroidJUnit4::class)
class OfflineTest {
    private val loads = ShowsIdlingResource()
    private val boxoffice = Shows.baseUrl

    @Before
    fun startWithNoSavedCopy() {
        IdlingRegistry.getInstance().register(loads)
        ApplicationProvider.getApplicationContext<Context>()
            .getSharedPreferences("shows", Context.MODE_PRIVATE)
            .edit().clear().commit()
    }

    @After
    fun putBoxofficeBack() {
        Shows.baseUrl = boxoffice
        IdlingRegistry.getInstance().unregister(loads)
    }

    @Test
    fun noServerAndNoCopyShowsTheError() {
        Shows.baseUrl = NOBODY
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.error)).check(matches(isDisplayed()))
            onView(withId(R.id.banner)).check(matches(not(isDisplayed())))
        }
    }

    @Test
    fun noServerWithACopyShowsTheBanner() {
        ActivityScenario.launch(MainActivity::class.java).use {
            onView(withId(R.id.shows)).check(matches(isDisplayed()))
            Shows.baseUrl = NOBODY
            onView(withId(R.id.refresh)).perform(click())
            onView(withId(R.id.banner))
                .check(matches(isDisplayed()))
                .check(matches(withText(startsWith("Offline: showing the list from"))))
            onView(withId(R.id.error)).check(matches(not(isDisplayed())))
        }
    }
}
```

```schooling-example
{
 "language": "kotlin",
 "file": "OfflineTest.kt",
 "parts": [
  {
   "code": "    private val boxoffice = Shows.baseUrl",
   "note": "The address before any test changed it, kept so that `@After` can put it back."
  },
  {
   "code": "        ApplicationProvider.getApplicationContext<Context>()\n            .getSharedPreferences(\"shows\", Context.MODE_PRIVATE)\n            .edit().clear().commit()",
   "note": "Clears the saved copy, the same file and name `Shows.load` uses. `commit` writes before it returns, where `apply` would write later, possibly after the activity has already read the file."
  },
  {
   "code": "    @After\n    fun putBoxofficeBack() {\n        Shows.baseUrl = boxoffice",
   "note": "All the instrumented tests run in one process, so `Shows`, a Kotlin `object`, lives from the first test to the last. A test that changed it and left it would break every test after it, in an order that depends on which ran first."
  },
  {
   "code": "        Shows.baseUrl = NOBODY\n        ActivityScenario.launch(MainActivity::class.java).use {",
   "note": "This test cannot use the rule of `ListTest`: the rule opens the activity before the test body runs, and the address has to be changed before the first load. `ActivityScenario.launch` opens it when the test says, and `use` closes it at the end."
  },
  {
   "code": "            onView(withId(R.id.error)).check(matches(isDisplayed()))\n            onView(withId(R.id.banner)).check(matches(not(isDisplayed())))",
   "note": "No server and no copy: the error line, and not the banner. Both views exist on every start, so `not(isDisplayed())` is the right check, as section 04 said."
  },
  {
   "code": "            onView(withId(R.id.shows)).check(matches(isDisplayed()))\n            Shows.baseUrl = NOBODY\n            onView(withId(R.id.refresh)).perform(click())",
   "note": "The second test lets the first load reach boxoffice, which saves a copy. The check on `shows` is there to make Espresso wait, through the idling resource, until that load is over; only then does boxoffice disappear and the button ask again."
  },
  {
   "code": "            onView(withId(R.id.banner))\n                .check(matches(isDisplayed()))\n                .check(matches(withText(startsWith(\"Offline: showing the list from\"))))",
   "note": "The banner, and its words up to the time. The time itself is when the copy was saved, which no test can know in advance, so the check stops before it."
  }
 ]
}
```

The second test needs boxoffice running, like `ListTest`. The first needs nothing at all, which
is the point of it.

**What these tests do not cover** is a network that is slow rather than gone, or one that drops
halfway through an answer. A refused connection is the easy case. Lesson 22 puts a bad network
between the app and boxoffice on purpose, and it is the harder half of the same question.
