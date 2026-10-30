---
title: Strings, templates and the raw string
version: 1
---

The planner's first screen is text: a course, a number of minutes, a total. Kotlin builds text by
putting values inside a string literal rather than gluing strings together with `+`, and the
syntax has two forms.

```schooling-example
{"language": "kotlin", "file": "Report.kt", "parts": [{"code": "fun main() {\n    val course = \"Kotlin\"\n    val minutes = 75", "note": "Two values the report will show."}, {"code": "    println(\"$course: $minutes min\")", "note": "`$name` puts a name's value into the string. The name ends where the letters end, so the colon after `course` is ordinary text."}, {"code": "    println(\"$course: ${minutes / 60} h ${minutes % 60} min\")", "note": "`${…}` takes any expression. `/` and `%` are whole-number division and remainder, so 75 minutes is 1 h and 15 min."}, {"code": "    println(\"Course name has ${course.length} letters\")", "note": "A property of a value is an expression too, so it needs the braces. Without them, `$course.length` would print `Kotlin.length`."}, {"code": "    println(\"Price: \\$0\")", "note": "A backslash before `$` keeps it as a dollar sign."}, {"code": "    val report = \"\"\"\n        Week 44\n          $course  $minutes min\n    \"\"\".trimIndent()\n    println(report)\n}", "note": "Three quotes open a raw string: it can span lines, and a backslash in it is just a backslash. `trimIndent()` removes the indentation the lines share, which is there only to keep the code tidy."}]}
```

```
ana@vm:~/kt/l01$ kotlinc Report.kt -include-runtime -d report.jar && java -jar report.jar
Kotlin: 75 min
Kotlin: 1 h 15 min
Course name has 6 letters
Price: $0
Week 44
  Kotlin  75 min
```

**Templates are evaluated where the string is built**, once. A template is not a formula that
updates when `minutes` changes later; it is the same as writing the concatenation out by hand,
which is what the compiler turns it into.

## A string never changes

A `String` in Kotlin, as in Java, is immutable. Every function that looks like it changes one
returns a new string and leaves the old one alone:

```kotlin
// Upper.kt
fun main() {
    val course = "kotlin"
    val shout = course.uppercase()
    println(course)
    println(shout)
    println(course.replaceFirstChar { it.uppercase() })
}
```

```
ana@vm:~/kt/l01$ kotlinc Upper.kt -include-runtime -d upper.jar && java -jar upper.jar
kotlin
KOTLIN
Kotlin
```

`course` is still `kotlin` after `uppercase()`, because the call built `KOTLIN` as a second string.
The last line takes a block of code in braces, which lesson 4 calls a lambda; for now it is enough
that it capitalises the first letter. **On a `String` there is no other kind of function**: nothing
can change one, so everything that looks like a change hands back a new string, and forgetting to
keep the result is the bug. `course.uppercase()` on a line of its own compiles, runs, and does
nothing you can see.

## Comparing strings

`==` compares two strings by their characters. That is not the Java habit, where `==` on objects
compares identity and `equals` compares content; Kotlin's `==` calls `equals` for you. Lesson 8
returns to this with classes of your own, and to `===`, which is identity.

```kotlin
// Compare.kt
fun main() {
    val a = "Kotlin"
    val b = "kot" + "lin".uppercase().lowercase()
    println(b)
    println(a == b.replaceFirstChar { it.uppercase() })
    println(a.equals("KOTLIN", ignoreCase = true))
}
```

```
ana@vm:~/kt/l01$ kotlinc Compare.kt -include-runtime -d compare.jar && java -jar compare.jar
kotlin
true
true
```

The last line names an argument, `ignoreCase = true`, which is a feature of every Kotlin function
call and the subject of lesson 3.
