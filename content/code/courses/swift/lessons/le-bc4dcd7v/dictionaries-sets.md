---
title: Dictionaries and sets
version: 1
---

Two more collections, and each answers a different question from an array's. **A dictionary answers
"what goes with this key?"**: the minutes studied for each course. **A set answers "is this in
here?"**: the days a course has sessions. Neither keeps an order.

## A dictionary looks things up by key

```swift
// Dictionaries.swift
var minutesByCourse = ["Swift": 135, "Kotlin": 60]
minutesByCourse["SQL"] = 30
minutesByCourse["Swift", default: 0] += 45
minutesByCourse["Go", default: 0] += 20
print(minutesByCourse["Swift"] ?? 0)
print(String(describing: minutesByCourse["Rust"]))
minutesByCourse["Kotlin"] = nil
print(minutesByCourse.count)
for course in minutesByCourse.keys.sorted() {
    print(course, minutesByCourse[course] ?? 0)
}
```

```
ana@vm:~/sw/l04$ swift Dictionaries.swift
180
nil
3
Go 20
SQL 30
Swift 180
```

The type is `[String: Int]`: keys of one type, values of another. **Reading by key gives an optional**,
since the key may not be there, and `"Rust"` was not. `?? 0` is lesson 2's answer. The form with
`default:` is the one to use for a running total: it reads 0 for a missing key, adds to it and stores
the result, so `"Go"` arrived with 20 without being created first. Assigning `nil` removes a key.

## A dictionary has no order

The last loop sorted the keys before printing them. That was not decoration:

```swift
// Unordered.swift
let minutesByCourse = ["Swift": 135, "Kotlin": 60, "SQL": 30, "Go": 20]
print(minutesByCourse)
```

```
ana@vm:~/sw/l04$ swift Unordered.swift
["Swift": 135, "Go": 20, "SQL": 30, "Kotlin": 60]
ana@vm:~/sw/l04$ swift Unordered.swift
["Kotlin": 60, "SQL": 30, "Swift": 135, "Go": 20]
ana@vm:~/sw/l04$ swift Unordered.swift
["Kotlin": 60, "Swift": 135, "SQL": 30, "Go": 20]
```

**The same program, run three times, printed the same dictionary in different orders.** A dictionary
stores its keys where their hash puts them, and Swift seeds its hashing differently in every process,
on purpose: it makes the order impossible to depend on by accident. When a report needs an order,
sort the keys, as the first program did, or use an array of pairs.

## A set holds each value once

```swift
// Sets.swift
var swiftDays: Set = ["Mon", "Wed", "Fri"]
let kotlinDays: Set = ["Wed", "Thu"]
print(swiftDays.contains("Wed"), swiftDays.contains("Tue"))
let result = swiftDays.insert("Mon")
print(result.inserted, swiftDays.count)
print(swiftDays.intersection(kotlinDays).sorted())
print(swiftDays.union(kotlinDays).sorted())
print(swiftDays.subtracting(kotlinDays).sorted())
```

```
ana@vm:~/sw/l04$ swift Sets.swift
true false
false 3
["Wed"]
["Fri", "Mon", "Thu", "Wed"]
["Fri", "Mon"]
```

Inserting `"Mon"` a second time did nothing, and `insert` said so: `inserted` is `false` and the
count is still three. **`contains` on a set takes the same short time however large the set is**,
which on an array would mean walking every item. The three operations answer the questions a planner
asks: the days both courses share, the days with any session, the days only Swift has. They print
sorted for the same reason the dictionary did.

| question | collection |
|---|---|
| in what order, and what is at position 3? | array |
| what is the value for this key? | dictionary |
| is this one in it, and what do two have in common? | set |
