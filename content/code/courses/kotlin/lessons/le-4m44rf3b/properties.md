---
title: Properties: getters, setters and the backing field
version: 1
---

A Kotlin property is not a field. **It is a pair of functions, a getter and, for a `var`, a setter,
that usually happen to read and write a field.** `s.done = true` calls the setter, and `s.done` calls
the getter, even though the code reads like a field access. That is why a property can be changed
later to compute its value or check what is written, without any caller changing.

```schooling-example
{"language": "kotlin", "file": "Goal.kt", "parts": [{"code": "class Goal(val course: String, minutes: Int) {", "note": "`minutes` is a plain parameter here, so the class can declare a property of that name with rules of its own."}, {"code": "    var minutes: Int = minutes\n        set(value) {\n            require(value >= 0) { \"a goal cannot be negative: $value\" }\n            field = value\n        }", "note": "A custom setter. `value` is what was assigned; `field` is the **backing field**, the storage behind the property. Writing `minutes = value` here instead would call the setter again, forever."}, {"code": "    val hours: Double\n        get() = minutes / 60.0\n}", "note": "A property with only a getter and no backing field at all: it is computed each time it is read."}, {"code": "fun main() {\n    val g = Goal(\"Kotlin\", 300)\n    println(g.hours)\n    g.minutes = 450\n    println(g.hours)\n    g.minutes = -5\n}", "note": "Reading `hours` after changing `minutes` shows the new value, because nothing was stored. The last line goes through the setter's check."}]}
```

```
ana@vm:~/kt/l07$ kotlinc Goal.kt -include-runtime -d goal.jar && java -jar goal.jar
5.0
7.5
Exception in thread "main" java.lang.IllegalArgumentException: a goal cannot be negative: -5
	at Goal.setMinutes(Goal.kt:4)
	at GoalKt.main(Goal.kt:15)
	at GoalKt.main(Goal.kt)
```

The stack trace names `Goal.setMinutes`: **`g.minutes = -5` was a call to a function**, generated
from the property, which is what the first paragraph claimed.

## A computed property or a function

`val hours get() = …` and `fun hours() = …` do the same work. The convention is about what the
caller can assume: **a property should be cheap, have no side effects, and give the same answer
twice in a row** if nothing else changed. `hours` qualifies. Something that reads a file, or counts a
million items, should be a function, so that its cost is visible as a call.

## The setter is where a rule lives

The check in the setter means **no code anywhere can store a negative goal**, not the constructor, not
a screen, not a test. Put the same check in every caller and the one that forgets is the bug. The
initial value went through no setter, though: `var minutes: Int = minutes` writes the field directly
when the object is built, so a negative value passed to the constructor would get in. Section 04's
`init` blocks close that gap.

## Visibility of a setter

A setter can be less visible than its getter: `var total: Int = 0` followed by `private set` gives a
property everyone can read and only the class can write. Section 06 uses that.
