---
title: Delegated properties: lazy, observable and map
version: 1
---

`by` works on properties too. **A delegated property hands its getter, and its setter, to another
object**, which decides how the value is stored and what happens when it is read or written. The
standard library provides the delegates most programs need.

```kotlin
// Delegates.kt
import kotlin.properties.Delegates

class Settings {
    val goal: Int by lazy {
        println("computing goal")
        300
    }

    var theme: String by Delegates.observable("light") { _, old, new ->
        println("theme: $old -> $new")
    }
}

fun main() {
    val s = Settings()
    println("created")
    println(s.goal)
    println(s.goal)
    s.theme = "dark"
    println(s.theme)
}
```

```
ana@vm:~/kt/l11$ kotlinc Delegates.kt -include-runtime -d delegates.jar && java -jar delegates.jar
created
computing goal
300
300
theme: light -> dark
dark
```

## `by lazy`

`goal` was not computed when the object was built, `created` printed first, and it was computed
**once**, on the first read; the second read reused the value. That is lesson 7's promise: unlike
`lateinit`, a `lazy` property cannot be read empty, because reading it is what fills it. By default the
first computation is guarded against two threads running it at once.

Use it for a value that is expensive and may never be needed, and for one that depends on something
that is only ready after construction.

## `Delegates.observable`

`theme` stores its value normally and runs the lambda after every assignment, with the property, the
old value and the new one; `_` skips the property. **It is a setter with a hook, written once**, and
the planner could use it to save a setting the moment it changes.

## A map as the storage

```kotlin
// MapDelegate.kt
class Row(map: Map<String, Any?>) {
    val course: String by map
    val minutes: Int by map
}

fun main() {
    val row = Row(mapOf("course" to "Kotlin", "minutes" to 45))
    println("${row.course}: ${row.minutes}")
}
```

```
ana@vm:~/kt/l11$ kotlinc MapDelegate.kt -include-runtime -d mapdelegate.jar && java -jar mapdelegate.jar
Kotlin: 45
```

Each property reads the map entry with its own name. This is handy for rows parsed from JSON or a
form, and it trusts the map completely: a missing key throws when the property is read, and a value of
the wrong type throws a `ClassCastException`. The type safety of the properties ends at the map.
