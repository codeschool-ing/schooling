---
title: Enums: a fixed set of values
version: 1
---

A session is planned, running or done, and nothing else. **An enum class declares a type whose
values are exactly the ones listed**, each an object with a name and a position:

```kotlin
// Enums.kt
enum class Status(val mark: String) {
    PLANNED("[ ]"),
    RUNNING("[~]"),
    DONE("[x]"),
}

fun next(s: Status): Status = when (s) {
    Status.PLANNED -> Status.RUNNING
    Status.RUNNING -> Status.DONE
    Status.DONE -> Status.DONE
}

fun main() {
    for (s in Status.entries) println("${s.ordinal} ${s.name} ${s.mark}")
    println(next(Status.PLANNED))
    println(Status.valueOf("DONE").mark)
}
```

```
ana@vm:~/kt/l09$ kotlinc Enums.kt -include-runtime -d enums.jar && java -jar enums.jar
0 PLANNED [ ]
1 RUNNING [~]
2 DONE [x]
RUNNING
[x]
```

Each value is built with the constructor's arguments, so `mark` is a property every status carries.
`entries` lists them in declaration order, `name` is the identifier as text, `ordinal` is the
position, and `valueOf` turns a name back into a value, throwing if there is no such name.

## No `else`, and why that matters

`next` covers the three statuses and has no `else`, and it compiles, because the compiler knows the
three are all there are. **That is the property this lesson is about**: add a fourth status, and every
`when` over `Status` without an `else` stops compiling until it says what to do with the new one.

```kotlin
// EnumAdded.kt
enum class Status { PLANNED, RUNNING, PAUSED, DONE }

fun next(s: Status): Status = when (s) {
    Status.PLANNED -> Status.RUNNING
    Status.RUNNING -> Status.DONE
    Status.DONE -> Status.DONE
}

fun main() {
    println(next(Status.PAUSED))
}
```

```
ana@vm:~/kt/l09$ kotlinc EnumAdded.kt -include-runtime -d enumadded.jar
EnumAdded.kt:4:31: error: 'when' expression must be exhaustive. Add the 'PAUSED' branch or an 'else' branch.
fun next(s: Status): Status = when (s) {
                              ^^^^
```

The message names the missing branch. In a planner with forty `when`s over a status, **the compiler
has just listed every place that has to decide what pausing means**. With an `else` in each, the same
change would compile, and `PAUSED` would quietly take whatever the `else` did.

## Where an enum stops being enough

Every `Status` value is one object, the same for every session, so it can carry only what is true of
the status itself, a mark, a label. **A running session has a start time, and a done one has its
minutes; a planned one has neither.** An enum cannot hold data that differs per case and per session.
That is the gap sealed classes fill.

The `ordinal` is also a trap worth naming: it changes when somebody inserts a value in the middle of
the list, so it must never be saved to a file or a database. Save the `name`.
