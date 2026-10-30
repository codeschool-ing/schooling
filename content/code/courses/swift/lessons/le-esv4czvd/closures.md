---
title: Closures, functions without a name
version: 1
---

A function in Swift is a value, like an `Int` or a `String`. It has a type, it can be stored in a
constant, passed to another function and returned from one. **A closure is a function written in place,
with no name**, and it is how most Swift code passes behaviour around.

## A function is a value

```swift
// FunctionValues.swift
func seconds(_ minutes: Int) -> Int {
    minutes * 60
}
let convert = seconds
print(convert(45))
print(type(of: convert))
func applyAll(_ f: (Int) -> Int, to values: [Int]) -> [Int] {
    var out: [Int] = []
    for value in values {
        out.append(f(value))
    }
    return out
}
print(applyAll(seconds, to: [45, 30]))
```

```
ana@vm:~/sw/l03$ swift FunctionValues.swift
2700
(Int) -> Int
[2700, 1800]
```

`let convert = seconds` stores the function itself, without calling it: no brackets after `seconds`.
Its type is `(Int) -> Int`, read as "takes an `Int`, gives an `Int`", and that is also the type of the
parameter `f` of `applyAll`. So `applyAll` can apply any function of that shape to every value in a
list, without knowing which one.

## The same function, with no name

Passing `seconds` meant declaring it first, somewhere else. A closure writes it where it is used, and
Swift lets you write it at four levels of shortness:

```schooling-example
{"language": "swift", "file": "Shorthand.swift", "parts": [{"code": "// Shorthand.swift\nlet full: (Int) -> Int = { (minutes: Int) -> Int in\n    return minutes * 60\n}", "note": "The whole form: the parameter and its type, the result type, the word `in`, then the body. This is a function with no name, and its type is written on the left: it takes an `Int` and gives an `Int`."}, {"code": "let inferred: (Int) -> Int = { minutes in\n    return minutes * 60\n}", "note": "The type on the left already says `(Int) -> Int`, so the closure need not repeat it. Only the parameter's name remains before `in`."}, {"code": "let implicit: (Int) -> Int = { minutes in minutes * 60 }", "note": "A single-expression body needs no `return`, as for a function."}, {"code": "let short: (Int) -> Int = { $0 * 60 }", "note": "No name at all: `$0` is the first parameter, `$1` the second. It suits a closure of one short line, and becomes hard to read in a longer one."}, {"code": "print(full(45), inferred(45), implicit(45), short(45))\nprint(type(of: short))", "note": "Four spellings, one function, and one type."}]}
```

```
ana@vm:~/sw/l03$ swift Shorthand.swift
2700 2700 2700 2700
(Int) -> Int
```

**Every form is the same function**: the four calls print the same number and the type is the same.
What changes is how much the reader is told and how much they work out. Two rules cover most code: use
`$0` for a closure that fits comfortably on one line, and give the parameters names as soon as there is
more than one line or more than one parameter.

The types can be left out because Swift **infers them from the context**: here, the `(Int) -> Int`
written on the left. When a closure is passed straight to a function, as in section 06, the function's
parameter type is the context, and nothing on the left is needed at all.
