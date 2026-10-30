---
title: Closures: what a lambda remembers
version: 1
---

A lambda can use names from around it, the parameters and local variables of the function it is
written in. **It does not copy their values; it keeps the variables themselves**, and it keeps them
for as long as the lambda exists, even after the function that declared them has returned. A lambda
together with the variables it holds on to is called a closure.

```kotlin
// Closures.kt
fun makeCounter(): () -> Int {
    var count = 0
    return { ++count }
}

fun main() {
    var total = 0
    val add: (Int) -> Unit = { total += it }
    add(45)
    add(30)
    println(total)

    val next = makeCounter()
    println(next())
    println(next())
    val other = makeCounter()
    println(other())
    println(next())
}
```

```
ana@vm:~/kt/l04$ kotlinc Closures.kt -include-runtime -d closures.jar && java -jar closures.jar
75
1
2
1
3
```

Two things happen here that a value copy could not explain.

**`add` changed `total`.** The lambda holds `total` itself, a `var` of `main`, so `total += it`
changes the variable `main` prints. Java's lambdas cannot do this: they may only read local
variables that are effectively final. Kotlin allows it, and on the JVM it works by moving `total`
into a small heap object that both `main` and the lambda point at.

**`makeCounter` returned, and `count` lived on.** Each call to `makeCounter` makes a new `count` and
a lambda that holds it. `next` and `other` hold different `count`s, which is why `other()` printed 1
while `next()` went on to 3. The variable outlived the function that declared it, because a lambda
still needed it.

## The surprise this causes

A lambda reads the variable when it runs, not when it was written:

```kotlin
// Late.kt
fun main() {
    var course = "Kotlin"
    val show = { println("studying $course") }
    course = "Android"
    show()
}
```

```
ana@vm:~/kt/l04$ kotlinc Late.kt -include-runtime -d late.jar && java -jar late.jar
studying Android
```

`show` was written while `course` was `"Kotlin"` and printed `"Android"`, because by the time it ran
that was the value of the variable it holds. **The fix, when you want the value at the time of
writing, is a `val` copy**, taken before the lambda is made. This is the same rule as lesson 2's
smart casts, from the other side: a `var` that something else can see is a `var` that can change
under you.

This matters most later, in lessons 14 and 15, when a lambda runs on another thread or after a
delay. A closure that captures a `var` and runs elsewhere is the classic way to read a value that
has moved on, and Kotlin's coroutines are designed so you rarely need one.
