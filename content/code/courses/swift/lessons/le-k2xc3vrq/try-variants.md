---
title: try? and try!
version: 1
---

Section 01's compiler offered three spellings. Plain `try` passes the error on. The other two **turn
the error into something else on the spot**: `try?` into an optional, and `try!` into a crash.

```swift
// TryVariants.swift
enum PlannerError: Error {
    case notANumber(String)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

let typed = ["45", "forty", "30", "", "60"]
let maybe = try? parseMinutes("forty")
print(maybe as Any)
let valid = typed.compactMap { try? parseMinutes($0) }
print(valid, valid.reduce(0, +))
let sure = try! parseMinutes("90")
print(sure)
let wrong = try! parseMinutes(typed[1])
print(wrong)
```

```
ana@vm:~/sw/l12$ swiftc TryVariants.swift -o tryvariants
ana@vm:~/sw/l12$ SWIFT_BACKTRACE=enable=no ./tryvariants
nil
[45, 30, 60] 135
90
tryvariants/TryVariants.swift:18: Fatal error: 'try!' expression unexpectedly raised an error: tryvariants.PlannerError.notANumber("forty")
Current stack trace:
0    libswiftCore.so                    0x00007fad0d162cd0 swift_reportError + 33
1    libswiftCore.so                    0x00007fad0d519190 _swift_stdlib_reportFatalErrorInFile + 109
2    libswiftCore.so                    0x00007fad0d1734e1 <unavailable> + 1520865
3    libswiftCore.so                    0x00007fad0d309e90 _assertionFailure(_:_:file:line:flags:) + 299
4    libswiftCore.so                    0x00007fad0d3692b0 swift_unexpectedError + 803
5    tryvariants                        0x000055e14ca67647 <unavailable> + 9799
6    libc.so.6                          0x00007fad0cc2a1ca <unavailable> + 172490
7    libc.so.6                          0x00007fad0cc2a200 __libc_start_main + 139
8    tryvariants                        0x000055e14ca66405 <unavailable> + 5125
```

## try? keeps the success and drops the reason

`try? parseMinutes("forty")` gives an `Int?`: the number when the call succeeds, `nil` when it throws,
and the error itself is discarded. `print(maybe as Any)` prints `nil` without the warning lesson 1
met, because `as Any` says the optional is meant.

**It fits where the reason does not matter.** `compactMap` (lesson 4) keeps the values that are not
`nil`, so `typed.compactMap { try? parseMinutes($0) }` reads a list of typed lengths and keeps the
ones that are numbers: 45, 30 and 60, 135 minutes, with `"forty"` and the empty string left out. That
is right for a quick total. It is wrong for a form, where the student needs to be told which field was
not a number, and only the error knows.

## try! is a promise, and it crashes when broken

`try!` says the call cannot fail here, and **if it does, the program stops**. `try! parseMinutes("90")`
gave 90. `try! parseMinutes(typed[1])` read `"forty"`, and the process ended with `'try!' expression
unexpectedly raised an error`, naming the file, line 18, and the error. It is lesson 2's force unwrap
again, for errors, and it deserves the same suspicion: honest for a value written in the program
itself, as `"90"` is, and a crash waiting for the day the value comes from somewhere else.

| | when the call throws | the result | use it when |
|---|---|---|---|
| `try` | the error goes to the caller, or to a `catch` | the value | somebody can act on the reason |
| `try?` | the error is dropped | an optional | only success or failure matters |
| `try!` | the program stops | the value | failure would be a bug in this program |
