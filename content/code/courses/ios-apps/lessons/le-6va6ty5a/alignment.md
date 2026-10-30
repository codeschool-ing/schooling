---
title: Alignment: which edges, and which baselines, line up
version: 1
---

**A stack's `alignment` lines its children up along the axis it does not stack on.** A `VStack`
aligns horizontally (`.leading`, `.center`, `.trailing`) and an `HStack` vertically (`.top`,
`.center`, `.bottom`, and two that matter for text, `.firstTextBaseline` and `.lastTextBaseline`).
The default is `.center` for both.

The planner's course row from section 03 shows why the baselines exist. On its left, a title in the
headline font over a caption; on its right, the minutes in the body font. Centred, the minutes sit
halfway between the two left lines, matching neither. **Aligned on the first text baseline, the
minutes sit on the same line as the title**, which is what a reader's eye expects:

```swift
HStack(alignment: .firstTextBaseline) {
    VStack(alignment: .leading) {
        Text(course.title).font(.headline)
        Text("this week").font(.caption)
    }
    Spacer()
    Text("\(minutes) min")
}
```

A baseline is the line letters sit on, so aligning baselines aligns text of different sizes the way
print does. Aligning `.top` would line up the tops of the two boxes instead, and a larger font has
more space above its letters, so the words would not quite share a line.

## Alignment inside a frame and inside a ZStack

`frame(width:height:alignment:)` and `ZStack(alignment:)` take an `Alignment`, which names both axes
at once: `.topLeading`, `.bottomTrailing`, `.center` and so on. In a frame it says where a smaller
child sits; in a `ZStack` it says how the layers line up, so a badge in `ZStack(alignment:
.topTrailing)` sits on the top-right corner of the icon under it.

## Lining up across containers

Sometimes two views in different stacks have to share a line, such as the colons in a column of
labels. SwiftUI's answer is a custom alignment guide, a type that conforms to `AlignmentID`, applied
with `.alignmentGuide(_:computeValue:)`. It is mentioned so that you recognise it; the planner never
needs one, and nothing here builds one.

Nothing in this section was run for the course. It is written from Apple's documentation for
`HStack`, `VerticalAlignment`, `Alignment` and `alignmentGuide(_:computeValue:)`, read on 30 October
2026.
