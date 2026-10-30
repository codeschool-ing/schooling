---
title: A list of pictures that scrolls
version: 1
---

**A list is where everything in this lesson happens at once and fast.** A person flicks through fifty
courses in a second; rows appear and disappear faster than covers download; and every row that
appears asks for a picture. Three rules keep that smooth, and each one is a section of this lesson
put to work. This section is SwiftUI, written from Apple's documentation for `List`, `task(id:)` and
`displayScale`, and **it was not run**.

## The row

The row loads its own cover, through the shared cache, downsampled to what it draws:

```swift
// CourseRow.swift
import SwiftUI
import PlannerCore

struct CourseRow: View {
    let course: Course
    let cover: URL
    let images: ImageCache
    @Environment(\.displayScale) private var scale
    @State private var picture: UIImage?

    var body: some View {
        HStack {
            Group {
                if let picture {
                    Image(uiImage: picture).resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                }
            }
            .frame(width: 80, height: 80)
            .clipped()
            .accessibilityHidden(true)
            Text(course.title)
        }
        .task(id: cover) {
            guard let data = try? await images.data(for: cover) else { return }
            picture = downsample(data, maxPixels: Int(80 * scale))
        }
    }
}
```

**The first rule is one cache for the whole list.** `images` is passed in, not created in the row, so
every row shares section 06's dictionary of downloads in flight, and fifty rows of three courses make
three downloads. A cache made inside each row would cache nothing.

**The second is decode small, off the main actor, before anything is drawn.** The `task` closure runs
the download and the downsampling as asynchronous work; only the small `UIImage` is assigned to the
state the view draws. In the app, the cache from section 06 would keep that small picture, so the next
time the row appears the work is not done at all.

**The third is that a row which leaves stops waiting.** `task(id:)` cancels its work when the row
disappears, as lesson 12 showed. The row stops waiting, and nothing it would have assigned arrives.
The download itself carries on, because it lives in the cache's own `Task` and another row may still
want it; a picture nobody wants is then kept, ready for the moment the person scrolls back.

The `try?` drops the error on purpose. A cover is decoration, and section 03 said its failure is
quiet: the grey square stays. The cover is hidden from VoiceOver for the same reason, since the
course's title beside it already says everything the picture does; lesson 19 is where that decision
is made for every picture in the planner.

## What `List` does with the rows

`List` is lazy: it builds rows as they come into view and discards them as they leave, which is why a
list of five thousand courses opens as fast as a list of five. **That laziness is why the work belongs
in the row's `task`** and not in an initializer: a row built and discarded during a fast scroll should
start nothing it will not finish. Lesson 8 is where `List`'s laziness, and the identity that lets it
reuse a row, are taught.

UIKit's collection views offer a prefetching hook, `prefetchDataSource`, that starts the downloads for
rows about to appear. The planner does not use one: the cache makes up much of the difference, since a
cover the person has seen once is in memory and a cover asked for by several rows is downloaded once.
