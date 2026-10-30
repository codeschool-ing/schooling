---
title: A block that builds a value
version: 1
---

The other half of a SwiftUI screen looks like this. Again, it is Apple's documented form and **not
run here**:

```swift
var body: some View {
    VStack {
        Text("This week")
        Text("135 of 300 minutes")
        if minutes > 300 {
            Text("Goal reached")
        }
    }
}
```

Look at what is inside the braces of `VStack`: three `Text` values on lines of their own, and an `if`
with a fourth. **Nothing is returned, nothing is appended, and no commas separate them.** In a normal
closure from lesson 3, those lines would create three values and throw each one away. Here they become
the stack's contents, because `VStack`'s parameter is marked with a **result builder**: an attribute
that tells the compiler to collect the value of each line in the block and combine them into one.

## One you can run today

SwiftUI is not on Linux, but Swift's standard toolchain ships another result builder, in the module
`RegexBuilder`, and it builds a regular expression out of pieces that read like a description. Here
it reads a line of the planner's log, a date, a course and some minutes:

```swift
// LogLine.swift
import RegexBuilder

let line = "2026-11-02 Swift 45"
let pattern = Regex {
    Capture {
        Repeat(.digit, count: 4)
        "-"
        Repeat(.digit, count: 2)
        "-"
        Repeat(.digit, count: 2)
    }
    " "
    Capture { OneOrMore(.word) }
    " "
    Capture { OneOrMore(.digit) }
}

if let match = line.wholeMatch(of: pattern) {
    print("date:", match.1)
    print("course:", match.2)
    print("minutes:", match.3)
}
```

```
ana@vm:~/sw/l16$ swift LogLine.swift
date: 2026-11-02
course: Swift
minutes: 45
```

**The same shape as `VStack`**: a block of lines, each producing a piece, and no glue between them.
`Regex { … }` collects the pieces in order, a capture, a space, a capture, a space, a capture, and
`wholeMatch` checks the line against all of them. The three captures come back as `match.1` to
`match.3`.

## What the block is really doing

It looks like a new kind of syntax, and it is ordinary Swift with a rewrite. For a block marked with a
builder, the compiler takes the value of each line and passes them all to a static function of the
builder called `buildBlock`. An `if` without an `else` becomes a call to `buildOptional`, an `if` with
one to `buildEither`, and a `for` loop to `buildArray`. A builder that does not define one of those
does not support that statement, and the compiler says so. Section 06 writes a builder, and makes that
refusal happen.
