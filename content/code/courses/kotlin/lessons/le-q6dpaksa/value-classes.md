---
title: Value classes: a type for one number
version: 1
---

`Session(course: String, minutes: Int)` takes an `Int`, and any `Int` fits: a number of seconds, a
year, a session count. The compiler cannot tell them apart, because they have the same type. **A value
class wraps one value in a type of its own**, so the compiler can tell them apart, and on the JVM it
usually costs nothing at run time, because the wrapper disappears in the compiled code.

```schooling-example
{"language": "kotlin", "file": "Minutes.kt", "parts": [{"code": "@JvmInline\nvalue class Minutes(val value: Int) {\n    init {\n        require(value >= 0) { \"minutes cannot be negative: $value\" }\n    }", "note": "`value class` with exactly one property. `@JvmInline` is required on the JVM and says what happens there: the class is replaced by its `Int` wherever it can be."}, {"code": "    operator fun plus(other: Minutes) = Minutes(value + other.value)\n}", "note": "`operator fun plus` lets two `Minutes` be added with `+`. Any class can declare operators this way; the function names are fixed by the language, `plus`, `minus`, `times` and so on."}, {"code": "data class Session(val course: String, val length: Minutes)", "note": "The session now says what its number is."}, {"code": "fun main() {\n    val total = Minutes(45) + Minutes(30)\n    println(total)\n    println(Session(\"Kotlin\", Minutes(45)))\n    println(Minutes(-5))\n}", "note": "The `init` check runs like any class's, so a negative length cannot exist."}]}
```

```
ana@vm:~/kt/l08$ kotlinc Minutes.kt -include-runtime -d minutes.jar && java -jar minutes.jar
Minutes(value=75)
Session(course=Kotlin, length=Minutes(value=45))
Exception in thread "main" java.lang.IllegalArgumentException: minutes cannot be negative: -5
	at Minutes.constructor-impl(Minutes.kt:4)
	at MinutesKt.main(Minutes.kt:13)
	at MinutesKt.main(Minutes.kt)
```

## What the compiler now refuses

```kotlin
// MinutesWrong.kt
@JvmInline
value class Minutes(val value: Int)

data class Session(val course: String, val length: Minutes)

fun main() {
    val seconds = 2700
    println(Session("Kotlin", seconds))
}
```

```
ana@vm:~/kt/l08$ kotlinc MinutesWrong.kt -include-runtime -d minuteswrong.jar
MinutesWrong.kt:9:31: error: argument type mismatch: actual type is 'Int', but 'Minutes' was expected.
    println(Session("Kotlin", seconds))
                              ^^^^^^^
```

**A number that meant seconds no longer fits where minutes are expected.** Before, this mistake would
have compiled, and a session of 2,700 minutes would have shown up on a screen. It is the same trade as
every other one in this course: a little more written where the value is made, and a whole kind of
error refused everywhere it is used.

## When it is worth it

A value class pays where a plain type is easy to confuse with another of the same type: ids of
different things that are all `String`s, amounts in different units that are all `Int`s. **For a value
that has one meaning in the whole program, the plain type is fine.** The planner gets the most from it
on ids, where `CourseId` and `SessionId` keep a session's id from being passed where a course's is
expected, which is exactly the mistake that compiles with two `String`s.
