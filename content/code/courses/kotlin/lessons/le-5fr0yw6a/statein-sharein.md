---
title: stateIn and shareIn: turning a cold flow hot
version: 1
---

A cold flow runs its producer once per collector. Two screens collecting the same log would open it
twice. **`shareIn` runs a cold flow once, in a scope you give it, and shares its values with every
collector**; `stateIn` does the same and keeps the latest value as a `StateFlow`.

```kotlin
// src/main/kotlin/ShareIn.kt
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val log = flow {
        println("  opening the log")
        for (m in listOf(45, 30, 60)) {
            delay(100)
            emit(m)
        }
    }
    val shared = log.shareIn(this, SharingStarted.Eagerly, replay = 3)
    launch { shared.collect { println("screen A got $it") } }
    launch { shared.collect { println("screen B got $it") } }
    delay(500)
    coroutineContext.cancelChildren()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=ShareInKt
  opening the log
screen A got 45
screen B got 45
screen A got 30
screen B got 30
screen A got 60
screen B got 60
```

`opening the log` printed once, and both screens got all three values. The sharing runs in a coroutine
of the scope passed in, here `runBlocking`'s, and **it keeps running until that scope is cancelled**:
`cancelChildren()` at the end stops it, along with the two collectors, so the program can finish. That
is lesson 15's structure doing its job: the shared producer belongs to a scope, and does not outlive it.

## When the sharing starts and stops

`SharingStarted` decides when the producer runs:

| policy | the producer runs |
|---|---|
| `Eagerly` | from the moment `shareIn` is called, until the scope ends |
| `Lazily` | from the first collector, until the scope ends |
| `WhileSubscribed(5000)` | while anyone collects, and for five seconds after the last one leaves |

`WhileSubscribed(5000)` is the one `android-apps` uses for state from a database or the network: the
work stops when nobody is looking, and the five seconds cover a screen rotating, which on Android
destroys and rebuilds it and would otherwise restart the producer every time.
