---
title: Single-expression bodies, and if as a value
version: 1
---

When a function's body is one expression, the braces and the `return` can go, and an `=` takes
their place. **The value of the expression is the value of the function**, and the return type can
then be inferred from it:

```kotlin
// Format.kt
fun format(minutes: Int): String = "${minutes / 60} h ${minutes % 60} min"

fun isLong(minutes: Int) = minutes >= 60

fun label(minutes: Int) = if (minutes >= 60) "long" else "short"

fun main() {
    println(format(135))
    println(isLong(45))
    println(label(90))
}
```

```
ana@vm:~/kt/l03$ kotlinc Format.kt -include-runtime -d format.jar && java -jar format.jar
2 h 15 min
false
long
```

`isLong` has no return type written, and it is a `Boolean` because `>=` gives one. That inference is
convenient and has a cost: **change the expression, and the function's type changes with it**,
silently, for every caller. Write the type on a function other code depends on, as `format` does,
and leave it out on a small private helper where the body is the whole story.

## `if` is an expression

`label` uses `if` the way other languages use the ternary operator, `?:` in Java, which Kotlin does
not have because it does not need it. `if (…) a else b` has a value, and the value is whichever
branch ran. An `if` used as a value must have its `else`: without one there would be no value when
the condition is false.

```kotlin
// NoElse.kt
fun label(minutes: Int) = if (minutes >= 60) "long"

fun main() {
    println(label(90))
}
```

```
ana@vm:~/kt/l03$ kotlinc NoElse.kt -include-runtime -d noelse.jar
NoElse.kt:2:27: error: 'if' must have both main and 'else' branches when used as an expression.
fun label(minutes: Int) = if (minutes >= 60) "long"
                          ^^
```

The same holds for `when` and `try`, which lessons 9 and 13 use as values the same way. This is a
large part of why Kotlin code has fewer `var`s than Java: a name that used to be declared empty and
filled in by two branches is now declared once, with the `if` on the right.

## Block body or expression body

The choice is about reading, not about what the function can do:

| shape | use it when |
|---|---|
| `fun f(…): T = expression` | the result is one expression, and fits on a line or two |
| `fun f(…): T { … return … }` | there are steps, a loop, or an early `return` |

A single-expression body that grows to fifteen lines of nested `if`s is legal and hard to read.
When a body needs a name for an intermediate value, it has outgrown the `=`.
