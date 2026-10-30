---
title: Observers: willSet and didSet
version: 1
---

Sometimes a stored property should stay stored and still have code run when it changes: to keep a
value in range, to log a change, to tell a screen to redraw. **A property observer is code attached
to a stored property that runs around every assignment.** `willSet` runs just before the new value
is stored, and `didSet` just after:

```swift
// Observers.swift
struct StudySession {
    var minutes: Int {
        willSet { print("will change from \(minutes) to \(newValue)") }
        didSet {
            if minutes > 600 { minutes = 600 }
            print("changed from \(oldValue) to \(minutes)")
        }
    }
}
var session = StudySession(minutes: 45)
session.minutes = 60
session.minutes = 900
print(session.minutes)
```

```
ana@vm:~/sw/l06$ swift Observers.swift
will change from 45 to 60
changed from 45 to 60
will change from 60 to 900
changed from 60 to 600
600
```

Three things are worth reading off the output.

**Making the session printed nothing.** The initialiser set `minutes` to 45, and neither observer
ran: observers run on assignments to an instance that already exists, never during its
initialisation. A value that must be checked from the first moment needs the check in the
initialiser as well, which section 07 shows.

**`willSet` sees `newValue`, `didSet` sees `oldValue`.** Each gets the value it cannot otherwise
see, by those names, and the property itself holds the other one.

**`didSet` may assign to the property again**, and that assignment does not trigger the observers a
second time. The 900 was stored, `didSet` replaced it with 600, and the line it printed already shows
the clamped value. That is how an observer keeps a property inside a range, a pattern lesson 16
turns into a reusable wrapper.

## What an observer is for in an app

On an iPhone, a screen has to redraw when the data under it changes, and the oldest way to arrange
that is an observer on the property that calls the screen. SwiftUI does it for you, with property
wrappers built on the same idea, and lesson 16 looks at them from the outside. **An observer is not
a computed property**: the value is still stored, and the observer only adds code around changes to
it. A property cannot be both computed and observed, since a computed property's own setter is
already the place for that code.
