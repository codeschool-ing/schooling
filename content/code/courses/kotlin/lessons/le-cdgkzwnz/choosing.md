---
title: Choosing one, and when to use none
version: 1
---

The Kotlin documentation gives a short guide, and it is the two questions again in the order you
would ask them:

| you want to | use |
|---|---|
| run a block only when a value is not null | `?.let` |
| configure an object and get it back | `apply` |
| do something extra with an object in a chain, and pass it on | `also` |
| compute a result from an object, with its members unprefixed | `run`, or `with` when it is not a chain |
| compute a result with temporary names of its own | `run` with no object |

**None of these is required.** Every one of them can be written as plain statements with a named
`val`, and sometimes that is the clearer code. The cost of a scope function is that the reader has to
know which of the five it is before they can read the block.

## Nesting makes `this` ambiguous

A receiver can be left out, which is the point, and which goes wrong when two receivers are in scope
at once. Inside nested blocks, an unprefixed call goes to the **innermost** receiver that has a
member of that name, and only then outwards:

```kotlin
// Nested.kt
fun main() {
    val report = StringBuilder()
    val week = mutableListOf(45, 30)
    report.apply {
        week.apply {
            add(60)
            append("week: $this, ")
            append("size $size")
        }
    }
    println(report)
}
```

```
ana@vm:~/kt/l06$ kotlinc Nested.kt -include-runtime -d nested.jar && java -jar nested.jar
week: [45, 30, 60], size 3
```

`add` and `size` belong to the list, the inner receiver. `append` has no match on a list, so it
found the builder, the outer one. And `this` is always the innermost, the list. **The program is
correct and a reader has to resolve every call by hand to know it.** Nested `apply`, `run` or `with`
are the case where naming things pays: `report.append(…)`, or `also` and `let` with a name for the
parameter, say which object each line is about.

## Long chains of them

`x.let { … }.also { … }.run { … }.apply { … }` compiles. **Two in a row is a reason to stop and name
the intermediate value**, because each one changes what `it` and `this` mean and the reader has to
hold all of that at once. The scope functions save a line when they save a name; once they cost
understanding, the line was cheaper.
