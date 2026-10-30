---
title: == and ===
version: 1
---

Lesson 1 said Kotlin's `==` calls `equals`, and promised `===` for later. **`==` asks whether two
values are equal; `===` asks whether they are the same object**, the same place in memory.

```kotlin
// Identity.kt
data class Session(val course: String, val minutes: Int)

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Kotlin", 45)
    val c = a
    println(a == b)
    println(a === b)
    println(a === c)
    println(a != b)
    println(a !== b)
}
```

```
ana@vm:~/kt/l08$ kotlinc Identity.kt -include-runtime -d identity.jar && java -jar identity.jar
true
false
true
false
true
```

`a` and `b` were built separately with the same values: equal, and two objects. `c = a` copies the
reference, not the object, so `a === c` is true: one session with two names. `!=` and `!==` are the
negations.

## `==` is null-safe

`a == b` is not exactly `a.equals(b)`. It is `a?.equals(b) ?: (b === null)`: **when `a` is null it
does not throw**, it answers whether `b` is null too. That is why `==` works on nullable values with no
safe call, where Java's `a.equals(b)` would throw on a null `a`.

## Which one you want

Almost always `==`. **`===` is for the rare question "is this the very object I already have"**: a
cache checking it was handed back the instance it stored, or a test checking that a function returned
its argument rather than a copy. Using `===` to compare values is the Java `==` bug reintroduced, and
it can look as if it works:

```kotlin
// Interned.kt
fun main() {
    val a = "Kotlin"
    val b = "Kotlin"
    val c = "Kot" + "lin".lowercase()
    println(a === b)
    println(a === c)
    println(a == c)
}
```

```
ana@vm:~/kt/l08$ kotlinc Interned.kt -include-runtime -d interned.jar && java -jar interned.jar
true
false
true
```

`a === b` is `true` because the JVM keeps one copy of each string literal and both names point at it.
`c` is built at run time, so it is a different object with the same characters, and `===` says `false`.
**A comparison that is right for literals and wrong for computed values is the kind of bug that passes
every test written with literals**, which is most tests. `==` gave the right answer for all three.
