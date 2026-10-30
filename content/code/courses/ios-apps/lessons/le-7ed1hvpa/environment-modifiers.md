---
title: Modifiers that reach down the tree: the environment
version: 1
---

**Some modifiers do not wrap one view's layout at all. They set a value that every view inside them
reads.** `.font(.caption)` on a `VStack` makes every text in that stack a caption, unless a text sets
its own. Apple's documentation for `font(_:)` describes it in those words: font information flows down
the view hierarchy as part of the environment, and remains in effect unless overridden at the level of
an individual view or container.

```swift
VStack(alignment: .leading) {
    Text("Week of 19 October")
        .font(.headline)       // overrides the stack's font for this text only
    Text("120 of 180 minutes done")
    Text("3 sessions left")
}
.font(.subheadline)
.foregroundStyle(.secondary)
```

The heading is a headline; the other two inherit the subheadline font and the secondary colour from
the stack. **The environment is how SwiftUI avoids a hundred parameters**: the font, the colour
scheme, the locale, the size category the person chose for text, the `scenePhase` lesson 2 read, all
travel down the tree without being passed by hand.

## The environment is a set of values with a key each

Apple's documentation for `EnvironmentValues` describes the mechanism: a collection of values
propagated through the hierarchy, each read with `@Environment` and a key path, some set by the
system from the device and the person's settings, others with a default SwiftUI provides. A modifier
like `.font(_:)` is a convenience for setting one of them, and `.environment(\.lineLimit, 2)` is the
general form.

| set by | examples |
|---|---|
| the system | `colorScheme`, `locale`, `dynamicTypeSize`, `scenePhase` |
| your modifiers | `font`, `lineLimit`, `isEnabled` through `.disabled(_:)` |
| your own keys, lesson 7 | the planner's model, put in the environment once |

**This changes how order behaves.** For a wrapping modifier, section 03 said order is everything. For
an environment modifier, what matters is which views are inside it: `.font` on the stack reaches every
text in the stack, wherever in the chain it is written, and a `.font` closer to a text wins over one
farther out.

Lesson 7 uses the same channel for data: the planner's model goes into the environment at the top of
the tree and any screen reads it. Lesson 19 reads the size the person chose for text from it.

Nothing in this section was run for the course; it is written from Apple's documentation for
`font(_:)`, `EnvironmentValues` and `environment(_:_:)`, read on 30 October 2026.
