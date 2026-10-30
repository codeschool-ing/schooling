---
title: Type inference, and the conversions Kotlin will not make for you
version: 1
---

None of the programs so far has written a type, and every one of their names has one. **Kotlin is
statically typed: the compiler knows the type of every name before the program runs**, exactly as
Java's does. It simply works most of them out from the value on the right, which is called type
inference. A missing type is not a missing check.

```kotlin
// Types.kt
fun main() {
    val minutes = 45
    val big = 3_000_000_000
    val hours = minutes / 60.0
    val done = false
    val course = "Kotlin"
    println(minutes::class.simpleName)
    println(big::class.simpleName)
    println(hours::class.simpleName)
    println(done::class.simpleName)
    println(course::class.simpleName)
    println(minutes / 60)
    println(hours)
}
```

```
ana@vm:~/kt/l01$ kotlinc Types.kt -include-runtime -d types.jar && java -jar types.jar
Int
Long
Double
Boolean
String
0
0.75
```

Five values, five types, none of them written. `::class.simpleName` asks a value for the name of its
class at run time, and it prints what the compiler had already decided:

| literal | type | why |
|---|---|---|
| `45` | `Int` | a whole number that fits in 32 bits |
| `3_000_000_000` | `Long` | it does not fit in an `Int`, so the compiler picks 64 bits; the underscores are only for your eyes |
| `minutes / 60.0` | `Double` | one side is a `Double`, so the result is one |
| `false` | `Boolean` | |
| `"Kotlin"` | `String` | |

**`minutes / 60` printed `0`.** Two `Int`s divide to an `Int`, and the fraction is thrown away
rather than rounded: 45 divided by 60 is 0 remainder 45. The next line divided by `60.0` and got
`0.75`. This is the same rule as Java's and C's, and it is the most common wrong number in a
beginner's program.

## Writing the type yourself

A type goes after the name, behind a colon. The compiler then checks the value against it instead
of inferring:

```kotlin
// Declared.kt
fun main() {
    val minutes: Int = 45
    val total: Long = minutes
    println(total)
}
```

```
ana@vm:~/kt/l01$ kotlinc Declared.kt -include-runtime -d declared.jar
Declared.kt:4:21: error: initializer type mismatch: expected 'Long', actual 'Int'.
    val total: Long = minutes
                    ^
```

This is where Kotlin differs from Java. **Kotlin never widens a number for you**: an `Int` is not a
`Long`, even though every `Int` value fits in one, and Java would have converted it without a word.
The conversion has to be written, and it is a function on the number:

```kotlin
// Converted.kt
fun main() {
    val minutes: Int = 45
    val total: Long = minutes.toLong()
    val ratio: Double = minutes.toDouble() / 60
    println(total)
    println(ratio)
}
```

```
ana@vm:~/kt/l01$ kotlinc Converted.kt -include-runtime -d converted.jar && java -jar converted.jar
45
0.75
```

`toLong()`, `toInt()`, `toDouble()` and their siblings exist on every number type. The narrowing
ones, such as `toInt()` on a `Long`, keep the low bits and drop the rest, so a value that does not
fit comes out as a different number rather than an error. Writing the conversion is what makes that
visible in the code.

## When to write the type anyway

Inference is the default, and a declared type is worth writing in three places:

- **when the value on the right does not say enough**, as with `val total: Long = 0`, where the
  literal alone would make an `Int`;
- **on a public function's return type**, which lesson 3 makes a habit, because it is a promise to
  every caller and should not change because somebody edited the body;
- **when you are not sure what the compiler inferred.** Writing the type you expect and compiling
  is the quickest way to find out whether you were right.
