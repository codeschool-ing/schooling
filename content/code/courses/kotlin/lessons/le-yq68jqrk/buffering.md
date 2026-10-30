---
title: A slow collector: buffer and conflate
version: 1
---

By default a flow's producer and collector take turns: the producer emits, the collector handles the
value, and only then does the producer go on. **With a slow collector, the producer spends most of its
time waiting.** Two operators change that, and they answer different questions.

```kotlin
// src/main/kotlin/FlowBuffer.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.buffer
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking
import kotlin.time.measureTime

private fun ticks(): Flow<Int> = flow {
    for (i in 1..5) {
        delay(100)
        emit(i)
    }
}

private suspend fun slowly(label: String, source: Flow<Int>) {
    val seen = mutableListOf<Int>()
    val took = measureTime {
        source.collect {
            delay(300)
            seen += it
        }
    }
    println("$label saw $seen in about ${(took.inWholeMilliseconds + 50) / 100 * 100} ms")
}

fun main() = runBlocking {
    slowly("plain   ", ticks())
    slowly("buffer  ", ticks().buffer())
    slowly("conflate", ticks().conflate())
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowBufferKt
plain    saw [1, 2, 3, 4, 5] in about 2000 ms
buffer   saw [1, 2, 3, 4, 5] in about 1600 ms
conflate saw [1, 3, 5] in about 1000 ms
```

The producer emits every 100 milliseconds and the collector takes 300 per value. The times are rounded
to the nearest hundred, because the exact figure moves a few milliseconds between runs.

- **Plain**, the two take turns, so each value costs 100 plus 300: about two seconds for five.
- **`buffer()`** runs the producer in its own coroutine, with a queue between them, so it emits all five
  without waiting and the collector works through the queue. Every value arrives, and the total is the
  collector's time plus the first tick.
- **`conflate()`** keeps only the latest value: whatever was emitted while the collector was busy
  replaces what was waiting. The collector saw fewer values and finished sooner.

## Which one

**`buffer` when every value matters**, each session written to disk, each message sent. **`conflate`
when only the latest one does**: a screen showing the current total has no use for a total that was
already out of date when it was drawn. Lesson 17's `StateFlow` behaves as if conflated, for exactly that
reason.
