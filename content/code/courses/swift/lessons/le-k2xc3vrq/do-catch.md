---
title: do and catch
version: 1
---

Catching an error means deciding what the program does instead. **A `do` block runs code that may
throw, and the `catch` clauses after it say what to do with each kind of failure.** The planner reads
four lengths a student typed, and each failure gets a sentence of its own:

```schooling-example
{"language": "swift", "file": "DoCatch.swift", "parts": [{"code": "// DoCatch.swift\nenum PlannerError: Error {\n    case notANumber(String)\n    case tooLong(minutes: Int)\n}\n\nfunc parseMinutes(_ text: String) throws -> Int {\n    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }\n    guard minutes <= 240 else { throw PlannerError.tooLong(minutes: minutes) }\n    return minutes\n}\n", "note": "The same error enum and the same function as section 01. Nothing in the function says who will handle what it throws."}, {"code": "for typed in [\"45\", \"forty\", \"300\", \"900\"] {\n    do {\n        let minutes = try parseMinutes(typed)\n        print(\"\\(typed): \\(minutes) minutes added\")", "note": "`do` opens a block where errors are caught. Inside it, `try` still marks the call that can fail; if it throws, the rest of the block is skipped and Swift looks at the `catch` clauses below, in order."}, {"code": "    } catch PlannerError.notANumber(let text) {\n        print(\"\\(typed): \\\"\\(text)\\\" is not a number of minutes\")", "note": "A `catch` clause is a pattern, like a `case` in lesson 7. This one matches only `notANumber`, and `let text` takes the value the case carried."}, {"code": "    } catch PlannerError.tooLong(let minutes) where minutes >= 600 {\n        print(\"\\(typed): \\(minutes) minutes looks like a typo\")\n    } catch PlannerError.tooLong(let minutes) {\n        print(\"\\(typed): \\(minutes) minutes is longer than one study block\")", "note": "Two clauses for the same case, told apart by `where`. Order matters: the first clause whose pattern matches wins, so the narrower one, 600 minutes or more, comes first."}, {"code": "    } catch {\n        print(\"\\(typed): unexpected \\(error)\")\n    }\n}", "note": "A bare `catch` catches anything left, and gives it the name `error` without being asked. Here it never runs, because the clauses above cover both cases, and section 02 says why it is still required."}]}
```

```
ana@vm:~/sw/l12$ swift DoCatch.swift
45: 45 minutes added
forty: "forty" is not a number of minutes
300: 300 minutes is longer than one study block
900: 900 minutes looks like a typo
```

Four inputs and four different lines, and **the loop went on after each failure**: a `catch` handles
the error, and the program continues after the `do` block as if nothing had been thrown. `300` and
`900` are the same case, `tooLong`, sent to different clauses by the `where`.

## Why the last catch is required

`parseMinutes` is declared `throws`, with no type after it, which means it may throw **any** error,
of any type that conforms to `Error`. The compiler knows the two cases of `PlannerError`, and it
does not know that `parseMinutes` throws nothing else. So inside a function that does not throw
itself, a `do` must catch everything:

```swift
// NotExhaustive.swift
enum PlannerError: Error {
    case notANumber(String)
    case tooLong(minutes: Int)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

func add(_ typed: String) {
    do {
        print(try parseMinutes(typed))
    } catch PlannerError.notANumber(let text) {
        print("not a number: \(text)")
    } catch PlannerError.tooLong(let minutes) {
        print("too long: \(minutes)")
    }
}
```

```
ana@vm:~/sw/l12$ swiftc NotExhaustive.swift -o notexhaustive
NotExhaustive.swift:14:15: error: errors thrown from here are not handled because the enclosing catch is not exhaustive
12 | func add(_ typed: String) {
13 |     do {
14 |         print(try parseMinutes(typed))
   |               `- error: errors thrown from here are not handled because the enclosing catch is not exhaustive
15 |     } catch PlannerError.notANumber(let text) {
16 |         print("not a number: \(text)")
```

`errors thrown from here are not handled because the enclosing catch is not exhaustive`: both
`PlannerError` cases are covered, and the compiler still cannot prove that nothing else arrives. The
fix is a final bare `catch`, as `DoCatch.swift` has, or marking `add` as `throws` so that anything
left goes up to its caller. Section 04 shows the third fix, a function that declares exactly which
type it throws.

## What to put in a catch

A catch that prints and carries on is right for a loop over input, as here. **A catch that does
nothing at all, `catch { }`, is almost never right**: it turns a failure into silence, and the
student whose session was not saved is not told. If there is truly nothing to do, write in the
`catch` why, and let the reader judge.
