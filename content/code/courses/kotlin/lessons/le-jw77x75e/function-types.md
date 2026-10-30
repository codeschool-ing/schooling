---
title: A function is a value, and it has a type
version: 1
---

Until now a function was something declared and called. **In Kotlin a function is also a value**: it
can be stored in a `val`, passed to another function and returned from one, exactly like an `Int`
or a `String`. A value has a type, and a function's type is written as its parameter types in
parentheses, an arrow, and the type it returns.

| type | reads as | an example value |
|---|---|---|
| `(Int) -> Int` | takes an `Int`, gives an `Int` | `{ m -> m + 15 }` |
| `(Int, String) -> String` | takes an `Int` and a `String`, gives a `String` | `{ m, course -> "$course: $m min" }` |
| `() -> Unit` | takes nothing, gives nothing worth having | `{ println("tick") }` |
| `(Int) -> Boolean` | a yes-or-no question about an `Int` | `{ m -> m >= 60 }` |

The values in the last column are **lambdas**: functions written inline, in braces, with no name.
Section 03 is about their syntax; here they are only the simplest way to get a function value to
look at.

```kotlin
// FunctionTypes.kt
fun main() {
    val addBreak: (Int) -> Int = { m -> m + 15 }
    val label: (Int, String) -> String = { m, course -> "$course: $m min" }
    val tick: () -> Unit = { println("tick") }
    val isLong: (Int) -> Boolean = { m -> m >= 60 }

    println(addBreak(45))
    println(label(45, "Kotlin"))
    tick()
    println(isLong(45))
    println(addBreak)
}
```

```
ana@vm:~/kt/l04$ kotlinc FunctionTypes.kt -include-runtime -d functiontypes.jar && java -jar functiontypes.jar
60
Kotlin: 45 min
tick
false
FunctionTypesKt$$Lambda/0x00007fba70000400@5451c3a8
```

A `val` holding a function is called with parentheses, as if it were the function itself:
`addBreak(45)`. Printing it without calling it shows what it is underneath: an object of a class the
JVM generated for the lambda. The numbers in that last line are an address and a hash code, and
yours will differ. Kotlin on the JVM represents every
lambda as an object with an `invoke` method, and `addBreak(45)` is `addBreak.invoke(45)` written
short.

## A nullable function type

A function type can be nullable like any other, and the parentheses matter: `(() -> Unit)?` is "a
function, or nothing", while `() -> Unit?` is "a function that returns a `Unit?`". The first is the
one you want for an optional callback, and lesson 2's tools apply to it:

```kotlin
// Callback.kt
fun finish(minutes: Int, onDone: ((Int) -> Unit)? = null) {
    println("finished $minutes min")
    onDone?.invoke(minutes)
}

fun main() {
    finish(45)
    finish(30) { m -> println("logged $m") }
}
```

```
ana@vm:~/kt/l04$ kotlinc Callback.kt -include-runtime -d callback.jar && java -jar callback.jar
finished 45 min
finished 30 min
logged 30
```

`onDone?.invoke(minutes)` is a safe call on a function value: when nobody passed a callback, nothing
is called. The second call passes its lambda after the parentheses, which section 05 explains.
