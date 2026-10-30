---
title: A String is a collection of characters
version: 1
---

A `String` is a collection too, of `Character`s, and most of what you have just learnt works on it:
`count`, `first`, a `for` loop, `map`, `filter`. **What does not work is the one thing most languages
offer first: reading a character by an integer position.** The reason is that Swift counts characters
the way a reader does, and that is not the way memory stores them.

```swift
// Strings.swift
let course = "Programação"
print(course.count, course.utf8.count)
let composed = "é"
let decomposed = "e\u{301}"
print(composed == decomposed, composed.count, decomposed.count)
print(composed.utf8.count, decomposed.utf8.count)
print(course.prefix(4), course.uppercased(), course.contains("ama"))
let vowels = course.filter { "aeiouáãéíóõú".contains($0) }
print(vowels)
```

```
ana@vm:~/sw/l04$ swift Strings.swift
11 13
true 1 1
2 3
Prog PROGRAMAÇÃO true
oaaão
```

`"Programação"` is eleven characters, and it takes thirteen bytes in UTF-8, because `ç` and `ã` take two
bytes each. A program that counted bytes would tell a Portuguese-speaking student that the course name
is longer than it looks.

The second pair is the stranger case. `"e\u{301}"` is the letter `e` followed by a combining acute
accent, two Unicode scalars that a reader sees as one `é`. Swift agrees with the reader: **both strings
count as one character and compare equal**, though one takes two bytes and the other three. A name
typed on one keyboard and pasted from another document can arrive in either form, and `==` does the
right thing.

## No integer subscripts

```swift
// StringIndex.swift
let course = "Programação"
print(course[3])
```

```
ana@vm:~/sw/l04$ swiftc StringIndex.swift -o stringindex
StringIndex.swift:3:7: error: 'subscript(_:)' is unavailable: cannot subscript String with an Int, use a String.Index instead.
1 | // StringIndex.swift
2 | let course = "Programação"
3 | print(course[3])
  |       `- error: 'subscript(_:)' is unavailable: cannot subscript String with an Int, use a String.Index instead.
4 | 

Swift.String.subscript:3:10: note: 'subscript(_:)' has been explicitly marked unavailable here
1 | struct String {
2 | @available(*, unavailable, message: "cannot subscript String with an Int, use a String.Index instead.")
3 |   public subscript(i: Int) -> Character { get }}
  |          `- note: 'subscript(_:)' has been explicitly marked unavailable here
4 | 
```

The error is explicit, `cannot subscript String with an Int`, and the second note shows where the
standard library refuses it on purpose. Because a character may be one byte or four, finding the
fourth one means walking from the start; an integer subscript would look instant and be slow, so Swift
does not offer one. **What it offers instead is `String.Index`**, a position you get by walking:

```swift
// StringIndexFixed.swift
let course = "Programação"
let fourth = course.index(course.startIndex, offsetBy: 3)
print(course[fourth])
print(course[fourth...])
if let space = "Swift basics".firstIndex(of: " ") {
    print("Swift basics"[..<space])
}
```

```
ana@vm:~/sw/l04$ swift StringIndexFixed.swift
g
gramação
Swift
```

`index(_:offsetBy:)` walks three characters from the start and returns that position. `course[fourth...]`
is everything from there on, and `firstIndex(of:)` finds a character, returning an optional index. In
practice you will rarely count positions at all: `prefix`, `split`, `contains` and `firstIndex(of:)`
cover most of what a planner does with text.
