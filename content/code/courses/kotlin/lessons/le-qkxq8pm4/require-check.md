---
title: require, check and error: failures with a sentence
version: 1
---

Three standard library functions throw for you, and the choice between them is a statement about whose
mistake it is:

| function | throws | means |
|---|---|---|
| `require(condition) { "…" }` | `IllegalArgumentException` | the caller passed something wrong |
| `check(condition) { "…" }` | `IllegalStateException` | this object is in the wrong state for the call |
| `error("…")` | `IllegalStateException` | this line should be unreachable |

`requireNotNull` and `checkNotNull` are the versions for a nullable value: they throw when it is
`null`, and otherwise return it with the non-null type, so the rest of the function can use it with
no `!!`.

```kotlin
// Guards.kt
class Timer {
    private var startedAt: Long? = null

    fun start(at: Long) {
        check(startedAt == null) { "already running since $startedAt" }
        startedAt = at
    }

    fun stop(at: Long): Long {
        val start = checkNotNull(startedAt) { "not running" }
        require(at >= start) { "stop at $at is before start at $start" }
        startedAt = null
        return at - start
    }
}

fun main() {
    val t = Timer()
    t.start(100)
    println(t.stop(160))
    try {
        t.stop(200)
    } catch (e: IllegalStateException) {
        println("${e::class.simpleName}: ${e.message}")
    }
    t.start(300)
    try {
        t.stop(250)
    } catch (e: IllegalArgumentException) {
        println("${e::class.simpleName}: ${e.message}")
    }
}
```

```
ana@vm:~/kt/l13$ kotlinc Guards.kt -include-runtime -d guards.jar && java -jar guards.jar
60
IllegalStateException: not running
IllegalArgumentException: stop at 250 is before start at 300
```

Stopping a timer that is not running is a misuse of the timer: `check`. Stopping it at a time before
it started is a wrong argument: `require`. **Each message names the values involved**, so the log line
is enough to understand the failure without a debugger.

## These are for bugs

`require` and `check` describe conditions that a correct program never violates. They are not a way
to handle a student typing `forty`; that is expected input, and it belongs to lesson 2's `?:`, lesson
9's sealed results or the next section's `Result`. **If a `require` fires in production, the fix is in
the code that called it**, not in a `catch` around it.
