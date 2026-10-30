---
title: Generic functions: one function for every type
version: 1
---

`List<Int>` has appeared since lesson 3, and the angle brackets were left unexplained. **They are a
type parameter**: `List` is written once, for a type to be named later, and `List<Int>` and
`List<String>` are two uses of it. Functions can have type parameters too:

```kotlin
// Generic.kt
fun <T> firstOrDefault(items: List<T>, default: T): T =
    if (items.isEmpty()) default else items[0]

fun <T> List<T>.second(): T? = if (size >= 2) this[1] else null

fun main() {
    println(firstOrDefault(listOf(45, 30), 0))
    println(firstOrDefault(emptyList<String>(), "none"))
    println(listOf("Kotlin", "Android").second())
    val n: Int = firstOrDefault(listOf(45), 0)
    println(n + 1)
}
```

```
ana@vm:~/kt/l12$ kotlinc Generic.kt -include-runtime -d generic.jar && java -jar generic.jar
45
none
Android
46
```

`fun <T>` declares a type parameter `T` before the function's name, and `T` is then used like any
type in the parameters and the result. **At each call, the compiler works out what `T` is from the
arguments**: an `Int` in the first call, a `String` in the second. The result has that type, which is
why `n + 1` compiles: `firstOrDefault` returned an `Int`, not some general object that would have to
be cast.

That is the point of generics. Without them, `firstOrDefault` would take `List<Any>` and return
`Any`, and every caller would cast the result back, hoping it was right. **With them, the type that
went in is the type that comes out, and the compiler checks it.**

## Naming the type yourself

`emptyList<String>()` names `T` explicitly, because an empty list has nothing to infer from. You can
name it on any call, and then the compiler checks the arguments against it:

```kotlin
// Explicit.kt
fun <T> firstOrDefault(items: List<T>, default: T): T =
    if (items.isEmpty()) default else items[0]

fun main() {
    println(firstOrDefault<Int>(listOf(45), "none"))
}
```

```
ana@vm:~/kt/l12$ kotlinc Explicit.kt -include-runtime -d explicit.jar
Explicit.kt:6:45: error: argument type mismatch: actual type is 'String', but 'Int' was expected.
    println(firstOrDefault<Int>(listOf(45), "none"))
                                            ^^^^^^
```

With `T` fixed to `Int`, a `String` default does not fit. Left to infer, the compiler would have
looked for a type both an `Int` and a `String` belong to and found one, a common supertype, which is
rarely what anybody meant. **When inference picks a surprising type, naming `T` turns the surprise
into an error message.**
