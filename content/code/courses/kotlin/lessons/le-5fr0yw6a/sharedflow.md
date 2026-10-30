---
title: SharedFlow: events, not state
version: 1
---

Some things a screen observes are not state. "Session saved" is a message to show once; it has no
current value, and two identical messages in a row are two messages, not one. A `StateFlow` would drop
the second one as a repeat, and would hand the old message to every screen that opens later. **A
`SharedFlow` is a hot stream of events**: it has no current value, delivers every emission to the
collectors present, and replays a configurable number of past events to new ones, zero by default.

```kotlin
// src/main/kotlin/SharedEvents.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val messages = MutableSharedFlow<String>()
    val early = launch { messages.collect { println("early screen: $it") } }
    delay(10)
    messages.emit("session saved")
    messages.emit("session saved")
    val late = launch { messages.collect { println("late screen: $it") } }
    delay(10)
    messages.emit("goal reached")
    delay(10)
    early.cancel()
    late.cancel()

    val withReplay = MutableSharedFlow<String>(replay = 1)
    withReplay.emit("week exported")
    val opened = launch { withReplay.collect { println("opened later: $it") } }
    delay(10)
    opened.cancel()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SharedEventsKt
early screen: session saved
early screen: session saved
early screen: goal reached
late screen: goal reached
opened later: week exported
```

The early screen got both `session saved` messages, because a shared flow does not drop repeats. The late
screen missed them, having arrived after they were emitted, and got `goal reached` like the early one.
With `replay = 1`, a collector that arrives later is first given the last event.

## Which one for what

**State, which always has a value and whose latest value is all that matters: `StateFlow`.** The week's
total, the list of sessions, whether loading is in progress. **Events, each of which matters once:
`SharedFlow`**, with no replay so that a screen opening later does not show yesterday's message again.
Choosing the wrong one produces the two classic screen bugs: a message that shows twice, or one that
never shows.
