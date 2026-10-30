---
title: A hundred thousand coroutines
version: 1
---

The claim behind coroutines is that they are cheap: **a suspended coroutine is a small object on the
heap, not a thread with its own stack**. A thread on the JVM reserves its stack, half a megabyte or
more, from the moment it starts, and the operating system schedules every one of them. A program can
have thousands of threads; it can have hundreds of thousands of coroutines.

```kotlin
// src/main/kotlin/Many.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.measureTime

fun main() {
    val done = AtomicInteger()
    val took = measureTime {
        runBlocking {
            repeat(100_000) {
                launch {
                    delay(1000)
                    done.incrementAndGet()
                }
            }
        }
    }
    println("${done.get()} coroutines finished")
    println("in about ${took.inWholeMilliseconds / 1000} s, on one thread")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=ManyKt
100000 coroutines finished
in about 1 s, on one thread
```

A hundred thousand coroutines each waited one second, and the whole program took about one second,
on the single thread `runBlocking` uses. **Every coroutine was suspended at `delay` at the same time**,
which cost each of them a small object and nothing more. `AtomicInteger` is a counter that is safe to
increment from several places, which this program does not strictly need on one thread and which
becomes necessary the moment the coroutines move to `Dispatchers.Default`.

## What it would cost with threads

The same program with `thread { Thread.sleep(1000) }` in place of `launch { delay(1000) }` asks the
operating system for a hundred thousand threads. Depending on the machine's limits it either takes
gigabytes of memory for the stacks or fails with `OutOfMemoryError: unable to create native thread`.
It was not run when this course was recorded, because a program designed to exhaust the recording
machine is not a demonstration worth its risk; you can try it on your own machine with a smaller
number and watch the memory climb.

Java 21 has virtual threads, which apply the same idea to `Thread` itself. **Coroutines add what
virtual threads do not**: structured concurrency, cancellation that propagates, and `Flow`, which are
lessons 15 to 17, and they run unchanged on Android, where virtual threads are not available.
