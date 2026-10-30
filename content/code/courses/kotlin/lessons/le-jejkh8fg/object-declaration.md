---
title: object: a class with exactly one instance
version: 1
---

Sometimes a program needs one of something: one configuration, one registry, one clock. Java does
it with a class, a private constructor and a static field holding the only instance, and gets the
details wrong often enough that "singleton" is a word people sigh at. **Kotlin's `object` declares a
class and its single instance in one go**, and the language takes care of creating it exactly once.

```kotlin
// Planner.kt
object Planner {
    private val sessions = mutableListOf<Int>()

    init {
        println("Planner created")
    }

    fun add(minutes: Int) {
        sessions.add(minutes)
    }

    val total: Int
        get() = sessions.sum()
}

fun main() {
    println("start")
    Planner.add(45)
    Planner.add(30)
    println(Planner.total)
    println(Planner === Planner)
}
```

```
ana@vm:~/kt/l10$ kotlinc Planner.kt -include-runtime -d planner.jar && java -jar planner.jar
start
Planner created
75
true
```

`Planner` is used by its name, with no constructor call: the name **is** the instance. It has
properties, functions and an `init` block like any class, and no constructor parameters, because
nobody calls a constructor.

## Created on first use

`start` printed before `Planner created`. **The object is built the first time something touches
it**, not when the program starts, and the JVM guarantees that happens once even if two threads touch
it at the same moment. That is the part Java's hand-written singletons get wrong, and here it is not
your code.

## What an `object` is for

An `object` fits **something that has no state of its own, or whose state really is one for the whole
program**: a set of helper functions that belong together, a constant table, a default
implementation of an interface. The planner's sessions are the wrong example on purpose. One global
list of sessions is easy to start with, and section 07 shows what it costs the first time two parts of
the program, or two tests, both believe they own it.
