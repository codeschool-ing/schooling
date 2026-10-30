---
title: Higher-order functions
version: 1
---

A function that takes a function as a parameter, or returns one, is called **higher-order**. The name
is grander than the idea: it is a function with a gap in it, where the caller supplies the part that
varies.

The planner wants to count sessions: the long ones, the short ones, the ones on a weekend. The
counting is the same every time and only the question changes, so the question becomes a parameter:

```kotlin
// HigherOrder.kt
fun countWhere(minutes: List<Int>, test: (Int) -> Boolean): Int {
    var count = 0
    for (m in minutes) {
        if (test(m)) count++
    }
    return count
}

fun scaledBy(factor: Int): (Int) -> Int = { it * factor }

fun main() {
    val week = listOf(45, 30, 60, 90, 20)
    println(countWhere(week, { it >= 60 }))
    println(countWhere(week, { it < 30 }))
    val triple = scaledBy(3)
    println(triple(20))
    println(scaledBy(2)(45))
}
```

```
ana@vm:~/kt/l04$ kotlinc HigherOrder.kt -include-runtime -d higherorder.jar && java -jar higherorder.jar
2
1
60
90
```

`countWhere` takes a list and a `(Int) -> Boolean`, and calls `test(m)` for each item. **The loop is
written once**, and every question about sessions is now one line at the call. Without it each
question would be its own loop, five lines each, with the one line that differs buried in the
middle.

`scaledBy` goes the other way: it **returns** a function. `scaledBy(3)` builds a lambda that
multiplies by 3 and hands it back, and `triple(20)` calls it. The last line calls the returned
function immediately, `scaledBy(2)(45)`, which is legal and rarely clearer than naming it first.

## This is most of the standard library

Lesson 5 is a tour of functions shaped exactly like `countWhere`: `count`, `filter`, `map`, `any`,
`sortedBy`, `groupBy`. Each takes a collection and a lambda, and **each replaces a loop you would
otherwise write by hand**. The standard library already has `count`, so in real code `countWhere`
is `week.count { it >= 60 }`, which the next section explains.

## What a function parameter costs

Each lambda passed to `countWhere` is an object, created at the call. For a function called a few
times that is nothing. For one called in a tight loop on a phone, it is an allocation per call,
which is what section 08's `inline` removes, and why the standard library's collection functions
are all declared `inline`.
