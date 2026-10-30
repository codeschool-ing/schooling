---
title: Patterns, where and if case
version: 1
---

The `case` lines of a switch are **patterns**: descriptions of a shape a value can match, which may
bind parts of it to names on the way. Section 04 used three kinds, a case with bindings, a range and
`default`. There are more, and they combine. This program classifies sessions by minutes and by
whether they were done:

```schooling-example
{"language": "swift", "file": "Patterns.swift", "parts": [{"code": "// Patterns.swift\nenum Activity {\n    case reading(pages: Int)\n    case video(minutes: Int)\n}\nlet goal = 45", "note": "A smaller `Activity` than section 03's, and a goal for one session."}, {"code": "func describe(minutes: Int, done: Bool) -> String {\n    switch (minutes, done) {\n    case (_, false):\n        return \"not done yet\"\n    case (0..<15, true):\n        return \"a short one\"\n    case (15..<60, true):\n        return \"a solid session\"\n    default:\n        return \"a long one\"\n    }\n}", "note": "A switch on a tuple of two values. `_` matches anything, a range matches a number inside it, and the first matching case wins."}, {"code": "func verdict(_ minutes: Int) -> String {\n    switch minutes {\n    case let m where m >= goal:\n        return \"goal met by \\(m - goal)\"\n    case let m:\n        return \"\\(goal - m) short\"\n    }\n}", "note": "`case let m` binds the whole value, and `where` adds a condition the pattern alone cannot express. The second case matches whatever is left, so no `default` is needed."}, {"code": "print(describe(minutes: 50, done: false), describe(minutes: 10, done: true), describe(minutes: 50, done: true), describe(minutes: 90, done: true))\nprint(verdict(60), verdict(30))", "note": "Four sessions through the first switch, two through the second."}, {"code": "let plan: [Activity] = [.reading(pages: 12), .video(minutes: 20), .video(minutes: 15)]\nif case .reading(let pages) = plan[0] {\n    print(\"starts with \\(pages) pages\")\n}\nvar videoMinutes = 0\nfor case .video(let minutes) in plan {\n    videoMinutes += minutes\n}\nprint(\"videos:\", videoMinutes)", "note": "`if case` tests one pattern; `for case` loops only over the elements that match it, binding as it goes."}], "output": "not done yet a short one a solid session a long one\ngoal met by 15 15 short\nstarts with 12 pages\nvideos: 35"}
```

The first switch matched a **tuple**, two values in brackets, against tuple patterns, and that is how
a switch decides on two things at once. **The cases are tried from the top and the first match
wins**, so the order is part of the logic: `(_, false)` sits first, and catches every undone session
before any range is consulted.

`where` adds a condition to a pattern after its bindings, and the second switch used it to compare
the bound minutes with the goal, which a range written in the pattern could not do since the goal
is a variable.

## When one case is all you want

A switch has to cover everything, and sometimes the question is only "is it this case?".
**`if case` matches one pattern and runs its body only if it fits**, binding names as a switch would.
`for case` does the same inside a loop and skips the elements that do not fit, which is how the last
lines add up only the videos.

The syntax reads backwards at first: the pattern is on the left and the value on the right of `=`,
as in `if case .video(let minutes) = activity`. Read it as "if the case `.video(let minutes)`
matches `activity`".
