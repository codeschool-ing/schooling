---
title: The modifiers that only look alike
version: 1
---

**Several pairs of modifiers produce the same picture in the simple case and different layouts in
the next one.** Each pair is a pair of different wrappers, and section 02's rule tells them apart:
ask what each one is, and what size it reports.

| looks like | is | the difference that bites |
|---|---|---|
| `.overlay { … }` and a `ZStack` | a wrapper the size of the view it modifies, against a container the size of its largest child | a badge in an overlay never makes the icon bigger; in a `ZStack` a large badge does |
| `.hidden()` and `if !visible { … }` | a view that is there and invisible, against no view at all | Apple's documentation for `hidden()` says a hidden view stays in the hierarchy and affects layout, so the space is kept |
| `.opacity(0)` and `.hidden()` | both keep the space; opacity can be animated, and `hidden()` cannot be reversed by a value | `hidden()` hides unconditionally; to show and hide, use opacity or an `if` |
| `.foregroundStyle(.red)` and `.tint(.red)` | the colour of content, against the accent colour of controls | a `Button`'s label follows the tint; text follows the foreground style |
| `.cornerRadius(12)` and `.clipShape(.rect(cornerRadius: 12))` | an older modifier, against the current one | Apple's documentation marks `cornerRadius(_:antialiased:)` deprecated from iOS 27.2, with the message "Use `clipShape` or `fill` instead" |

**The `overlay` row is the one the planner uses.** The course row will carry a small dot when a
session is overdue, and it must not move the title by a point when it appears:

```swift
Image(systemName: "book")
    .overlay(alignment: .topTrailing) {
        Circle()
            .fill(.red)
            .frame(width: 8, height: 8)
    }
```

Apple's documentation for `overlay(alignment:content:)` describes it as layering views in front of
this one, grouped in an implicit `ZStack` positioned by the alignment. The overlay takes the size of
the image it modifies, so the dot sits on the corner and the row's layout is untouched whether the dot
is there or not.

## Why the deprecated one still matters

You will read `.cornerRadius(…)` in older code for years, because it worked from the first SwiftUI.
Deprecated means the compiler warns and the modifier still works; Apple's message names what to use,
and `clipShape` takes any shape, which `cornerRadius` never could.

Nothing in this section was run for the course. The table and the listing are written from Apple's
documentation for each modifier named, read on 30 October 2026.
