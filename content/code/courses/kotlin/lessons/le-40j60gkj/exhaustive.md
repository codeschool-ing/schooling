---
title: The when the compiler forces you to finish
version: 1
---

The payoff of a sealed hierarchy arrives the day it changes. The planner gains a fourth shape: a
session the student skipped, with a reason.

```kotlin
// Skipped.kt
sealed class Session {
    data class Planned(val course: String, val minutes: Int) : Session()
    data class Running(val course: String, val startedAt: String) : Session()
    data class Done(val course: String, val minutes: Int) : Session()
    data class Skipped(val course: String, val reason: String) : Session()
}

fun describe(s: Session): String = when (s) {
    is Session.Planned -> "${s.course}: ${s.minutes} min planned"
    is Session.Running -> "${s.course}: running since ${s.startedAt}"
    is Session.Done -> "${s.course}: ${s.minutes} min done"
}

fun main() {
    println(describe(Session.Skipped("Kotlin", "ill")))
}
```

```
ana@vm:~/kt/l09$ kotlinc Skipped.kt -include-runtime -d skipped.jar
Skipped.kt:9:36: error: 'when' expression must be exhaustive. Add the 'is Skipped' branch or an 'else' branch.
fun describe(s: Session): String = when (s) {
                                   ^^^^
```

**The compiler refused, and named both the missing branch and the way out.** Every `when` over
`Session` in the planner fails the same way, so adding a shape produces a list of every place that has
to handle it, with file and line. Nothing reaches a student's phone half-handled.

## The `else` that turns it off

The message offers two fixes, and the second is the trap:

```kotlin
// SkippedElse.kt
sealed class Session {
    data class Planned(val course: String, val minutes: Int) : Session()
    data class Running(val course: String, val startedAt: String) : Session()
    data class Done(val course: String, val minutes: Int) : Session()
    data class Skipped(val course: String, val reason: String) : Session()
}

fun describe(s: Session): String = when (s) {
    is Session.Planned -> "${s.course}: ${s.minutes} min planned"
    is Session.Done -> "${s.course}: ${s.minutes} min done"
    else -> "${s} is in progress"
}

fun main() {
    println(describe(Session.Running("Android", "14:30")))
    println(describe(Session.Skipped("Kotlin", "ill")))
}
```

```
ana@vm:~/kt/l09$ kotlinc SkippedElse.kt -include-runtime -d skippedelse.jar && java -jar skippedelse.jar
Running(course=Android, startedAt=14:30) is in progress
Skipped(course=Kotlin, reason=ill) is in progress
```

With `else`, the skipped session compiled and was described as **in progress**, which is false. The
`else` was written when it meant "running", and it went on meaning "everything not listed above",
including shapes that did not exist when it was written. **An `else` on a sealed type trades a compile
error today for a wrong answer later.** Write one branch per subtype, and let the compiler find the
places a new one has to go.

## Exhaustive for statements too

Since Kotlin 1.7, a `when` over a sealed type or an enum must be exhaustive even when it is a
statement whose value is not used. Before that, only `when` used as a value was checked, and a
`when` that did something in each branch could silently miss a case. Every Kotlin you install today
checks both.
