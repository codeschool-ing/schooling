---
title: The assertions kotlin.test gives you
version: 1
---

`assertEquals` is most of what a test needs. The rest of `kotlin.test` covers the cases where equality is
the wrong question:

| assertion | passes when |
|---|---|
| `assertEquals(expected, actual)` | the two are equal, by `==` |
| `assertTrue(condition)` / `assertFalse(condition)` | the condition is `true` / `false` |
| `assertNull(x)` / `assertNotNull(x)` | `x` is `null` / is not, and `assertNotNull` returns it as non-null |
| `assertIs<T>(x)` | `x` is a `T`, and returns it smart-cast to `T` |
| `assertFailsWith<E> { … }` | the block throws an `E`, and returns the exception |
| `assertContains(collection, element)` | the element is in the collection |

The last two return something, and that is what makes them useful: a test can go on to check the
exception's message, or a property of the subtype. Lesson 17's `WeekTotal` refuses minutes that are not
positive, and a test can hold it to that:

```kotlin
// src/test/kotlin/WeekTotalTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs

class WeekTotalTest {
    @Test
    fun addsUp() {
        val week = WeekTotal()
        week.add(45)
        week.add(30)
        assertEquals(75, week.minutes.value)
    }

    @Test
    fun refusesZero() {
        val e = assertFailsWith<IllegalArgumentException> { WeekTotal().add(0) }
        assertEquals("minutes must be positive: 0", e.message)
    }

    @Test
    fun loadedCarriesItsSessions() {
        val state: WeekUi = WeekUi.Loaded(listOf(45, 30))
        val loaded = assertIs<WeekUi.Loaded>(state)
        assertEquals(2, loaded.sessions.size)
    }
}
```

`--tests` runs one class, or one test, instead of all of them:

```
ana@vm:~/kt/planner$ ./gradlew test --tests WeekTotalTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :compileKotlin UP-TO-DATE
> Task :compileJava NO-SOURCE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

WeekTotalTest > addsUp() PASSED

WeekTotalTest > refusesZero() PASSED

WeekTotalTest > loadedCarriesItsSessions() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

**`refusesZero` tests a failure, and passes because the failure happened.** A refusal is behaviour like
any other, and the day somebody removes the `require`, this is the test that says so.
`assertIs` returned `state` typed as `WeekUi.Loaded`, so `loaded.sessions` compiled with no cast, the
same smart cast lesson 9's `is` gave.

`assertEquals` compares with `==`, which is why lesson 8's data classes make tests short: two `Loaded`
values with the same list are equal, and a test can state the whole expected state in one line.
