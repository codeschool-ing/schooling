---
title: Inheritance: final by default, open by choice
version: 1
---

Java lets any class be extended unless it says `final`. **Kotlin is the other way round: every class
and every member is `final` unless it says `open`**, so extending a class somebody did not design for
it does not compile:

```kotlin
// Final.kt
class Session(val minutes: Int)

class TimedSession(minutes: Int, val startedAt: String) : Session(minutes)

fun main() {
    println(TimedSession(45, "14:30").minutes)
}
```

```
ana@vm:~/kt/l11$ kotlinc Final.kt -include-runtime -d final.jar
Final.kt:4:59: error: this type is final, so it cannot be extended.
class TimedSession(minutes: Int, val startedAt: String) : Session(minutes)
                                                          ^^^^^^^
```

The reason is a long-known failure of inheritance: a subclass depends on the internal behaviour of
its parent, which the parent's author is free to change, and the subclass breaks without either side
having done anything wrong. **Making extension an explicit decision means the author of a class knows
it will be extended**, and designs for it.

## `open`, `abstract` and `override`

```kotlin
// Inheritance.kt
abstract class Reminder(val course: String) {
    abstract fun message(): String
    open fun prefix() = "reminder"
    fun show() = "${prefix()}: ${message()}"
}

class DailyReminder(course: String, val minutes: Int) : Reminder(course) {
    override fun message() = "$minutes min of $course today"
}

class ExamReminder(course: String, val date: String) : Reminder(course) {
    override fun prefix() = "EXAM"
    override fun message() = "$course on $date"
}

fun main() {
    val reminders: List<Reminder> = listOf(DailyReminder("Kotlin", 45), ExamReminder("Android", "2026-12-01"))
    reminders.forEach { println(it.show()) }
}
```

```
ana@vm:~/kt/l11$ kotlinc Inheritance.kt -include-runtime -d inheritance.jar && java -jar inheritance.jar
reminder: 45 min of Kotlin today
EXAM: Android on 2026-12-01
```

| on a member | means |
|---|---|
| nothing | final: subclasses cannot replace it, like `show` |
| `open` | subclasses may replace it, like `prefix` |
| `abstract` | subclasses must provide it; the class itself cannot be built |
| `override` | this replaces a parent's member; it is itself `open` unless marked `final override` |

`abstract class` cannot be instantiated, `Reminder("Kotlin")` is refused, and its subclasses pass the
constructor argument up with `: Reminder(course)`. **`show` calls `prefix()` and `message()`, and gets
the subclass's versions at run time**: that is what overriding is for.

## Prefer interfaces and composition

Kotlin makes inheritance deliberate because the alternatives are usually better. An interface states
a promise without tying anybody to an implementation; delegation, in the next section, reuses an
implementation without inheriting from it. **Reach for `open` when a family of classes genuinely shares
behaviour that is designed to be specialised**, as Android's own framework classes are.
