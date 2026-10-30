---
title: Sorting, grouping, and finding the largest
version: 1
---

A planner report wants the longest sessions first and the minutes per course. Both are one call.

```swift
// Sorting.swift
let week: [(course: String, minutes: Int)] = [
    ("Swift", 45), ("Kotlin", 30), ("Swift", 60), ("SQL", 20), ("Kotlin", 50),
]
print([45, 30, 60, 20, 50].sorted())
let longestFirst = week.sorted { $0.minutes > $1.minutes }
print(longestFirst.map { "\($0.course) \($0.minutes)" })
let byCourseThenLength = week.sorted {
    ($0.course, $1.minutes) < ($1.course, $0.minutes)
}
print(byCourseThenLength.map { "\($0.course) \($0.minutes)" })
if let longest = week.max(by: { $0.minutes < $1.minutes }) {
    print("longest:", longest.course, longest.minutes)
}
```

```
ana@vm:~/sw/l04$ swift Sorting.swift
[20, 30, 45, 50, 60]
["Swift 60", "Kotlin 50", "Swift 45", "Kotlin 30", "SQL 20"]
["Kotlin 50", "Kotlin 30", "SQL 20", "Swift 60", "Swift 45"]
longest: Swift 60
```

`sorted()` with no argument works on anything that can be compared with `<`, such as numbers and
strings. For anything else, **`sorted(by:)` takes a closure answering one question: should the first
of these two come before the second?** `$0.minutes > $1.minutes` says the longer one comes first.

The second sort compares tuples, which Swift compares element by element: by course name first and,
only when the names are equal, by minutes. Swapping `$0` and `$1` in the second position turns that half
of the comparison round, so each course's sessions come longest first. `max(by:)` takes the same kind of
closure and returns an optional, because an empty array has no largest item.

## Grouping

```swift
// Grouping.swift
let week: [(course: String, minutes: Int)] = [
    ("Swift", 45), ("Kotlin", 30), ("Swift", 60), ("SQL", 20), ("Kotlin", 50),
]
let byCourse = Dictionary(grouping: week) { $0.course }
let totals = byCourse.mapValues { sessions in
    sessions.reduce(0) { $0 + $1.minutes }
}
for course in totals.keys.sorted() {
    print(course, byCourse[course]?.count ?? 0, totals[course] ?? 0)
}
```

```
ana@vm:~/sw/l04$ swift Grouping.swift
Kotlin 2 80
SQL 1 20
Swift 2 105
```

`Dictionary(grouping:by:)` walks the array once and files each session under the key the closure
returns, so `byCourse` is a `[String: [(course: String, minutes: Int)]]`: every course with its list of
sessions. `mapValues` is `map` for a dictionary's values, keeping the keys, and here it turns each list
into a total. **Grouping and then reducing each group** is the shape of nearly every summary a planner
shows: per course, per day, per week. Section 03's warning still holds, so the loop sorts the keys.
