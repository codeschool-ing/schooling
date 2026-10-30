---
title: VStack, LazyVStack and List
version: 1
---

**A `VStack` builds every one of its children as soon as it appears; a `LazyVStack` and a `List`
build a row only when it is about to scroll into view.** For eight rows the difference is nothing.
For eight thousand, a `VStack` inside a `ScrollView` builds eight thousand rows before the screen
shows the first one, and keeps all of them. Nothing in this section was run; the behaviour is the one
Apple's article *Creating performant scrollable stacks* describes.

```swift
ScrollView {
    LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(model.plan.sessions) { session in
            SessionCard(session: session)
        }
    }
    .padding()
}
```

**The three are not interchangeable, and the choice is about more than speed:**

| | builds rows | gives you | use it for |
|---|---|---|---|
| `VStack` | all of them, at once | exact layout, nothing else | a handful of rows that always fit |
| `LazyVStack` in a `ScrollView` | as they approach the screen | your own row design, no separators or edit mode | a long feed of custom cards |
| `List` | as they approach the screen | swipe actions, sections, selection, edit mode, the platform's look | most lists in an app, the planner's included |

**Lazy has a cost a `VStack` does not**: the stack does not know the height of rows it has not built,
so its scroll indicator is an estimate, and jumping to the end means building the rows on the way.

**Apple's own advice is to start with the plain stack.** The same article says lazy stacks *trade
some degree of layout correctness for performance*, and to switch only when profiling shows a
worthwhile improvement: Xcode's *Product* menu, *Profile*, and the SwiftUI template in Instruments,
whose View Body instrument counts the views loaded. It also says never to profile on the simulator,
only on a real device. None of that was run for this course.
