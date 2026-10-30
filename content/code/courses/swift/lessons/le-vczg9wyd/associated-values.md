---
title: Associated values
version: 1
---

A study activity is reading, a video or a set of exercises, and each kind carries different data:
pages for reading, minutes for a video, how many exercises were done out of how many. A struct with
three optional fields would allow nonsense, a video with pages, and would make every reader check
which fields are set. **An associated value is data attached to one case**, and only that case
carries it:

```swift
// Associated.swift
enum Activity {
    case reading(pages: Int)
    case video(minutes: Int)
    case exercises(done: Int, of: Int)
}
let plan: [Activity] = [
    .reading(pages: 12),
    .video(minutes: 20),
    .exercises(done: 7, of: 10),
]
for activity in plan {
    print(activity)
}
func minutes(for activity: Activity) -> Int {
    switch activity {
    case .reading(let pages):
        return pages * 3
    case .video(let minutes):
        return minutes
    case .exercises(let done, _):
        return done * 4
    }
}
print(plan.map(minutes(for:)).reduce(0, +))
```

```
ana@vm:~/sw/l07$ swift Associated.swift
reading(pages: 12)
video(minutes: 20)
exercises(done: 7, of: 10)
84
```

**Each case is a different shape, and the type is all three.** The array holds one of each, and
`print` shows each case with its labelled data. The only way to read the data out is to ask which
case it is, and the `switch` in `minutes(for:)` does that: `case .reading(let pages)` matches a
reading and binds its page count to a new constant, `pages`, for the body of that case. `_` skips a
value the code does not need, the total number of exercises here. The estimate, three minutes a page
and four an exercise, gives 36 + 20 + 28 = 84.

`plan.map(minutes(for:))` passes the function itself to `map`, the way lesson 3 passed functions as
values.

## Raw or associated, not both

A raw value is the same for every instance of a case, fixed when the enum is written: `.friday` is
always `"friday"`. An associated value is chosen each time a value is made: one video lasts 20
minutes, another 45. **An enum may have one kind or the other, never both**, because a case with
data attached cannot also be a single constant string.

This is the shape lesson 2 called the truth about optionals, and section 06 comes back to it: an
`Int?` is an enum with two cases, one of which carries an `Int`.
