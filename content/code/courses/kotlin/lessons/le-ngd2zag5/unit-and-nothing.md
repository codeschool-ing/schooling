---
title: Unit and Nothing, the two return types with no value
version: 1
---

Every Kotlin function returns something, including the ones that look as if they return nothing.
Two types make that work, and the second of them explains a piece of lesson 2 that was left
unexplained: how `?: return` and `?: throw` can sit where a value belongs.

## `Unit`: finished, nothing to report

A function with no return type written, and a block body, returns `Unit`. `Unit` is a type with
exactly one value, also called `Unit`, so returning it says "this function finished" and carries no
information. It plays the part of Java's `void`, with one difference: **it is a real value**, which
you can store and print.

```kotlin
// UnitNothing.kt
fun log(message: String) {
    println("> $message")
}

fun fail(message: String): Nothing = throw IllegalStateException(message)

fun minutesFrom(input: String): Int = input.toIntOrNull() ?: fail("not a number: $input")

fun main() {
    val result = log("planned 45 min")
    println(result)
    println(minutesFrom("45"))
    println(minutesFrom("forty"))
}
```

```
ana@vm:~/kt/l03$ kotlinc UnitNothing.kt -include-runtime -d unitnothing.jar && java -jar unitnothing.jar
> planned 45 min
kotlin.Unit
45
Exception in thread "main" java.lang.IllegalStateException: not a number: forty
	at UnitNothingKt.fail(UnitNothing.kt:6)
	at UnitNothingKt.minutesFrom(UnitNothing.kt:8)
	at UnitNothingKt.main(UnitNothing.kt:14)
	at UnitNothingKt.main(UnitNothing.kt)
```

`println(result)` printed `kotlin.Unit`, the name of the one value. That `Unit` is a value matters
more than it seems once functions are passed around as values in lesson 4: a function "that returns
nothing" is a function that returns `Unit`, and it fits anywhere a function returning some type is
expected, with no special case.

## `Nothing`: never finishes

`fail` is declared to return `Nothing`. **`Nothing` is the type with no values at all**, so a
function that returns it can never return normally: it throws, or loops forever. The compiler
knows that, and uses it.

Because `Nothing` has no values, the compiler treats it as fitting any type: there is no value of it
that could ever be the wrong type. That is why `minutesFrom` compiles. `?:` needs an `Int` on the
right, and `fail(…)` is `Nothing`, which fits. **`throw` and `return` are expressions of type
`Nothing` too**, which is the whole explanation of lesson 2's `?: return` and `?: throw`.

The compiler also knows that code after a call to `fail` can never run, and warns about it as
unreachable. A helper like `fail` is worth writing for exactly that: one place that builds the
message and the exception, and every caller still type-checks as if it returned the value it was
supposed to.

The standard library already has two such helpers. `error(message)` throws `IllegalStateException`,
and `TODO()` throws `NotImplementedError`; both are declared to return `Nothing`. `TODO()` is worth
knowing in particular, because it lets a half-written function compile:

```kotlin
// Todo.kt
fun weeklyGoal(course: String): Int = TODO("goals arrive in lesson 7")

fun main() {
    println("planner starting")
    println(weeklyGoal("Kotlin"))
}
```

```
ana@vm:~/kt/l03$ kotlinc Todo.kt -include-runtime -d todo.jar && java -jar todo.jar
planner starting
Exception in thread "main" kotlin.NotImplementedError: An operation is not implemented: goals arrive in lesson 7
	at TodoKt.weeklyGoal(Todo.kt:2)
	at TodoKt.main(Todo.kt:6)
	at TodoKt.main(Todo.kt)
```

The program compiles and runs, and stops at the first call that reaches the unfinished function, with
the reason in the message.
