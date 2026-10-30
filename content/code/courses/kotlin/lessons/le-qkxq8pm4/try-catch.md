---
title: try as an expression, catch and finally
version: 1
---

`try` in Kotlin is an expression, like `if` and `when`: **its value is the value of the `try` block if
nothing was thrown, or of the `catch` block that ran**.

```kotlin
// TryExpr.kt
fun minutesOrZero(text: String): Int = try {
    text.trim().toInt()
} catch (e: NumberFormatException) {
    println("not a number: '$text'")
    0
} finally {
    println("checked '$text'")
}

fun main() {
    println(minutesOrZero("45"))
    println(minutesOrZero("forty"))
}
```

```
ana@vm:~/kt/l13$ kotlinc TryExpr.kt -include-runtime -d tryexpr.jar && java -jar tryexpr.jar
checked '45'
45
not a number: 'forty'
checked 'forty'
0
```

Follow the second call. `toInt()` threw, the `catch` for `NumberFormatException` ran and its last
expression, `0`, became the value of the `try`. Then **`finally` ran, whatever happened**, before the
function returned. In the first call nothing was thrown, the `catch` was skipped, and `finally` ran
anyway. A `finally` block's own value is ignored; it is for cleanup, not for results.

## Catch what you expect, by name

`catch (e: NumberFormatException)` catches that exception and its subclasses, and nothing else. **A
`catch (e: Exception)` catches every bug as well**, and turns it into the same `0`:

```kotlin
// TooBroad.kt
fun minutesOrZero(text: String?): Int = try {
    text!!.trim().toInt()
} catch (e: Exception) {
    0
}

fun main() {
    println(minutesOrZero("forty"))
    println(minutesOrZero(null))
}
```

```
ana@vm:~/kt/l13$ kotlinc TooBroad.kt -include-runtime -d toobroad.jar && java -jar toobroad.jar
0
0
```

Both printed `0`. The second was not a student typing a word; it was a `null` that should never have
reached this function, a bug somewhere else, and the broad `catch` made it look like ordinary input.
**A catch that names the one exception you expect lets every other failure stay loud.** Lesson 15
adds a sharper reason: in coroutine code, catching `Exception` also catches the signal that cancels a
task, and the task then refuses to stop.

## Several catches

A `try` can have several `catch` blocks, tried in order, and the first whose type matches runs. Put
the most specific first: a `catch (e: Exception)` above a `catch (e: NumberFormatException)` would take
everything, and
the specific one below it would never run.
