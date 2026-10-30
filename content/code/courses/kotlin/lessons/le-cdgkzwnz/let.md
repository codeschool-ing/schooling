---
title: let, for the value that might be null
version: 1
---

`let` passes the object as `it` and returns the block's result. On its own that is little more than
naming a value. **Its real use is behind a safe call**: `x?.let { … }` runs the block only when `x`
is not null, with `it` already smart cast to the non-null type, and gives `null` otherwise.

```kotlin
// Let.kt
fun main() {
    val input: String? = "45"
    val seconds = input?.toIntOrNull()?.let { it * 60 }
    println(seconds)

    val missing: String? = null
    missing?.let { println("never printed: $it") }
    println(missing?.let { it.length } ?: 0)

    val note: String? = "read chapter 3"
    note?.let { text ->
        val words = text.split(" ").size
        println("note of $words words")
    }
}
```

```
ana@vm:~/kt/l06$ kotlinc Let.kt -include-runtime -d let.jar && java -jar let.jar
2700
0
note of 3 words
```

Three uses in one file. The first turns a number that might be missing into another number that
might be missing, and the chain stops at the first `null`, as lesson 2's safe calls did. The second
runs a block for its effect only when there is something to act on. The third shows a name for
`it`, `text`, which is the right choice once the block is longer than a line.

## A `let` that only renames is noise

`val n = minutes.let { it * 2 }` is `val n = minutes * 2` with more punctuation. **`let` earns its
place when the value is nullable, or when it is the end of a chain** you do not want to break into a
named `val`:

```kotlin
// LetChain.kt
fun main() {
    val sessions = listOf("Kotlin" to 45, "Android" to 30, "Kotlin" to 60)
    sessions.filter { it.first == "Kotlin" }
        .sumOf { it.second }
        .let { "Kotlin this week: ${it / 60} h ${it % 60} min" }
        .let(::println)
}
```

```
ana@vm:~/kt/l06$ kotlinc LetChain.kt -include-runtime -d letchain.jar && java -jar letchain.jar
Kotlin this week: 1 h 45 min
```

The total is used twice inside the template, so it needs a name, and `let` gives it one without
interrupting the chain. The last `let` takes a function reference, which lesson 4 showed is allowed
wherever a lambda of the same type is.

## `?.let` against `if`

`if (note != null) { … }` does the same as `note?.let { … }` for a local `val`, and is often clearer.
The two differ for a `var` property, where lesson 2 showed the `if` cannot smart cast: `?.let`
reads the property once, and works on that value, so it is the short form of lesson 2's "copy it into
a `val` first".
