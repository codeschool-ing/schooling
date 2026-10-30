---
title: The safe call, ?.
version: 1
---

`?.` is a dot that checks first. `note?.length` asks `note` for its length if `note` is a string,
and gives `null` without asking if `note` is `null`. **The result of a safe call is always nullable**,
because one of its two outcomes is `null`: `note?.length` is an `Int?`, not an `Int`.

The planner keeps three notes, one of them missing and one empty:

```kotlin
// SafeCall.kt
fun main() {
    val notes: List<String?> = listOf("read chapter 3", null, "")
    for (note in notes) {
        println(note?.length)
    }
    val second: String? = notes[1]
    println(second?.uppercase()?.length)
    val total: Int? = notes[0]?.length
    println(total)
}
```

```
ana@vm:~/kt/l02$ kotlinc SafeCall.kt -include-runtime -d safecall.jar && java -jar safecall.jar
14
null
0
null
14
```

`for (note in notes)` runs its body once per item of the list, with `note` standing for each item
in turn; lesson 5 has much more to say about lists. The three lines of output are the three
outcomes worth telling apart: **a length, `null` for the missing note, and `0` for the empty one.**
An empty string is a string. Only `null` is absent, and `?.` treats the two differently on purpose.

## A chain stops at the first null

`second?.uppercase()?.length` is two safe calls in a row. `second` is `null`, so the first `?.`
gives `null`, and the second `?.` is asked about that `null` and gives `null` again. Nothing after
the first missing value runs. That is why a chain of safe calls reads as one question: "the length
of the upper-case form of the second note, if there is one".

The other way round, a plain `.` after a `?.`, does not compile, because the value on its left is
nullable. Once a chain is safe, it stays safe until something answers the null case, and section 04
is that something.

## Doing something only when a value is there

A safe call can also call a function whose result you do not care about. `note?.let { println(it) }`
runs the block in braces only when `note` is not `null`, with `it` standing for the value. It is a
common shape in Kotlin and in Android code, and lesson 6 explains `let` properly, along with its
four siblings; for now it is enough to recognise it as "if present, do this".

## What a safe call costs

Nothing you would notice. The compiler turns `note?.length` into exactly the `if` you would have
written by hand: compare with `null`, branch, call. **The difference is that you cannot forget to
write it**, because without the `?` the code does not compile.
