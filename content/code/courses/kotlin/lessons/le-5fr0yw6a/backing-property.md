---
title: A private MutableStateFlow and a public StateFlow
version: 1
---

If every screen could set the total, nobody would know who set it, and a bug that writes 0 could be
anywhere. Lesson 5 had the answer for lists, a private `MutableList` handed out as a `List`, and it is
the same shape here. **The class that owns the state keeps a `MutableStateFlow` private and exposes it as
a read-only `StateFlow`**; changes go through its functions.

```kotlin
// src/main/kotlin/Backing.kt
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class WeekTotal {
    private val _minutes = MutableStateFlow(0)
    val minutes: StateFlow<Int> = _minutes.asStateFlow()

    fun add(m: Int) {
        require(m > 0) { "minutes must be positive: $m" }
        _minutes.update { it + m }
    }
}

fun main() {
    val week = WeekTotal()
    week.add(45)
    week.add(30)
    println(week.minutes.value)
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=BackingKt
75
```

The underscore name for the private half is a convention the Kotlin and Android style guides both
describe: `_minutes` is the backing property, `minutes` the one the world sees. **`asStateFlow()` wraps it
so that a caller cannot cast it back to `MutableStateFlow`** and write through the cast. Writing from
outside is refused at compile time:

```kotlin
// src/main/kotlin/BackingWrite.kt
fun main() {
    val week = WeekTotal()
    week.minutes.value = 0
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=BackingWriteKt 2>&1 | head -3
e: file:///home/ana/kt/planner/src/main/kotlin/BackingWrite.kt:4:18 'val' cannot be reassigned.

FAILURE: Build failed with an exception.
```

Delete `BackingWrite.kt` after seeing the message, like `NotSuspend.kt` in lesson 14.

## `update`, not `value +=`

`_minutes.value += m` reads the value and writes a new one in two steps. If two coroutines on different
threads do it at the same moment, both can read 45 and both write 45 plus their own minutes, and one
addition is lost. **`update { it + m }` retries until its read and write happen with nothing in
between**, so concurrent additions all count. The planner is single-threaded today; `android-apps` is not,
and the habit costs nothing.
