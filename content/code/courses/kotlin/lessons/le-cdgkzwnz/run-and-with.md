---
title: run and with, for computing a result
version: 1
---

`run` and `with` both make the object the receiver and return the block's result. They are `apply`
with the other answer to the second question: **use them when the block computes something from the
object**, and the object itself is not what you want back.

```kotlin
// RunWith.kt
fun main() {
    val sessions = listOf(45, 30, 60, 20)

    val summary = sessions.run {
        val total = sum()
        val longest = max()
        "$size sessions, $total min, longest $longest"
    }
    println(summary)

    val text = with(StringBuilder()) {
        append("Kotlin")
        append(" · ")
        append(sessions.sum())
        toString()
    }
    println(text)

    val goal = run {
        val perDay = 45
        val days = 5
        perDay * days
    }
    println(goal)
}
```

```
ana@vm:~/kt/l06$ kotlinc RunWith.kt -include-runtime -d runwith.jar && java -jar runwith.jar
4 sessions, 155 min, longest 60
Kotlin · 155
225
```

`sessions.run { … }` uses `sum()`, `max()` and `size` without a prefix, and the last expression, the
template, is the result. **The `val`s inside the block exist only there**, so `total` and `longest`
do not leak into the rest of `main`.

## `with` is `run` with the object in parentheses

`with(x) { … }` and `x.run { … }` do the same thing. `with` is not an extension: the object is a
normal argument, and the block trails it. The usual reading is **`with` for "with this object, do
several things"**, as with the builder above, where `toString()` at the end makes the result a
`String` rather than the builder. `x.run` fits at the end of a chain or behind `?.`, where `with`
cannot go: there is no `?.with`.

## `run` with no object

The last block is `run` called on nothing at all. It is a block that computes a value with names of
its own and gives back the last expression. **It scopes temporary names**, `perDay` and `days`, to
the computation that needs them, so the function around it does not end with a dozen `val`s nobody
reads twice.
