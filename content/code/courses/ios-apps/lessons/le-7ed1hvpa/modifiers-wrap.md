---
title: A modifier returns a new view that wraps the old one
version: 1
---

**A modifier does not change the view it is called on. It returns a new view with the old one
inside.** Apple's documentation for `View` puts it plainly: modifiers work by wrapping the view
instance on which you call them in another view with the specified characteristics. So
`Text("50 min").padding()` is not a text with padding set on it; it is a padding view whose content
is a text.

That sounds like a detail and it is the key to everything else in this lesson, because each wrapper
is a **participant in layout** in its own right. Lesson 4 section 04 met one already: a frame is a new
view around the old one, with its own size. Padding is another, a background another, and the chain

```swift
Text("50 min")
    .padding()
    .background(.yellow)
    .frame(maxWidth: .infinity, alignment: .trailing)
```

is four views, nested like boxes: a frame, holding a background, holding a padding, holding a text.
**Read a chain from the top down to know what is inside what**: the first modifier is the innermost
wrapper and the last is the outermost.

## Why SwiftUI is built this way

Because a view is a value, as lesson 3 section 02 said, there is nothing to set a property on. A
modifier has to produce a new value, and the cheapest new value that changes one thing is a small
struct holding the old view and the one thing. The type of the result records the whole chain, which
is how SwiftUI compares the next description with this one, the same way lesson 3 section 07 showed
for an `if`.

**Two consequences follow, and they are the next two sections.** The order of the chain changes the
result, because each wrapper sees only what is inside it (section 03). And two modifiers that look
alike can be different wrappers that lay out differently (section 04).

Nothing in this section was run for the course. Section 08 builds the same wrappers in plain Swift,
prints their types, and runs.
