---
title: Hot and cold
version: 1
---

Lesson 16's flows were cold: a recipe that runs once per collector, from the start, and does nothing
while nobody collects. That is right for reading a log. It is wrong for **the state of a screen**: the
week's total exists whether or not anything is drawing it, a screen that opens late should see the
current total and not a replay of how it got there, and two screens showing it should see the same
number, not run two producers.

**A hot flow exists independently of its collectors**: it has a current value or a stream of events,
collectors come and go, and they see what is happening from the moment they arrive.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l17-hotcold\" aria-label=\"Two panels. Left, a cold Flow: two collectors, each with its own run of the producer, each receiving 45, 30, 60 from the start. Right, a hot StateFlow: one holder with a current value, 75; a collector that arrives early sees every change from then on, a collector that arrives late is given 75 at once and then later changes, and the holder exists with or without collectors.\"><defs><marker id=\"l17-hotcold-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-hotcold-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">cold Flow</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">hot StateFlow</text><rect x=\"30\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"90\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">producer run</text><text x=\"90\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45 30 60</text><path d=\"M152 75 L208 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-phosphor)\"></path><rect x=\"210\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">collector</text><rect x=\"30\" y=\"140\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"90\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">producer run</text><text x=\"90\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45 30 60</text><path d=\"M152 165 L208 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-phosphor)\"></path><rect x=\"210\" y=\"140\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">collector 2</text><text x=\"180\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">one run per collector, from the start</text><rect x=\"420\" y=\"90\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">value</text><text x=\"480\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">75</text><path d=\"M542 105 L598 70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-amber)\"></path><path d=\"M542 135 L598 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-hotcold-ah-amber)\"></path><rect x=\"600\" y=\"45\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">early</text><text x=\"655\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every change</text><rect x=\"600\" y=\"145\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">late</text><text x=\"655\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">75, then changes</text><text x=\"540\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">one holder, with or without collectors</text></svg>", "caption": "A cold flow runs once per collector; a StateFlow holds one current value that every collector shares."}
```

```kotlin
// src/main/kotlin/Hot.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val minutes = MutableStateFlow(0)
    minutes.value = 45
    minutes.value = 75
    println("current: ${minutes.value}")

    val watcher = launch {
        minutes.collect { println("watcher sees $it") }
    }
    delay(50)
    minutes.value = 135
    delay(50)
    minutes.value = 135
    delay(50)
    watcher.cancel()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=HotKt
current: 75
watcher sees 75
watcher sees 135
```

The value changed twice before anybody watched, and nothing was lost by that: **`minutes.value` always
holds the current value**, readable at any moment without collecting. The watcher arrived and was given
75 at once, the current value, not the history. It saw 135 when it was set, and did not see the second
135, because the value had not changed.

The watcher had to be cancelled. **Collecting a hot flow never ends on its own**, because the flow has
no end: there is always a current value and possibly another one coming. That is why lesson 16 said a
screen collects in a coroutine of its own, and stops when the screen goes away.
