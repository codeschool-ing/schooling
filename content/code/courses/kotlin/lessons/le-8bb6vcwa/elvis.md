---
title: The elvis operator, ?:
version: 1
---

A safe call keeps a missing value missing. Sooner or later the program needs a real value, and
`?:` gives it one: `a ?: b` is `a` when `a` is not `null`, and `b` when it is. Tilt your head to
the left and the operator looks like a quiff and two eyes, which is where the name comes from.

The planner reads a number of minutes from text a student typed, and text is not always a number.
`toIntOrNull()` turns `"45"` into `45` and anything it cannot read into `null`, so its type is
`Int?`. The elvis operator turns that into an `Int`:

```schooling-example
{"language": "kotlin", "file": "Elvis.kt", "parts": [{"code": "fun minutesFrom(input: String): Int {\n    return input.toIntOrNull() ?: 0\n}", "note": "A function that promises an `Int`. `toIntOrNull()` gives an `Int?`, and `?: 0` answers the missing case, so the expression as a whole is an `Int` and the promise is kept."}, {"code": "fun describe(note: String?): String {\n    val text = note ?: return \"no note\"\n    return \"note: $text (${text.length} chars)\"\n}", "note": "The right side of `?:` may also leave the function. `return` there means: if there is no note, this function is finished. Past that line `text` is a `String`, never null."}, {"code": "fun main() {\n    println(minutesFrom(\"45\"))\n    println(minutesFrom(\"forty\"))\n    println(minutesFrom(\"\"))\n    println(describe(null))\n    println(describe(\"read chapter 3\"))\n}", "note": "Five calls: two that can be read, two that cannot, one with no note at all. Lesson 3 is about functions; here they only give the operator somewhere to stand."}]}
```

```
ana@vm:~/kt/l02$ kotlinc Elvis.kt -include-runtime -d elvis.jar && java -jar elvis.jar
45
0
0
no note
note: read chapter 3 (14 chars)
```

## A default is a decision

`?: 0` makes the program carry on, and that is not always the right thing. **A minute count of
zero for `"forty"` is a guess the program made on the student's behalf**, and the weekly total is
now wrong without anyone being told. The elvis operator makes the decision easy to write, which is
different from making it correct. Three right-hand sides, three decisions:

| right side | when it is the right answer |
|---|---|
| a value, `?: 0` | when a missing value really means that value: no sessions means a total of 0 |
| `?: return …` | when the rest of the function has nothing to do without the value |
| `?: throw IllegalArgumentException("…")` | when a missing value is a mistake somebody has to hear about |

`throw` is an expression in Kotlin, so it can sit on the right of `?:` like `return` does. Lesson
13 is about failure and returns to it; the point here is that **the operator is the place where a
program says what absence means**, and it is worth a second to choose.

## Precedence

`?:` binds more loosely than almost everything else, so `a?.length ?: 0 + 1` is `a?.length ?: (0 + 1)`,
not `(a?.length ?: 0) + 1`. When the right side is more than a single value, write the parentheses.
