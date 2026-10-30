---
title: What a singleton costs
version: 1
---

Section 02's `Planner` object held the sessions for the whole program. **Every piece of code that
names `Planner` shares that one list, and nothing in the code says so.** That is fine until two of
them both assume they start from an empty week. Two small checks show it, written as plain functions
because lesson 18 has not introduced a test framework yet:

```kotlin
// Shared.kt
object Planner {
    val sessions = mutableListOf<Int>()
    fun total() = sessions.sum()
}

fun checkOneSession() {
    Planner.sessions.add(45)
    check(Planner.total() == 45) { "expected 45, got ${Planner.total()}" }
    println("one session: ok")
}

fun checkEmptyWeek() {
    check(Planner.total() == 0) { "expected 0, got ${Planner.total()}" }
    println("empty week: ok")
}

fun main() {
    checkOneSession()
    checkEmptyWeek()
}
```

```
ana@vm:~/kt/l10$ kotlinc Shared.kt -include-runtime -d shared.jar && java -jar shared.jar
one session: ok
Exception in thread "main" java.lang.IllegalStateException: expected 0, got 45
	at SharedKt.checkEmptyWeek(Shared.kt:14)
	at SharedKt.main(Shared.kt:20)
	at SharedKt.main(Shared.kt)
```

`check` throws `IllegalStateException` when its condition is false. **Each check is correct on its
own, and the second fails because the first ran before it.** Swap the two calls in `main` and both
pass. A failure that depends on order is the most expensive kind to find, because it appears and
disappears as the order changes, and a test framework, which may run tests in any order, will find
it at random.

## The fix: an instance, passed in

The planner's state belongs in an ordinary class, and the code that needs a planner receives one:

```kotlin
// Passed.kt
class Planner {
    private val sessions = mutableListOf<Int>()
    fun add(minutes: Int) { sessions.add(minutes) }
    fun total() = sessions.sum()
}

fun checkOneSession(planner: Planner) {
    planner.add(45)
    check(planner.total() == 45) { "expected 45, got ${planner.total()}" }
    println("one session: ok")
}

fun checkEmptyWeek(planner: Planner) {
    check(planner.total() == 0) { "expected 0, got ${planner.total()}" }
    println("empty week: ok")
}

fun main() {
    checkOneSession(Planner())
    checkEmptyWeek(Planner())
}
```

```
ana@vm:~/kt/l10$ kotlinc Passed.kt -include-runtime -d passed.jar && java -jar passed.jar
one session: ok
empty week: ok
```

Each check builds its own planner, so neither can see the other's sessions. **Handing an object the
things it depends on, instead of letting it reach for a global, is called dependency injection**, and
in its simplest form it is just a parameter. `android-apps` meets a library that automates it; the
idea underneath is the one above.

Keep `object` for what has no state, or for state that genuinely is one for the program and is safe
to share: a constant table, a formatter with no settings, a default implementation.
