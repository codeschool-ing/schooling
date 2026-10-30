---
title: Visibility: public, private, protected and internal
version: 1
---

Everything in Kotlin is **public by default**: visible to any code that can see the class. Java's
default is package-private, and Kotlin chose the other way because most declarations in a library
are meant to be used. The other three modifiers each narrow it:

| modifier | on a class member | at the top of a file |
|---|---|---|
| `public` (the default) | visible everywhere | visible everywhere |
| `private` | inside this class only | inside this file only |
| `protected` | this class and its subclasses | not allowed |
| `internal` | anywhere in the same **module** | anywhere in the same module |

A module is what is compiled together: one Gradle module, one `kotlinc` run. `internal` matters once
lesson 19 builds a project of two modules, where it means "public inside this module, invisible to
the others".

## Hiding the parts that keep a promise

The planner's tracker keeps a log of sessions and a running total, and the total must always equal
the sum of the log. **That promise holds only if nothing else can write either of them**:

```kotlin
// Tracker.kt
class Tracker {
    private val log = mutableListOf<Int>()
    var total: Int = 0
        private set

    fun add(minutes: Int) {
        log.add(minutes)
        total += minutes
    }

    fun sessions(): List<Int> = log.toList()
}

fun main() {
    val t = Tracker()
    t.add(45)
    t.add(30)
    println(t.total)
    println(t.sessions())
    t.total = 0
}
```

```
ana@vm:~/kt/l07$ kotlinc Tracker.kt -include-runtime -d tracker.jar
Tracker.kt:21:7: error: cannot access 'total': it is private in 'Tracker'.
    t.total = 0
      ^^^^^
```

`log` is private, so only `add` can change it. `total` has a public getter and a `private set`, so
the last line, which tries to reset it from outside, is refused by name. Remove it and the program
runs:

```kotlin
// TrackerOk.kt
class Tracker {
    private val log = mutableListOf<Int>()
    var total: Int = 0
        private set

    fun add(minutes: Int) {
        log.add(minutes)
        total += minutes
    }

    fun sessions(): List<Int> = log.toList()
}

fun main() {
    val t = Tracker()
    t.add(45)
    t.add(30)
    println(t.total)
    println(t.sessions())
}
```

```
ana@vm:~/kt/l07$ kotlinc TrackerOk.kt -include-runtime -d trackerok.jar && java -jar trackerok.jar
75
[45, 30]
```

`sessions()` returns a copy, as lesson 5 advised, so a caller who receives the list cannot reach into
the tracker through it. **The class is now the only code that can break its own promise**, which
makes the promise something one file can be checked for.

## Start private

The habit that follows is the same one as `val` before `var`: **make a member `private` until
something outside needs it**. Widening later is a one-word change that breaks nobody; narrowing a
public member later breaks every caller that already uses it.
