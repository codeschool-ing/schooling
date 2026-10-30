---
title: Errors that are part of a function's type
version: 1
---

Lesson 2 used an optional for a value that may be missing: `Int("forty")` is `nil`, and that is all
it says. **When the caller needs to know why something failed, a `nil` is not enough**, and Swift's
answer is an error: a value that describes the failure, thrown by the function that found it and
caught by whoever can deal with it.

An error is any type that conforms to the protocol `Error`, and an enum is the usual choice, because
each case names one way to fail and can carry what the caller needs to know (lesson 7). A function
that can fail says so with **`throws`** between its parameters and its return type, and fails with
**`throw`**:

```swift
// Throws.swift
enum PlannerError: Error {
    case notANumber(String)
    case tooLong(minutes: Int)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else {
        throw PlannerError.notANumber(text)
    }
    guard minutes <= 240 else {
        throw PlannerError.tooLong(minutes: minutes)
    }
    return minutes
}

let minutes = parseMinutes("45")
print(minutes)
```

```
ana@vm:~/sw/l12$ swiftc Throws.swift -o throws
Throws.swift:17:15: error: call can throw but is not marked with 'try'
15 | }
16 | 
17 | let minutes = parseMinutes("45")
   |               |- error: call can throw but is not marked with 'try'
   |               |- note: did you mean to use 'try'?
   |               |- note: did you mean to handle error as optional value?
   |               `- note: did you mean to disable error propagation?
18 | print(minutes)
19 | 
```

**The compiler refuses the call, not the function.** `parseMinutes` is fine. What is refused is
calling it as though it could not fail: a function marked `throws` can only be called with `try` in
front, and the three notes are the three ways to write it, which sections 03 and 04 cover. The rule
puts every place an error can come from on the page, where a reader sees it, rather than only in the
function's declaration three files away.

## What `try` does with the error

`try` on its own does not handle anything. **It passes the error on**: if the call throws, the
function containing the `try` stops there and throws the same error to its own caller. That is only
allowed inside a function that is itself marked `throws`, or at the top level of a program, where
there is no caller left:

```swift
// Uncaught.swift
enum PlannerError: Error {
    case notANumber(String)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

print(try parseMinutes("45"))
print(try parseMinutes("forty"))
print("never printed")
```

```
ana@vm:~/sw/l12$ swiftc Uncaught.swift -o uncaught
ana@vm:~/sw/l12$ SWIFT_BACKTRACE=enable=no ./uncaught
45
Swift/ErrorType.swift:254: Fatal error: Error raised at top level: uncaught.PlannerError.notANumber("forty")
Current stack trace:
0    libswiftCore.so                    0x00007fc381f62cd0 swift_reportError + 33
1    libswiftCore.so                    0x00007fc382319190 _swift_stdlib_reportFatalErrorInFile + 109
2    libswiftCore.so                    0x00007fc381f734e1 <unavailable> + 1520865
3    libswiftCore.so                    0x00007fc382109e90 _assertionFailure(_:_:file:line:flags:) + 299
4    libswiftCore.so                    0x00007fc382169600 swift_errorInMain + 766
5    uncaught                           0x0000563e71a7ecb3 <unavailable> + 7347
6    libc.so.6                          0x00007fc381a2a1ca <unavailable> + 172490
7    libc.so.6                          0x00007fc381a2a200 __libc_start_main + 139
8    uncaught                           0x0000563e71a7e155 <unavailable> + 4437
```

The first call printed 45. The second threw, nothing caught it, and the error reached the top of the
program, where Swift stops the process with **`Error raised at top level`** and the error itself:
`uncaught.PlannerError.notANumber("forty")`, the module, the type, the case and the value it carried.
`never printed` was not printed. `SWIFT_BACKTRACE=enable=no` keeps the crash report to the short stack
trace, as in lesson 11.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" data-fig=\"l12-propagation\" aria-label=\"A diagram of calls stacked from bottom to top. At the bottom, parseMinutes throws PlannerError.notANumber. Above it, a function marked throws that calls it with try passes the error up. Path 1, on the left, ends in a do block with catch, where the error is handled. Path 2, on the right, reaches the top level with no catch, and the program stops with a fatal error.\"><defs><marker id=\"l12-propagation-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-propagation-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l12-propagation-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"200\" y=\"196\" width=\"320\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">parseMinutes(\"forty\")</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">throws PlannerError.notANumber</text><rect x=\"200\" y=\"112\" width=\"320\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">func total(…) throws</text><text x=\"360\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">marked try, inside a throwing function: passes it up</text><path d=\"M360 194 L360 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-propagation-ah-amber)\"></path><rect x=\"30\" y=\"24\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">path 1</text><text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">do { try … } catch: handled here</text><rect x=\"390\" y=\"24\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\"></rect><text x=\"540\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">path 2</text><text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">nobody catches it: fatal error at top level</text><path d=\"M330 110 L210 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-propagation-ah-phosphor)\"></path><path d=\"M390 110 L510 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l12-propagation-ah-amber)\"></path></svg>", "caption": "An error travels up the calls, from the throw to the first do/catch that handles it, through every function marked throws. If it reaches the top of the program first, the program stops."}
```

**A thrown error is not a crash.** It is an ordinary value travelling up the calls, and it only ends
the program when nothing on its way catches it. Section 02 is about catching it.
