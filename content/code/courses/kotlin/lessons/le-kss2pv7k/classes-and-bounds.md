---
title: Generic classes, and bounds on what T may be
version: 1
---

A class can take a type parameter the same way, after its name. And often `T` cannot be just
anything: a ranking needs items that can be compared. **An upper bound, `T : Comparable<T>`, says what
`T` must be**, and inside the class the compiler then allows what that type promises:

```kotlin
// Ranked.kt
class Ranked<T : Comparable<T>>(private val items: List<T>) {
    fun top(): T? = items.maxOrNull()
    fun bottom(): T? = items.minOrNull()
}

fun main() {
    println(Ranked(listOf(45, 90, 30)).top())
    println(Ranked(listOf("Kotlin", "Go", "Android")).bottom())
}
```

```
ana@vm:~/kt/l12$ kotlinc Ranked.kt -include-runtime -d ranked.jar && java -jar ranked.jar
90
Android
```

`maxOrNull` needs items it can compare, and the bound is what lets it be called on a list of `T`.
`Int` and `String` are both `Comparable` to themselves, so both rankings work. A type that is not
comparable is refused at the call:

```kotlin
// Unranked.kt
class Ranked<T : Comparable<T>>(private val items: List<T>) {
    fun top(): T? = items.maxOrNull()
}

class Session(val course: String, val minutes: Int)

fun main() {
    println(Ranked(listOf(Session("Kotlin", 45))).top())
}
```

```
ana@vm:~/kt/l12$ kotlinc Unranked.kt -include-runtime -d unranked.jar
Unranked.kt:9:13: error: cannot infer type for type parameter 'T'. Specify it explicitly.
    println(Ranked(listOf(Session("Kotlin", 45))).top())
            ^^^^^^
Unranked.kt:9:20: error: argument type mismatch: actual type is 'List<Session>', but 'List<uninferred T (of class Ranked<T : Comparable<T>>)>' was expected.
    println(Ranked(listOf(Session("Kotlin", 45))).top())
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

**The bound moved the error to the line that made it**: the call that passes sessions, rather than
some line inside `Ranked` that tried to compare two of them. That is the same move lesson 7's `init`
check made, applied to types.

## Several bounds

`T : Comparable<T>` is one bound. For more, a `where` clause after the signature lists them:
`fun <T> longest(items: List<T>) where T : CharSequence, T : Comparable<T>`. Both must hold, so the
function can use `length` from `CharSequence` and comparison from `Comparable`.

## The default bound

A `T` with no bound written has the bound `Any?`, so it may be `null`. **`<T : Any>` excludes `null`**,
which matters when a function wants to promise its result is never null, or to use a `T` as a map key
that must not be one.
