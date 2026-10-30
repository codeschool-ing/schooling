---
title: Smart casts, and the check the compiler remembers
version: 1
---

The oldest way to handle `null` is to check for it, and Kotlin keeps that way and improves it.
**After `if (note != null)`, the compiler treats `note` as a `String` for as long as the check holds**,
so `.length` compiles with a plain dot. This is called a smart cast: the compiler casts for you,
because it has just watched you prove the cast is safe.

```kotlin
// SmartCast.kt
fun describe(note: String?): String {
    if (note == null) {
        return "no note"
    }
    return "note of ${note.length} characters"
}

fun main() {
    println(describe(null))
    println(describe("read chapter 3"))
}
```

```
ana@vm:~/kt/l02$ kotlinc SmartCast.kt -include-runtime -d smartcast.jar && java -jar smartcast.jar
no note
note of 14 characters
```

The check here is the opposite one, `note == null`, followed by a `return`. The compiler follows
that too: past the `if`, the only way to have arrived is with a note, so `note` is a `String` on
the last line. **Checking and leaving early is the most readable shape**, because the rest of the
function is written for the case where everything is present.

## When the compiler will not remember

A smart cast is a promise that the value cannot change between the check and the use. For a `val`
in the same function that is plainly true. For a `var` property of an object, it is not: something
else could set it to `null` in between.

```kotlin
// Draft.kt
class Draft {
    var note: String? = "read chapter 3"
}

fun main() {
    val draft = Draft()
    if (draft.note != null) {
        println(draft.note.length)
    }
}
```

```
ana@vm:~/kt/l02$ kotlinc Draft.kt -include-runtime -d draft.jar
Draft.kt:9:17: error: smart cast to 'String' is impossible, because 'note' is a mutable property that could be mutated concurrently.
        println(draft.note.length)
                ^^^^^^^^^^
```

`class Draft` declares a class with one property, which lesson 7 covers. The message names the
reason in full: `note` is a mutable property that could be mutated concurrently, so the check on
one line proves nothing about the next. **The fix is to take a copy into a `val`**, check the copy,
and use the copy:

```kotlin
// DraftFixed.kt
class Draft {
    var note: String? = "read chapter 3"
}

fun main() {
    val draft = Draft()
    val note = draft.note
    if (note != null) {
        println(note.length)
    }
}
```

```
ana@vm:~/kt/l02$ kotlinc DraftFixed.kt -include-runtime -d draftfixed.jar && java -jar draftfixed.jar
14
```

The local `note` is a `val`, so nothing can change it between the check and the use, and the smart
cast is allowed. The property can still change afterwards; what you printed is the value it had
when you copied it, which is what you checked.

## `is` casts the same way

The same mechanism works for any type check, not only `null`. `if (value is String)` makes `value` a
`String` inside the braces. Lesson 9 leans on that heavily, because it is what makes a `when` over a
sealed class read so cleanly.
