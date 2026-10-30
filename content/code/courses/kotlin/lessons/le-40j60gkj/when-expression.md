---
title: when, the switch that is an expression
version: 1
---

`when` is Kotlin's answer to `switch`, and it does more in less. **It picks the first branch whose
condition matches, and like `if` it is an expression**, so its value can be returned or stored.

```kotlin
// When.kt
fun label(minutes: Int): String = when {
    minutes <= 0 -> "nothing"
    minutes < 30 -> "short"
    minutes < 90 -> "normal"
    else -> "long"
}

fun dayKind(day: Int) = when (day) {
    1, 7 -> "weekend"
    in 2..6 -> "weekday"
    else -> "not a day"
}

fun main() {
    for (m in listOf(0, 20, 45, 120)) println("$m: ${label(m)}")
    println(dayKind(7))
    println(dayKind(3))
    println(dayKind(9))
}
```

```
ana@vm:~/kt/l09$ kotlinc When.kt -include-runtime -d when.jar && java -jar when.jar
0: nothing
20: short
45: normal
120: long
weekend
weekday
not a day
```

Two shapes appear. `when { … }` with nothing after it takes a full condition in each branch, and
replaces a chain of `if … else if`. `when (day) { … }` compares one value against each branch, and a
branch can list several values, `1, 7`, or a range with `in`. **Branches are tried in order and the
first match wins**, which is why `label` can test `< 30` before `< 90` without repeating the lower
bound. There is no fall-through and no `break`: each branch runs alone.

## `else` is required when `when` is a value

`label` must return a `String` for every `Int`, and the compiler cannot tell that the four conditions
cover every number, so the `else` is required. Take it out and the program does not compile, for the
same reason lesson 3's `if` needed its `else`.

There is one kind of value for which the compiler **can** tell that every case is covered without an
`else`: a value whose possible cases are all known when the program is compiled. Enums are the first,
in section 03, and sealed classes the second, which is what this lesson is about.

## `is` inside `when`

A branch can test a type with `is`, and inside it the value is smart cast, as lesson 2 promised:

```kotlin
// WhenIs.kt
fun describe(x: Any): String = when (x) {
    is Int -> "a number of minutes: ${x + 0}"
    is String -> "a note of ${x.length} characters"
    is List<*> -> "a list of ${x.size}"
    else -> "something else"
}

fun main() {
    println(describe(45))
    println(describe("read chapter 3"))
    println(describe(listOf(45, 30)))
    println(describe(4.5))
}
```

```
ana@vm:~/kt/l09$ kotlinc WhenIs.kt -include-runtime -d whenis.jar && java -jar whenis.jar
a number of minutes: 45
a note of 14 characters
a list of 2
something else
```

`x.length` compiles in the `String` branch because the branch only runs when `x` is a `String`. `Any`
is the type every Kotlin type is a subtype of, and `List<*>` is a list of an unknown item type, which
lesson 12 explains. Testing an `Any` like this is a last resort; the rest of the lesson replaces `Any`
with a type that knows its own cases.
