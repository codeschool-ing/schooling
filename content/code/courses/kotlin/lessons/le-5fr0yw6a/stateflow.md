---
title: StateFlow: a value that can be watched
version: 1
---

`StateFlow<T>` is a hot flow with three rules, and each one exists because of how a screen uses state.

| rule | why |
|---|---|
| it always has a value, so it needs one to start with | a screen drawn before anything loads still has something to draw |
| a new collector receives the current value first | a screen that opens late is up to date at once |
| equal values are not emitted twice, and a slow collector gets only the latest | redrawing for no change, or for a value already replaced, is wasted work |

The third rule is lesson 16's `conflate()`, built in:

```kotlin
// src/main/kotlin/State.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val total = MutableStateFlow(0)
    val screen = launch {
        total.collect {
            delay(100)
            println("drew $it")
        }
    }
    delay(10)
    repeat(5) { total.value += 15 }
    delay(300)
    screen.cancel()
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=StateKt
drew 0
drew 75
```

The screen drew 0, the starting value, and took 100 milliseconds over it. Meanwhile the total moved five
times. When the screen was ready again it was given the latest value, 75, and **the four values in
between were never drawn**, which is exactly right: they were out of date before anybody could have
seen them.

## Reading without collecting

`total.value` reads the current value, from any code, without suspending. That makes a `StateFlow` usable
in plain functions and in tests, and it is the main difference from a cold flow in practice: **a state
flow is a variable that can also be watched**, where a cold flow is only ever a stream.
