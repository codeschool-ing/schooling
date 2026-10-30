---
title: AsyncImage, the one-line picture
version: 1
---

**SwiftUI can show a picture from a URL in one line, and that line hides three decisions.** `AsyncImage`
takes a URL, downloads it, decodes it and draws it, with a placeholder while it waits. For a single
picture on one screen that is the whole job. For a list of fifty course covers it makes three choices
for you: how big the decoded picture is in memory, whether the bytes are kept for next time, and what
happens to a download whose row has scrolled away. This lesson is about making those choices on
purpose.

The SwiftUI in this lesson was written from Apple's documentation for `AsyncImage` and
`AsyncImagePhase`, read on 30 October 2026, and **none of it was run**. The decisions underneath it
are plain Swift and arithmetic, and sections 04 and 06 run them.

## The short form

The planner's course list shows a cover beside each course. The shortest version:

```swift
// CourseRow.swift
import SwiftUI
import PlannerCore

struct CourseRow: View {
    let course: Course
    let cover: URL

    var body: some View {
        HStack {
            AsyncImage(url: cover) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 80, height: 80)
            .clipped()
            Text(course.title)
        }
    }
}
```

**The modifiers go on the image inside the closure, not on `AsyncImage`.** Apple's documentation says
so plainly: `resizable` is a modifier of `Image`, and `AsyncImage` is not an `Image`, so the closure
hands you one to modify. Without `resizable`, the picture is drawn at its own pixel size and the frame
crops whatever part of it falls inside.

## What it does with the bytes

Apple's documentation says `AsyncImage` downloads with the shared `URLSession`. On iOS 27 and later it
also caches the downloaded data the way HTTP says it may, through a cache the system creates, and a
view hierarchy can hand it a session of its own with the `asyncImageURLSession` modifier. **On the iOS
17 this course targets, neither is promised**: a cover that scrolls off and back may be downloaded
again. Section 06 builds a cache the app controls, which behaves the same on every version.

What it never does is shrink the picture. `AsyncImage` decodes the image at the size the file has,
and section 04 shows what that costs.
