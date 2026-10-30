---
title: Arrays, in order and by position
version: 1
---

An **array** is an ordered list of values of one type. `[45, 30, 60]` is an `[Int]`, short for
`Array<Int>`, and every item in it is an `Int`: the compiler will not let a `String` in. Order is the
point of an array, and the position of an item is its **index**, counted from zero.

```swift
// Arrays.swift
var sessions = [45, 30, 60]
sessions.append(20)
sessions += [50]
print(sessions, sessions.count)
print(sessions[0], sessions[sessions.count - 1])
sessions.insert(15, at: 0)
let removed = sessions.remove(at: 2)
print(sessions, "removed \(removed)")
for (index, minutes) in sessions.enumerated() {
    print(index, minutes)
}
let empty: [Int] = []
print(empty.isEmpty, String(describing: empty.first), String(describing: sessions.first))
```

```
ana@vm:~/sw/l04$ swift Arrays.swift
[45, 30, 60, 20, 50] 5
45 50
[15, 45, 60, 20, 50] removed 30
0 15
1 45
2 60
3 20
4 50
true nil Optional(15)
```

`append` adds one item at the end and `+=` adds a whole array. `insert(_:at:)` and `remove(at:)` work
by position, and `remove` hands back what it took out. `enumerated()` gives each item together with
its index, as a pair the loop takes apart into two names. **`first` and `last` are optionals**,
because an empty array has neither, which is lesson 2 arriving in a place you will meet every day.

## An index that is not there

`sessions[0]` is not optional. Swift trusts you to know the array is long enough, and checks while the
program runs:

```swift
// OutOfRange.swift
let sessions = [45, 30]
print(sessions[5])
```

```
ana@vm:~/sw/l04$ swiftc OutOfRange.swift -o outofrange
ana@vm:~/sw/l04$ ./outofrange 2>&1 | head -3
Swift/ContiguousArrayBuffer.swift:695: Fatal error: Index out of range

*** Signal 4: Backtracing from 0x7fdd0f3731ef... done ***
```

**Reading past the end stops the program**, with the same kind of report as lesson 1's overflow, and
the first line says why. It names a file of the standard library rather than yours, because that is
where the check lives; the line of yours that asked is further down the full report. It is the right outcome: in C, the same line reads whatever
memory happens to sit there, and the program carries on with a number nobody wrote. When you are not
sure an index exists, check `sessions.indices.contains(5)` first, or use `first` and `last`, which ask
the question for you.

## A let array is a fixed array

Lesson 1 said that what `let` means for a list would wait for lesson 5. Here is the half you need now:

```swift
// LetArray.swift
let sessions = [45, 30]
sessions.append(60)
print(sessions)
```

```
ana@vm:~/sw/l04$ swiftc LetArray.swift -o letarray
LetArray.swift:3:10: error: cannot use mutating member on immutable value: 'sessions' is a 'let' constant
1 | // LetArray.swift
2 | let sessions = [45, 30]
  | `- note: change 'let' to 'var' to make it mutable
3 | sessions.append(60)
  |          `- error: cannot use mutating member on immutable value: 'sessions' is a 'let' constant
4 | print(sessions)
5 | 
```

`append` is a **mutating** member: it changes the array it is called on, and a `let` array cannot be
changed at all, not even by adding to the end. The note offers the fix. Lesson 5 explains why an array
behaves like a number here and not like an object somebody else could change behind your back, which
is the deeper reason.
