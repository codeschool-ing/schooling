---
title: Generic types
version: 1
---

Functions are not the only thing with a placeholder. `Array<Element>`, `Dictionary<Key, Value>` and
`Optional<Wrapped>` are generic types from the standard library, and `[Int]` is only a shorter way
of writing `Array<Int>`. **A generic type is a struct, class or enum with type parameters**, and each
use of it picks the types. An undo list for the planner is a stack, and a stack has nothing to do
with what it holds:

```schooling-example
{"language": "swift", "file": "Stack.swift", "parts": [{"code": "// Stack.swift\nstruct Stack<Element> {\n    private var items: [Element] = []", "note": "`Element` is the type parameter of the whole struct. Every `Stack` has one, chosen when the stack is created, and the array inside holds that type."}, {"code": "    mutating func push(_ item: Element) { items.append(item) }\n    mutating func pop() -> Element? { items.popLast() }\n    var top: Element? { items.last }\n    var isEmpty: Bool { items.isEmpty }\n}", "note": "The methods use `Element` like any type. `pop()` and `top` return an optional, because an empty stack has nothing to give."}, {"code": "extension Stack where Element: Numeric {\n    var sum: Element { items.reduce(0, +) }\n}", "note": "An extension that exists only when the elements are numbers: `sum` is a member of `Stack<Int>` and not of `Stack<String>`."}, {"code": "var undo = Stack<String>()\nundo.push(\"added Optionals, 45 min\")\nundo.push(\"marked Closures done\")\nprint(undo.pop() ?? \"-\")\nprint(undo.top ?? \"-\")", "note": "A stack of strings, written `Stack<String>`: an undo list where the last action is the first to come back."}, {"code": "var minutes = Stack<Int>()\nminutes.push(45)\nminutes.push(30)\nprint(minutes.sum, minutes.isEmpty)", "note": "The same struct holding integers. Here `sum` exists, and the compiler worked out `Element` from the explicit `<Int>`."}], "output": "marked Closures done\nadded Optionals, 45 min\n75 false"}
```

`swift Stack.swift` runs it. The undo list gave back the last action first, and its top is then the
one before. The stack of minutes added to 75, and it is not empty.

## Each use is a different type

`Stack<String>` and `Stack<Int>` are two types, as `[String]` and `[Int]` are. A function that takes
a `Stack<Int>` will not accept a `Stack<String>`, and an assignment from one to the other is refused.
The compiler produces code for each use it needs, which is why generic code in Swift costs nothing
at run time when the types are known: the stack of integers is as fast as one written for `Int`
alone.

## A constraint on the type, or on an extension

The struct itself puts no condition on `Element`, so anything can be stacked. The condition sits on
the **extension**: `where Element: Numeric` adds `sum` only to stacks of numbers. Putting the
constraint on the struct instead, `struct Stack<Element: Numeric>`, would forbid a stack of strings
altogether. **Constrain as late as possible**: on the member that needs it rather than on the whole
type.
