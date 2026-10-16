---
title: Where the tests live, and what they need
version: 1
---

**The project Android Studio made in lesson 14 is already set up for Espresso.** The template put
two test folders beside `src/main`, wrote the libraries they need into the build files, and left an
example test in each. You add files; you change no build file.

| folder | what runs there | runs on |
|---|---|---|
| `app/src/test/` | local tests, on your computer's Java runtime | your computer, no Android |
| `app/src/androidTest/` | instrumented tests: Espresso | the device, inside the app |
| `app/src/main/` | the app itself | the device |

Inside `androidTest`, the template made the folders of the package, `java/example/tickets/`, and a
file in it called `ExampleInstrumentedTest.kt`, which checks the app's package name. It can stay or
go; the tests of this lesson go beside it.

## What the template already declares

Open `tickets/app/build.gradle.kts`. Two parts of it concern this lesson. In `defaultConfig`, the
runner that the test APK hands to Android's instrumentation:

```kotlin
testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
```

And at the bottom, among the dependencies, three lines for tests:

```kotlin
testImplementation(libs.junit)
androidTestImplementation(libs.androidx.junit)
androidTestImplementation(libs.androidx.espresso.core)
```

`testImplementation` is for the local tests and `androidTestImplementation` for the instrumented
ones; neither goes into the app a user installs. The names after `libs.` point into
`tickets/gradle/libs.versions.toml`, where the template wrote which versions; leave them as it chose.

| name in the build file | the library | what it gives a test |
|---|---|---|
| `libs.junit` | JUnit 4 | `@Test`, `@Before`, `@After`, the rules: the frame every test here uses |
| `libs.androidx.junit` | AndroidX Test's JUnit extensions | `AndroidJUnit4`, the runner a test class names, and `ActivityScenarioRule`, which opens an activity for each test |
| `libs.androidx.espresso.core` | Espresso | `onView`, `onData`, the matchers, actions and assertions, and the idling resources of section 05 |

The second and third bring the rest of AndroidX Test with them, including `ActivityScenario` and
`ApplicationProvider`, which section 06 uses.

## A first test class

Two tests: the refresh button is on the screen, and tapping the show `sh-103` opens it with its
title and price. Make the file in `androidTest/java/example/tickets/`: in the *Project* view,
right-click the package and choose *New › Kotlin Class/File*.
Save it as `tickets/app/src/androidTest/java/example/tickets/ListTest.kt`:

```kotlin
// tickets/app/src/androidTest/java/example/tickets/ListTest.kt
package example.tickets

import androidx.test.espresso.Espresso.onData
import androidx.test.espresso.Espresso.onView
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

The values the second test expects are boxoffice's, as lesson 1 read them. The price is 6500
cents, which the app's `price()` writes as `R$ 65,00`:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows | jq -r '.shows[] | "\(.id)  \(.price_cents)  \(.title)"'
sh-101  8000  Auto da Compadecida
sh-102  8000  Auto da Compadecida
sh-103  6500  O Pagador de Promessas
```

Section 04 reads the class piece by piece. One warning before that: **this version is flaky**, and
section 05 says why and fixes it.

**None of the test code in this lesson was compiled or run for this course.** It needs AndroidX
Test, which comes from Google's own repository, and the recording machine can reach neither that
repository nor an emulator. It is written against the parts of Espresso that have not changed in
years, and section 07 says how to run it.
