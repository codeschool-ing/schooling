---
title: The if trap: a modifier applied only sometimes
version: 1
---

**A helper that applies a modifier only when a condition holds is one of the commonest pieces of
SwiftUI code online, and it quietly costs the view its identity.** It looks like this:

```swift
extension View {
    @ViewBuilder
    func when<Modified: View>(_ condition: Bool, modify: (Self) -> Modified) -> some View {
        if condition {
            modify(self)
        } else {
            self
        }
    }
}

Text("50 min")
    .when(session.done) { $0.foregroundStyle(.green) }
```

It reads well and it compiles. **The `if` inside it is the `if` of lesson 3 section 07**: two branches,
two slots in the type, and flipping the condition removes the view in one slot and creates a new one
in the other. For a `Text` that is a small waste. For a view with state inside, a text field or a
scroll position, it is a reset: the field loses what was typed when the session is marked done.
Lesson 11 shows the other symptom, an animation that fades one view out and another in instead of
changing a colour.

## The same thing without SwiftUI

Plain Swift shows what the helper builds. `Words` stands for a view and `Highlighted` for a modifier's
wrapper; `when` is the helper, and `Highlight` is the alternative, one wrapper that is always there
and whose effect is a value. Save this as `iftrap.swift` in `~/l05`:

```schooling-example
{"language": "swift", "file": "iftrap.swift", "parts": [{"code": "// iftrap.swift: a modifier inside an if, and the identity it costs\nstruct Words { let text: String }\nstruct Highlighted<Content> { let content: Content }\nenum Either<First, Second> { case first(First), second(Second) }\n", "note": "A view, a modifier's wrapper, and the two-branch shape a builder makes of an `if`."}, {"code": "/// The helper people write: apply a modifier only when a condition holds.\nfunc when<V, T>(_ condition: Bool, _ view: V, _ modify: (V) -> T) -> Either<T, V> {\n    condition ? .first(modify(view)) : .second(view)\n}\n", "note": "The helper, without the builder's syntax: the modified view in the first branch, the plain one in the second. Its type has both, so it compiles; its value is one or the other."}, {"code": "/// The alternative: one wrapper, always there, whose effect is a value.\nstruct Highlight<Content> { let content: Content; let on: Bool }\n", "note": "The fix: the wrapper is always applied, and whether it does anything is a `Bool` inside it."}, {"code": "for done in [true, false] {\n    let branched = when(done, Words(text: \"50 min\")) { Highlighted(content: $0) }\n    let valued = Highlight(content: Words(text: \"50 min\"), on: done)\n    print(\"done: \\(done)\")\n    print(\"  if:    \\(branched)\")\n    print(\"  value: \\(valued)\")\n}\n", "note": "Both ways, for a session done and not done."}]}
```

```
ana@vm:~/l05$ swift iftrap.swift
done: true
  if:    first(iftrap.Highlighted<iftrap.Words>(content: iftrap.Words(text: "50 min")))
  value: Highlight<Words>(content: iftrap.Words(text: "50 min"), on: true)
done: false
  if:    second(iftrap.Words(text: "50 min"))
  value: Highlight<Words>(content: iftrap.Words(text: "50 min"), on: false)
```

**With the `if`, the text lives in `first` when done and in `second` when not**: two different places,
so to SwiftUI two different views. **With the value, the text is in the same place both times**, and
only `on` changed. That is the whole difference between a reset and an update.

## What to write instead

Most modifiers take a value that can mean "no effect", so the condition goes inside the value:

```swift
Text("50 min")
    .foregroundStyle(session.done ? .green : .primary)
    .opacity(session.done ? 0.6 : 1)
```

One view, always the same slot, with values that change. Use a conditional view only when the views
really are different things, a checkmark against a number, as lesson 3 section 07 did on purpose.
Nothing in this section ran SwiftUI; `iftrap.swift` ran on Linux.
