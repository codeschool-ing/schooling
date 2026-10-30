---
title: guard let, and the early exit
version: 1
---

`if let` puts the good case inside braces. When a function cannot do anything useful without the
value, that nests the whole function one level deeper, and a second check nests it again. **`guard
let` turns it round: it handles the bad case first, leaves, and the unwrapped name stays for the
rest of the function.**

```swift
// GuardLet.swift
func minutes(from typed: String) -> Int {
    guard let value = Int(typed) else {
        print("not a number: \(typed)")
        return 0
    }
    guard value > 0 else {
        print("not positive: \(value)")
        return 0
    }
    return value
}
print(minutes(from: "45"))
print(minutes(from: "forty"))
print(minutes(from: "-5"))
```

```
ana@vm:~/sw/l02$ swift GuardLet.swift
45
not a number: forty
0
not positive: -5
0
```

Read the function from the top and the shape is a list of conditions, each with its way out, and then
the work. `value` was unwrapped by the first `guard` and is used by the second and by `return value`,
**outside any braces of its own**. That is the difference from `if let`, where the name ends at the
closing brace.

## The else has to leave

A `guard` exists to stop the code below it from running with a bad value, so the compiler checks that
its `else` really leaves. Forget the `return` and it refuses:

```swift
// FallThrough.swift
func minutes(from typed: String) -> Int {
    guard let value = Int(typed) else {
        print("not a number: \(typed)")
    }
    return value
}
print(minutes(from: "45"))
```

```
ana@vm:~/sw/l02$ swiftc FallThrough.swift -o fallthrough
FallThrough.swift:5:5: error: 'guard' body must not fall through, consider using a 'return' or 'throw' to exit the scope
3 |     guard let value = Int(typed) else {
4 |         print("not a number: \(typed)")
5 |     }
  |     `- error: 'guard' body must not fall through, consider using a 'return' or 'throw' to exit the scope
6 |     return value
7 | }
```

`return` is one way out of a function, and the message names `throw` as the other, which lesson 12
explains. Inside a loop, `continue` and `break` also count. **What does not count is printing a
message and carrying on**, because then `value` would be used below with no value in it, which is
the bug `guard` exists to prevent.

## Which to reach for

| when | write |
|---|---|
| the value is needed for a few lines and then not | `if let` |
| the function cannot continue without it | `guard let … else { return }` |
| both cases do real work | `if let … else` |

The three shapes compile to the same check. The choice is about what the reader sees first: with
`guard`, the ways the function can give up are at the top, one per line, and the rest of the function
is the case that matters.
