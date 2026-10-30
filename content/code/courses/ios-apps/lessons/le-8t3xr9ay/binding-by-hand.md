---
title: A binding, built by hand
version: 1
---

**A `Binding` is two closures and nothing else, and the clearest way to believe that is to write
one.** SwiftUI is not on Linux, but closures, key paths and dynamic member lookup are plain Swift, so
this section builds a type with the same shape as `Binding`, called `Ref` so the two cannot be
confused, and runs it. It is a model of the idea and not SwiftUI's source; Apple's documentation for
`Binding` describes the real type, which also carries a transaction for animations.

Make a directory, `~/bindings`, and save this as `binding.swift` in it:

```schooling-example
{"language": "swift", "file": "binding.swift", "parts": [{"code": "// binding.swift: what a Binding is, built by hand\n@dynamicMemberLookup\nstruct Ref<Value> {\n    let read: () -> Value\n    let write: (Value) -> Void\n\n    var value: Value {\n        get { read() }\n        nonmutating set { write(newValue) }\n    }\n", "note": "The whole idea in five lines: two closures, one that reads and one that writes. `nonmutating set` means setting `value` does not change the `Ref` itself, only whatever the closures reach. SwiftUI's `Binding` is the same shape with more around it."}, {"code": "    subscript<Part>(dynamicMember path: WritableKeyPath<Value, Part>) -> Ref<Part> {\n        Ref<Part>(read: { self.value[keyPath: path] },\n                  write: { self.value[keyPath: path] = $0 })\n    }\n}\n", "note": "Narrowing. Given a `Ref` to a whole value and a key path into it, make a `Ref` to the part. `@dynamicMemberLookup` lets you write `ref.done` or `ref[1]` and have Swift call this, which is exactly how `$session.done` works."}, {"code": "final class Storage<Value> {\n    var value: Value\n    init(_ value: Value) { self.value = value }\n}\n", "note": "A stand-in for where `@State` keeps a value: a box that lives outside the view structs, so a new copy of a view finds the same box."}, {"code": "struct Session {\n    var title: String\n    var done: Bool\n}\n\nstruct DoneToggle {\n    let isOn: Ref<Bool>\n    func tap() { isOn.value.toggle() }\n}\n", "note": "A child that only knows how to flip a `Bool`. Like a `Toggle`, it is given the means to change the value and not the value."}, {"code": "let storage = Storage([\n    Session(title: \"SQL, joins\", done: false),\n    Session(title: \"Mobile, lifecycle\", done: false),\n])\n\nvar copy = storage.value[0].done\ncopy.toggle()\nprint(\"a copy:      copy is \\(copy), storage is \\(storage.value.map(\\.done))\")\n", "note": "First, hand over a copy. Flipping it changes the copy and nothing else, which is what passing a plain value to a child does."}, {"code": "let first = Ref(read: { storage.value[0].done }, write: { storage.value[0].done = $0 })\nDoneToggle(isOn: first).tap()\nprint(\"a binding:   storage is \\(storage.value.map(\\.done))\")\n", "note": "Then a binding made from scratch, the way `Binding(get:set:)` makes one. The tap reaches the storage."}, {"code": "let sessions = Ref(read: { storage.value }, write: { storage.value = $0 })\nDoneToggle(isOn: sessions[1].done).tap()\nprint(\"narrowed:    storage is \\(storage.value.map(\\.done))\")\n", "note": "Last, a binding to the whole list, narrowed twice: to element 1, then to its `done`. That line is `$plan.sessions[1].done` with the dollar sign spelled out."}]}
```

Run it as a single file, the way lesson 1 section 08 ran `check.swift`:

```
ana@vm:~/bindings$ swift binding.swift
a copy:      copy is true, storage is [false, false]
a binding:   storage is [true, false]
narrowed:    storage is [true, true]
```

**Three lines, three ways of handing a child something to change.** The copy changed and the storage
did not: `[false, false]`. The binding made from two closures reached the storage and set the first
session: `[true, false]`. The narrowed one reached the second: `[true, true]`. Nothing in `DoneToggle`
changed between the three; only what it was given.

That is all `@Binding` adds to a view: a property whose type is a binding, and the `$` syntax to make
one. `@State`'s part is the `Storage` box, kept by SwiftUI outside the struct, plus the call to run
`body` again after a write, which this model leaves out.
