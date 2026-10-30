---
title: One function for every answer Android can give
version: 1
---

**The difficult part of a permission is not asking; it is deciding what to offer.** Four facts
arrive from three places: the phone's Android version, whether the permission is held, Android's
advice to explain, and the app's own memory of having asked. Spread across a composable, that
becomes a tangle of `if`s that nobody can test without a phone. Gathered into one function with no
Android in it, it is a table:

```kotlin
// app/src/main/java/com/example/planner/ui/ReminderPermission.kt
package com.example.planner.ui

/** What the reminders card offers, given what Android says about the permission. */
enum class Offer { NotNeeded, Granted, Ask, Explain, OpenSettings }

fun offerFor(sdk: Int, granted: Boolean, showRationale: Boolean, askedBefore: Boolean): Offer = when {
    sdk < 33 -> Offer.NotNeeded
    granted -> Offer.Granted
    showRationale -> Offer.Explain
    askedBefore -> Offer.OpenSettings
    else -> Offer.Ask
}
```

The order of the branches is the reasoning, top to bottom:

1. **Below Android 13 there is nothing to ask.** The reminders simply work; lesson 19 section 05
   showed the same rule inside `canNotify`.
2. **Held means held**, whatever the history.
3. **If Android advises an explanation, the student has refused exactly once.** Explain, then ask.
4. **Not held, no advice, and the app asked before: refused twice.** The dialog will not appear
   again, so the only honest offer is the settings screen.
5. **Otherwise the app has never asked**, and may.

Branch 4 is the one that needs the app's memory. Without `askedBefore`, "never asked" and "refused
twice" look identical to Android's API: not held, no advice. An app that confused them would
either open Settings at a student who has never been asked, or press a button that does nothing
forever.

## The table, printed

A function with no Android in it is tested with plain JUnit, no Robolectric and no emulator:

```kotlin
// app/src/test/java/com/example/planner/ui/OfferTest.kt
package com.example.planner.ui

import org.junit.Test

class OfferTest {
    @Test fun everyCombination() {
        println("sdk  granted  rationale  askedBefore  ->  offer")
        for (sdk in listOf(32, 35)) for (granted in listOf(false, true))
            for (rationale in listOf(false, true)) for (asked in listOf(false, true)) {
                if (granted && (rationale || asked)) continue
                val offer = offerFor(sdk, granted, rationale, asked)
                println("%-4d %-8b %-10b %-12b ->  %s".format(sdk, granted, rationale, asked, offer))
            }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*OfferTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    sdk  granted  rationale  askedBefore  ->  offer
    32   false    false      false        ->  NotNeeded
    32   false    false      true         ->  NotNeeded
    32   false    true       false        ->  NotNeeded
    32   false    true       true         ->  NotNeeded
    32   true     false      false        ->  NotNeeded
    35   false    false      false        ->  Ask
    35   false    false      true         ->  OpenSettings
    35   false    true       false        ->  Explain
    35   false    true       true         ->  Explain
    35   true     false      false        ->  Granted
OfferTest > everyCombination PASSED
BUILD SUCCESSFUL in 16s
```

Every combination on Android 12 offers nothing to ask, because there is nothing. On Android 15 the
four outcomes each appear where the list above puts them. The test skips the combinations where
the permission is held together with a history, because they all give `Granted` and add only lines.

**A table is also a specification someone can disagree with.** If a designer decides that a
student who refused twice should see the card only once a week, that is one more input and one more
row, argued about in a test rather than discovered in a bug report.
