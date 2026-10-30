---
title: map and filter
version: 1
---

Most of what a program does with a list is one of two things: **keep some of the items**, or **turn
each item into something else**. `filter` and `map` are those two, and they are higher-order
functions exactly like lesson 4's `countWhere`: a loop written once, with the varying part as a
lambda.

Until lesson 7 gives the planner classes of its own, a session is a `Pair`: a course and a number of
minutes, built with `to`. `"Kotlin" to 45` is a `Pair<String, Int>`, and its two halves are
`first` and `second`.

```schooling-example
{"language": "kotlin", "file": "MapFilter.kt", "parts": [{"code": "fun main() {\n    val sessions = listOf(\"Kotlin\" to 45, \"Android\" to 30, \"Kotlin\" to 60, \"Go\" to 20)", "note": "Four sessions. `to` is a function written between its two arguments, which lesson 11 shows how to declare."}, {"code": "    println(sessions.filter { it.second >= 45 })", "note": "`filter` keeps the items for which the lambda says `true`, in their original order. The result is a new list; `sessions` is untouched."}, {"code": "    println(sessions.map { it.second })\n    println(sessions.map { \"${it.first}: ${it.second} min\" })", "note": "`map` builds a new list with one item for every item of the old one, each the lambda's result. The new list can hold a different type: `Int`s, then `String`s."}, {"code": "    println(sessions.filter { it.first == \"Kotlin\" }.map { it.second }.sum())", "note": "The calls chain. Read it left to right: the Kotlin sessions, their minutes, the total."}, {"code": "    println(sessions.mapNotNull { if (it.second >= 45) it.first else null })\n}", "note": "`mapNotNull` maps and drops the `null` results in one step, and its result type is `List<String>`, not `List<String?>`."}]}
```

```
ana@vm:~/kt/l05$ kotlinc MapFilter.kt -include-runtime -d mapfilter.jar && java -jar mapfilter.jar
[(Kotlin, 45), (Kotlin, 60)]
[45, 30, 60, 20]
[Kotlin: 45 min, Android: 30 min, Kotlin: 60 min, Go: 20 min]
105
[Kotlin, Kotlin]
```

## Every step makes a new list

`sessions.filter { … }.map { … }.sum()` built two lists on the way to one number: the filtered list
and the mapped one. **For a list of four items, nobody will ever notice.** For a list of a million,
or a chain of six steps, those intermediate lists are the cost, and section 07 shows the lazy
alternative that builds none of them.

## The loop it replaces

The same total written as a loop:

```kotlin
var total = 0
for (s in sessions) {
    if (s.first == "Kotlin") total += s.second
}
```

Both are correct. The chain says **what** is computed and the loop says **how**, and the chain has
no `var` that a later edit could reuse by mistake. That is why Kotlin code reaches for the chain
first and keeps the loop for the cases where several things happen per item and naming them would
take more space than the loop does.
