---
title: What a data class leaves out
version: 1
---

Everything a data class generates is built from **the properties of its primary constructor, and
nothing else**. That is a precise rule with consequences that are easy to miss.

## A property in the body is invisible to `equals`

```kotlin
// Body.kt
data class Session(val course: String, val minutes: Int) {
    var note: String = ""
}

fun main() {
    val a = Session("Kotlin", 45).apply { note = "chapter 3" }
    val b = Session("Kotlin", 45).apply { note = "chapter 9" }
    println(a == b)
    println(a)
}
```

```
ana@vm:~/kt/l08$ kotlinc Body.kt -include-runtime -d body.jar && java -jar body.jar
true
Session(course=Kotlin, minutes=45)
```

Two sessions with different notes are equal, and `toString` does not show the note. That can be
deliberate, a cached value that should not affect identity, and **it is a bug whenever the property is
part of what the session is**. If it belongs, it goes in the constructor.

## An array compares by identity

```kotlin
// ArrayProp.kt
data class Week(val minutes: IntArray)

fun main() {
    println(Week(intArrayOf(45, 30)) == Week(intArrayOf(45, 30)))
    println(listOf(45, 30) == listOf(45, 30))
}
```

```
ana@vm:~/kt/l08$ kotlinc ArrayProp.kt -include-runtime -d arrayprop.jar && java -jar arrayprop.jar
false
true
```

It compiled without a word, and the answer is `false`. **An array's `equals` is `===`**, so the
generated `equals` compares the two arrays as objects. Two weeks with the same minutes are
not equal. A `List` compares its items, which the second line shows, and is what a data class should
hold.

## The rules the compiler enforces

- the primary constructor needs **at least one parameter, and every parameter must be a `val` or
  `var`**, since a plain parameter is not a property and could not take part;
- a data class **cannot be `open`, `abstract` or `inner`**: generated `equals` and `copy` do not
  survive being inherited, because a subclass would have properties the generated code knows
  nothing about;
- it **can** implement interfaces and extend another class, and it can declare its own `toString` or
  `equals`, in which case the compiler does not generate that one.

The second rule matters for lesson 9. A family of related data shapes, a session that is planned,
running or done, is not a data class with subclasses. It is a sealed hierarchy, whose members are each
a data class of their own.
