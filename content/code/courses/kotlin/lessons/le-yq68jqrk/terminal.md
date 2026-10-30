---
title: Terminal operators: collecting a result
version: 1
---

`collect` is one way to end a flow. **A terminal operator is a suspending function that runs the flow
and returns something other than a flow**, and the library has the ones you would expect from lesson 5:

```kotlin
// src/main/kotlin/FlowTerminal.kt
import kotlinx.coroutines.flow.count
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.fold
import kotlinx.coroutines.flow.runningFold
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val week = flowOf(45, 30, 60)
    println(week.toList())
    println(week.first())
    println(week.fold(0) { total, m -> total + m })
    println(week.count { it >= 45 })
    println(week.runningFold(0) { total, m -> total + m }.toList())
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowTerminalKt
[45, 30, 60]
45
135
2
[0, 45, 75, 135]
```

`flowOf` builds a flow of fixed values. Each line ran the flow again, because it is cold, and each
terminal operator collected it in its own way. `first()` stopped the flow after one value, like
`take(1)`; `fold` and `count` collected all three. `runningFold` is not terminal: it is an operator
that emits each running total, and `toList()` after it is what collected them.

| terminal | returns |
|---|---|
| `collect { … }` | `Unit`, when the flow ends |
| `toList()`, `toSet()` | every value |
| `first()`, `firstOrNull()` | the first value, then cancels the rest |
| `fold`, `reduce` | one accumulated value |
| `count` | how many values passed the test |

## When to collect into a list

`toList()` waits for the flow to finish. **On a flow that never ends, a terminal operator that needs
every value never returns**, and the coroutine waits forever. `toList()` is right for a flow known to
be finite, the lines of a file, a page of results, and wrong for anything that represents a value
changing over time, which is collected value by value as it arrives.
