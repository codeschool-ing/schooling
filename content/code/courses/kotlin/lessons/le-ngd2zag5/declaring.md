---
title: Declaring a function
version: 1
---

A function in Kotlin is `fun`, a name, the parameters in parentheses with a type after each, and
the return type after a colon. **Parameters always have their types written**; it is the one place
where inference never applies, because a function is a promise to callers the compiler has not
seen yet.

The planner needs the total of a week's sessions:

```schooling-example
{"language": "kotlin", "file": "Total.kt", "parts": [{"code": "fun total(minutes: List<Int>): Int {", "note": "One parameter, a list of whole numbers, and a promise to return an `Int`. `List<Int>` reads as a list of `Int`; lesson 12 explains the angle brackets."}, {"code": "    var sum = 0\n    for (m in minutes) {\n        sum += m\n    }\n    return sum\n}", "note": "A block body: statements in braces, and `return` to hand back the result. The `var` lives only inside the function."}, {"code": "fun main() {\n    val week = listOf(45, 30, 60)\n    println(total(week))\n}", "note": "A call passes values in the order the parameters were declared."}]}
```

```
ana@vm:~/kt/l03$ kotlinc Total.kt -include-runtime -d total.jar && java -jar total.jar
135
```

A parameter is a `val`. **Inside `total`, `minutes = listOf()` does not compile**, which is the same
rule as lesson 1 applied to the names a caller hands you. A function that needs to change a value
makes its own `var`, as `sum` is here.

## The compiler checks every way out

A function that promises an `Int` must return one on every path through it. Forget a path, and the
compiler names the line where the function ends without one:

```kotlin
// Hours.kt
fun hours(minutes: Int): Int {
    if (minutes > 0) {
        return minutes / 60
    }
}

fun main() {
    println(hours(90))
}
```

```
ana@vm:~/kt/l03$ kotlinc Hours.kt -include-runtime -d hours.jar
Hours.kt:6:1: error: missing return statement.
}
^
```

The missing path is `minutes` of zero or less. In Java the same mistake is the same error; what
Kotlin adds is the next section, where an `if` stops being a statement and becomes a value, and the
missing `else` stops compiling for a different reason.

## Where functions live

`total` is declared at the top of the file, outside any class. **Kotlin calls this a top-level
function, and it is the normal place for a function**, not a workaround. Java would have needed a
class with a `static` method, and lesson 1 showed that the compiler builds exactly that for you,
`TotalKt`, out of sight. Section 06 returns to where functions can be declared and who can see them.

## Arguments are evaluated first, left to right

`total(listOf(45, 30, 60))` builds the list, then calls `total`. With several arguments, each is
evaluated in the order written, before the function body starts. That sounds obvious until an
argument has a side effect, such as printing or reading a file, and then the order is the
difference between a correct log and a confusing one. Kotlin guarantees it, even with the named
arguments of section 04 written out of order.
