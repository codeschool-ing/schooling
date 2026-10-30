---
title: Erasure, and reified type parameters
version: 1
---

On the JVM, **type arguments exist only at compile time**. A `List<Int>` and a `List<String>` are both
just a `List` while the program runs; the `<Int>` was checked by the compiler and then thrown away.
This is called type erasure, and it explains a refusal you will meet:

```kotlin
// Erased.kt
fun <T> isListOf(value: Any): Boolean = value is List<T>

fun main() {
    println(isListOf<Int>(listOf(45)))
}
```

```
ana@vm:~/kt/l12$ kotlinc Erased.kt -include-runtime -d erased.jar
Erased.kt:2:50: error: cannot check for instance of erased type 'List<T (of fun <T> isListOf)>'.
fun <T> isListOf(value: Any): Boolean = value is List<T>
                                                 ^^^^^^^
```

At run time there is no `T` to compare with, so `is List<T>` cannot be answered and is refused. This is
also why lesson 9 wrote `is List<*>`: the star asks only "is it a list", which can be checked.

## `reified`: keeping T in an inline function

Lesson 4 said there was one case where `inline` is required rather than an optimisation. **An inline
function's body is copied into each call site, where the type argument is known**, so the compiler
can write the real type into the copy. Marking the parameter `reified` asks it to:

```kotlin
// Reified.kt
inline fun <reified T> List<Any>.only(): List<T> = filter { it is T }.map { it as T }

inline fun <reified T> typeName(): String? = T::class.simpleName

fun main() {
    val mixed: List<Any> = listOf(45, "read chapter 3", 30, 2.5)
    println(mixed.only<Int>())
    println(mixed.only<String>())
    println(typeName<Map<String, Int>>())
    println(mixed.filterIsInstance<Double>())
}
```

```
ana@vm:~/kt/l12$ kotlinc Reified.kt -include-runtime -d reified.jar && java -jar reified.jar
[45, 30]
[read chapter 3]
Map
[2.5]
```

`it is T` compiles here, because in the copy made for `only<Int>()` it reads `it is Int`.
`T::class` gives the class object for the type, which a non-reified `T` cannot. The standard library's
`filterIsInstance` on the last line is exactly this pattern, and so is the `inject<T>()` or
`viewModel<T>()` that Android libraries use: **a function that needs to know at run time which type it
was called for is an inline function with a reified parameter**.

## The price

A reified function must be `inline`, so its body is copied into every caller, and it cannot be called
from Java, which has no way to supply the type. Neither matters for small helpers, which is what these
functions almost always are.
