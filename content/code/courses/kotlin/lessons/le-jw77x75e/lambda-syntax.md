---
title: Writing a lambda
version: 1
---

A lambda is braces around a list of parameters, an arrow, and a body. Four rules cover almost every
lambda you will read:

```schooling-example
{"language": "kotlin", "file": "Lambdas.kt", "parts": [{"code": "fun main() {\n    val isLong = { minutes: Int -> minutes >= 60 }", "note": "With nothing on the left to say what the parameter is, the lambda declares its type itself. The type of `isLong` is then inferred: `(Int) -> Boolean`."}, {"code": "    val half: (Int) -> Int = { it / 2 }", "note": "**A lambda with exactly one parameter can leave it unnamed** and call it `it`, when the type is known from elsewhere, here the declared type on the left."}, {"code": "    val describe: (Int) -> String = { minutes ->\n        val hours = minutes / 60\n        val rest = minutes % 60\n        \"$hours h $rest min\"\n    }", "note": "A lambda can have several lines. **The value of its last expression is its result**: there is no `return`."}, {"code": "    val courseOnly: (String, Int) -> String = { course, _ -> course }", "note": "`_` names a parameter the lambda does not use, which says so to a reader and stops the compiler warning."}, {"code": "    println(isLong(90))\n    println(half(45))\n    println(describe(135))\n    println(courseOnly(\"Kotlin\", 45))\n}"}]}
```

```
ana@vm:~/kt/l04$ kotlinc Lambdas.kt -include-runtime -d lambdas.jar && java -jar lambdas.jar
true
22
2 h 15 min
Kotlin
```

## `return` does not mean what it seems

The last expression is the result, so a `return` inside a lambda is not needed, and in most places
it is not allowed:

```kotlin
// LambdaReturn.kt
fun main() {
    val double: (Int) -> Int = { m -> return m * 2 }
    println(double(45))
}
```

```
ana@vm:~/kt/l04$ kotlinc LambdaReturn.kt -include-runtime -d lambdareturn.jar
LambdaReturn.kt:3:39: error: 'return' is prohibited here.
    val double: (Int) -> Int = { m -> return m * 2 }
                                      ^^^^^^
LambdaReturn.kt:3:46: error: return type mismatch: expected 'Unit', actual 'Int'.
    val double: (Int) -> Int = { m -> return m * 2 }
                                             ^^^^^
```

**A bare `return` in Kotlin always returns from the nearest function declared with `fun`**, and the
lambda is not one. Here that would be `main`, which returns `Unit` and cannot return `m * 2`, and
even where the types fit the compiler refuses, for a reason section 08 gives. When you need to leave
a lambda early, the form is a labelled return, `return@label`, which section 08 also shows.

## When to name `it`

`it` is short, and it is unreadable when lambdas nest, because the inner `it` hides the outer one.
**Name the parameter when the lambda is longer than a line, or when it sits inside another lambda.**
`{ it >= 60 }` is clear; `{ session -> session.minutes >= 60 }` is clearer the moment there are two
things the lambda could be talking about.
