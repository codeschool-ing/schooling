---
title: The test scheduler decides when coroutines run
version: 1
---

Lesson 17's `WeekModel` launches its work in a scope it is given. In a test that scope is the test
itself: `runTest` hands `this`, and every coroutine launched in it runs on **the test's scheduler**,
which runs nothing until the test lets it. That is the point. The test can look at the state between
any two steps of the work, the moment a real screen would have drawn it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l18-scheduler\" aria-label=\"A virtual clock from 0 to 200 milliseconds. At 0, refresh queues the launched work and the state is Loading. advanceTimeBy(199) runs the work, which starts the source's delay of 200, and moves the clock to 199; the state is still Loading. advanceUntilIdle moves the clock to 200, where the source returns and the state becomes Loaded. No real time passes.\"><defs><marker id=\"l18-scheduler-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-scheduler-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l18-scheduler-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">the test's clock, in virtual milliseconds</text><path d=\"M60 120 L660 120\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60 114 L60 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M630 114 L630 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M660 114 L660 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><text x=\"624\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">199</text><text x=\"666\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"30\" y=\"46\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">refresh()</text><text x=\"115\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">work queued: Loading</text><path d=\"M115 96 L115 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"250\" y=\"46\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"365\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">advanceTimeBy(199)</text><text x=\"365\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">source starts delay(200): Loading</text><path d=\"M480 71 L630 71 L630 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-scheduler-ah-wire)\"></path><rect x=\"470\" y=\"168\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">advanceUntilIdle()</text><text x=\"585\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">source returns: Loaded</text><path d=\"M660 166 L660 124\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-scheduler-ah-amber)\"></path><text x=\"60\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">no real time passes</text></svg>", "caption": "The test moves the clock: the work waits in the queue until the test runs it, and the delay ends when the test says so."}
```

```kotlin
// src/test/kotlin/SchedulerTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class SchedulerTest {
    @Test
    fun launchWaitsItsTurn() = runTest {
        val model = WeekModel(this) { listOf(45, 30) }
        model.refresh()
        assertEquals(WeekUi.Loading, model.state.value)
        runCurrent()
        assertEquals(WeekUi.Loaded(listOf(45, 30)), model.state.value)
    }

    @Test
    fun timeMovesWhenTheTestSays() = runTest {
        val model = WeekModel(this) {
            delay(200)
            listOf(45, 30)
        }
        model.refresh()
        advanceTimeBy(199)
        assertEquals(WeekUi.Loading, model.state.value)
        advanceUntilIdle()
        assertEquals(WeekUi.Loaded(listOf(45, 30)), model.state.value)
        assertEquals(200, currentTime)
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests SchedulerTest
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

SchedulerTest > timeMovesWhenTheTestSays() PASSED

SchedulerTest > launchWaitsItsTurn() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

In the first test the source answers at once, and the state was still `Loading` after `refresh()`.
**`launch` queued the work and returned; nothing ran it until `runCurrent()`**, which runs every task
due at the current instant. The second test moves the clock by hand: at 199 milliseconds the source is
still waiting, and `advanceUntilIdle()` runs everything left, which ended at 200.

| call | runs |
|---|---|
| `runCurrent()` | what is due now, without moving the clock |
| `advanceTimeBy(ms)` | what falls due before `now + ms`, and moves the clock there |
| `advanceUntilIdle()` | everything, moving the clock as far as it takes |

The three are among the experimental calls of section 05, so the class carries the same `@OptIn`.
