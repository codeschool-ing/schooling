---
title: data object, for a case with no data
version: 1
---

Lesson 9's `WeekState.Loading` was a `data object`. An `object` alone would have worked as a state;
the `data` changes one thing you can see and one you cannot:

```kotlin
// DataObject.kt
sealed interface WeekState {
    object Loading : WeekState
    data object Empty : WeekState
    data class Loaded(val sessions: List<Int>) : WeekState
}

fun main() {
    println(WeekState.Loading)
    println(WeekState.Empty)
    println(WeekState.Loaded(listOf(45)))
    println(WeekState.Empty == WeekState.Empty)
}
```

```
ana@vm:~/kt/l10$ kotlinc DataObject.kt -include-runtime -d dataobject.jar && java -jar dataobject.jar
WeekState$Loading@7d4991ad
Empty
Loaded(sessions=[45])
true
```

**The visible difference is `toString`**: the plain object printed its class and a hash code, the data
object printed its name. In a log, `Empty` says what happened, and `WeekState$Loading@` with a hash code
after it makes somebody look it up. Next to data classes that print their properties, a plain object is the one entry
that does not read.

The invisible difference is `equals`. A plain object compares by identity, which is right as long as
there is exactly one instance. Some serialisation libraries can build a second instance of an
`object` when they read one back; a `data object` compares equal to any instance of its own type, so
the copy still matches.

## The rule for a sealed hierarchy

**Cases with data are `data class`; cases without are `data object`.** It costs one word, keeps every
case printing the same way, and is what current Kotlin and Android code writes.
