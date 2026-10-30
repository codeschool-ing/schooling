---
title: Extension functions
version: 1
---

The planner prints minutes as hours in a dozen places, and `format(minutes)` from lesson 3 reads
backwards: the value comes second. **An extension function adds a function to a type you did not
write**, called with a dot as if it were a member:

```kotlin
// Extensions.kt
fun Int.asHours(): String = "${this / 60} h ${this % 60} min"

fun List<Int>.longest(): Int? = maxOrNull()

fun String?.orNone(): String = this ?: "none"

fun main() {
    println(135.asHours())
    println(listOf(45, 90, 30).longest())
    val note: String? = null
    println(note.orNone())
}
```

```
ana@vm:~/kt/l11$ kotlinc Extensions.kt -include-runtime -d extensions.jar && java -jar extensions.jar
2 h 15 min
90
none
```

`fun Int.asHours()` declares a function whose **receiver** is an `Int`; inside it, `this` is the number
it was called on. It is lesson 6's receiver again, now with a name. The receiver can be any type,
including a generic list and a nullable type: `orNone` is declared on `String?`, so it can be called on
a value that is `null`, and handles that case itself.

Most of the standard library you have used is extensions: `map`, `filter`, `sumOf`, `let`, `apply`.
They are declared on `Iterable` or on any type `T`, outside those types, which is why they work on
Java's collections, which know nothing about Kotlin.

## Resolved by the declared type

An extension is not really inside the class. **It is a static function that takes the receiver as its
first parameter**, and which one is called is decided at compile time, from the type the compiler sees:

```kotlin
// Dispatch.kt
open class Reminder
class ExamReminder : Reminder()

fun Reminder.kind() = "reminder"
fun ExamReminder.kind() = "exam reminder"

fun main() {
    val r: Reminder = ExamReminder()
    println(r.kind())
    println(ExamReminder().kind())
}
```

```
ana@vm:~/kt/l11$ kotlinc Dispatch.kt -include-runtime -d dispatch.jar && java -jar dispatch.jar
reminder
exam reminder
```

`r` holds an `ExamReminder`, and its declared type is `Reminder`, so the `Reminder` extension ran. An
overridden member would have picked the exam version at run time; **an extension cannot be
overridden**, because it is not a member. When behaviour has to depend on the real type of the object,
it belongs in the class, as an `open` member or an interface method.

## A member always wins

An extension with the same name and parameters as a member is never called:

```kotlin
// Shadow.kt
class Session {
    fun label() = "member"
}

fun Session.label() = "extension"

fun main() {
    println(Session().label())
}
```

```
ana@vm:~/kt/l11$ kotlinc Shadow.kt -include-runtime -d shadow.jar && java -jar shadow.jar
Shadow.kt:6:13: warning: this extension is shadowed by a member: 'fun label(): String' defined in 'Session'.
fun Session.label() = "extension"
            ^^^^^
member
```

The compiler warned that the extension is shadowed by the member, and the program printed `member`.
**Nobody can change what an existing method does by declaring an extension**, which is what makes
extensions safe to have everywhere. The rule is about members only: much of what looks built into
`String`, such as `uppercase()`, is itself an extension in the standard library, and an extension of
yours with the same name in your own file would take its place in that file. Choose names that do not
collide.
