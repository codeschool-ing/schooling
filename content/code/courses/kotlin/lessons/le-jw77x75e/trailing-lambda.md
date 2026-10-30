---
title: The trailing lambda
version: 1
---

`countWhere(week, { it >= 60 })` has its lambda inside the parentheses, among the other arguments.
Kotlin has a rule that changes how most Kotlin code looks: **when the last parameter of a function
is a function, the lambda can be written after the closing parenthesis.** And when it is the only
argument, the parentheses can go entirely.

```kotlin
// Trailing.kt
fun countWhere(minutes: List<Int>, test: (Int) -> Boolean): Int {
    var count = 0
    for (m in minutes) if (test(m)) count++
    return count
}

fun main() {
    val week = listOf(45, 30, 60, 90, 20)
    println(countWhere(week, { it >= 60 }))
    println(countWhere(week) { it >= 60 })
    println(week.count { it >= 60 })
    repeat(2) { i ->
        println("session ${i + 1}")
    }
}
```

```
ana@vm:~/kt/l04$ kotlinc Trailing.kt -include-runtime -d trailing.jar && java -jar trailing.jar
2
2
2
session 1
session 2
```

The first three lines print the same number three ways. The third uses the standard library's
`count`, whose only argument is the lambda, so there are no parentheses at all. **`repeat(2) { … }`
looks like a loop the language provides, and it is an ordinary function** from the standard library,
`repeat(times: Int, action: (Int) -> Unit)`, called with a trailing lambda.

That is the point of the rule. Code written in Kotlin reads like it has new control structures, and
most of them are functions: `repeat`, `use` in lesson 13, `launch` in lesson 14, `runTest` in lesson
18. Jetpack Compose, which `android-apps` is built on, is this rule taken all the way: a screen is a
tree of function calls, each with a trailing lambda holding the calls nested inside it.

## Only the last lambda trails

A function with two function parameters can trail only the second. The first stays inside the
parentheses, and it is often clearer to name both:

```kotlin
// TwoLambdas.kt
fun check(minutes: Int, onLong: () -> Unit, onShort: () -> Unit) {
    if (minutes >= 60) onLong() else onShort()
}

fun main() {
    check(90, { println("long") }) { println("short") }
    check(30, onLong = { println("long") }, onShort = { println("short") })
}
```

```
ana@vm:~/kt/l04$ kotlinc TwoLambdas.kt -include-runtime -d twolambdas.jar && java -jar twolambdas.jar
long
short
```

The first call is legal and makes a reader stop to work out which block is which. **Use the
trailing form when the lambda is the main point of the call**, the body of the loop or the content
of the block; use names when there are two lambdas of equal weight.
