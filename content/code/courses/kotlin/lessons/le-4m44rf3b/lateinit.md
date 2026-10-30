---
title: lateinit, for a value that arrives after construction
version: 1
---

Every property so far got its value when the object was built. Some cannot: on Android, a screen
object is created by the system, and the views and services it uses are handed to it a moment later.
**`lateinit var` declares a non-null property that is allowed to be empty until first assigned**,
without making it nullable and answering `null` at every use.

```kotlin
// Late.kt
class Screen {
    lateinit var title: String

    fun show() = println("showing $title")

    fun ready() = this::title.isInitialized
}

fun main() {
    val s = Screen()
    println(s.ready())
    s.title = "Week 44"
    println(s.ready())
    s.show()
    Screen().show()
}
```

```
ana@vm:~/kt/l07$ kotlinc Late.kt -include-runtime -d late.jar && java -jar late.jar
false
true
showing Week 44
Exception in thread "main" kotlin.UninitializedPropertyAccessException: lateinit property title has not been initialized
	at Screen.getTitle(Late.kt:3)
	at Screen.show(Late.kt:5)
	at LateKt.main(Late.kt:16)
	at LateKt.main(Late.kt)
```

`title` is a `String`, not a `String?`, so `show` uses it with no check. The price is the last line:
**reading a `lateinit` property before it is assigned throws
`UninitializedPropertyAccessException`**, with the property's name in the message. That is a crash,
like lesson 2's `!!`, and it is the same bet: that the value will be there when it is needed.

`this::title.isInitialized` asks whether the assignment has happened, which is occasionally useful in
cleanup code. Needing it often is a sign the property should have been nullable.

## The rules

`lateinit` is allowed only on a `var`, because it has to be assigned later, and only for a non-null
type that is not a primitive like `Int` or `Boolean`, because those have no empty state on the JVM to
mean "not yet".

## When to use it, and the alternative

**Use `lateinit` when something outside the class guarantees the assignment before any use**, and
the guarantee is part of how the framework works: Android's lifecycle, a test framework's setup
method in lesson 18. When the value can be computed by the class itself the first time it is needed,
lesson 11's `by lazy` is better: it cannot be read empty, because reading it is what fills it.
