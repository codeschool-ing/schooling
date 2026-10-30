---
title: Extension properties, and where extensions belong
version: 1
---

A property can be an extension too, as long as it is computed:

```kotlin
// ExtProps.kt
val List<Int>.total: Int
    get() = sum()

val Int.isLong: Boolean
    get() = this >= 60

fun main() {
    val week = listOf(45, 90, 30)
    println(week.total)
    println(week.count { it.isLong })
}
```

```
ana@vm:~/kt/l11$ kotlinc ExtProps.kt -include-runtime -d extprops.jar && java -jar extprops.jar
165
1
```

**An extension property has no backing field**: it is a getter, and a setter for a `var`, attached to
the type from outside, and there is nowhere in an `Int` to store anything extra. An initialiser is
therefore refused:

```kotlin
// ExtField.kt
val Int.bonus: Int = 5

fun main() {
    println(45.bonus)
}
```

```
ana@vm:~/kt/l11$ kotlinc ExtField.kt -include-runtime -d extfield.jar
ExtField.kt:2:22: error: extension property cannot be initialized because it has no backing field.
val Int.bonus: Int = 5
                     ^
```

## Where to declare them

An extension declared at the top of a file is visible wherever that file's package is imported, which
is everywhere in a small project. Three habits keep that from turning into a cloud of functions on
`String` that nobody can find:

- **declare an extension next to the code that needs it**, and make it `private` or `internal` when only
  that code does;
- **extend types you own for convenience, and types you do not own for vocabulary**: `Int.asHours()`
  says something about the planner's domain and is worth sharing; `String.trimAndUpper()` is a
  one-off;
- **when an extension needs private state of the class, it should be a member**, because an extension
  sees only the public API, like any other outside code.

## Extensions inside a class

An extension can also be declared inside a class, where it has two receivers: the class instance and
the extended value. Lesson 6's blocks that read like a small language for one object are often built
this way, and so is the Gradle script of lesson 19, where `implementation("…")` inside `dependencies
{ }` is exactly such a function.
