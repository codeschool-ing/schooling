---
title: apply, for setting an object up
version: 1
---

`apply` makes the object the block's receiver and returns the object. **It is for configuring
something and then handing it on**: create, set it up in a block where its members need no prefix,
and get it back at the end.

```kotlin
// Apply.kt
fun main() {
    val report = StringBuilder().apply {
        append("Week 44\n")
        append("Kotlin   105 min\n")
        append("Android   30 min")
    }
    println(report)
    println(report.length)

    val goals = mutableMapOf<String, Int>().apply {
        put("Kotlin", 300)
        put("Android", 240)
    }
    println(goals)
}
```

```
ana@vm:~/kt/l06$ kotlinc Apply.kt -include-runtime -d apply.jar && java -jar apply.jar
Week 44
Kotlin   105 min
Android   30 min
41
{Kotlin=300, Android=240}
```

`StringBuilder` is a Java class that collects text cheaply, and `append` is its method. Inside the
block, `append` is called on the builder without naming it, because the builder is `this`. The value
of the whole expression is the builder, so `report` holds it, and the map is built the same way.

## The shape it replaces

Without `apply`, the same code names the object on every line:

```kotlin
val report = StringBuilder()
report.append("Week 44\n")
report.append("Kotlin   105 min\n")
report.append("Android   30 min")
```

That is four statements about one object, and nothing stops a fifth line from appearing between
them that does something else. **`apply` makes the setup one expression**, which reads as "the
builder, configured like this", and it can sit where an expression goes: an argument, a return
value, a property's initial value.

## What `apply` should not contain

The block's value is thrown away, because `apply` returns the object. **A computation whose result you
need belongs in `run`**, and a block that does something to the world, logging or saving, belongs in
`also`. `apply` with a `println` inside it works, and makes the next reader wonder whether the
printing is part of the setup.

`android-apps` meets `apply` constantly. Building an `Intent`, a notification or a `Bundle` is exactly
this shape: make an object, set five things on it, pass it on.
