---
title: The force unwrap, and the crash it promises
version: 1
---

The fourth answer is not an answer to the `nil` case at all. **`!` after an optional says: there is
a value in here, and if I am wrong, stop the program.** It gives you the plain value and gives the
crash back.

```swift
// Bang.swift
let good = Int("45")!
print(good + 1)
let bad = Int("forty")!
print(bad + 1)
```

```
ana@vm:~/sw/l02$ swiftc Bang.swift -o bang
ana@vm:~/sw/l02$ ./bang 2>&1 | head -5
bang/Bang.swift:4: Fatal error: Unexpectedly found nil while unwrapping an Optional value

*** Signal 4: Backtracing from 0x7f53791731ef... done ***

*** Program crashed: Illegal instruction at 0x00007f53791731ef ***
ana@vm:~/sw/l02$ script -qc ./bang /dev/null | tr -d '\r' | head -2
46
bang/Bang.swift:4: Fatal error: Unexpectedly found nil while unwrapping an Optional value
```

The unwrap on line 4 found `nil`, and the program stopped with a **fatal error** before its last
`print`. The first line is the one to read: where, `bang/Bang.swift:4`, which is the module, the file
and the line, and why, `Unexpectedly found nil while unwrapping an Optional value`. `head -5` keeps
that line and the start of the crash report; the full report runs on for some fifty more.

**One line is missing from that output, and that is a lesson of its own.** `print(good + 1)` ran,
and `46` never appeared. When its output goes into a pipe rather than straight to a terminal, a
program collects what it prints in a buffer and writes it out in large pieces, and a crash ends the
process before the buffer is written. The last command runs `./bang` through `script`, which makes it
believe it is printing to a terminal, and `tr` removes the carriage returns a terminal adds: now `46`
is there, above the error. **Output missing before a crash is not proof that the line did not run.**

This is the same kind of stop as lesson 1's overflow, and for the same reason. A program that carried
on would have a `bad` with no number in it, and every line after would be guessing.

## When ! is honest

`!` is not forbidden. It is a claim, and some claims are true by construction:

- a value the program itself just built, `URL(string: "https://swift.org")!`, where the text is fixed
  and correct;
- a test, where a crash with a line number is exactly the failure you want (lesson 18);
- a short program you will throw away.

**What it is never right for is input**: anything a student typed, a file read, a server's answer.
Those are where `nil` is normal, and a crash there is a crash in front of somebody. The same goes for
a `!` added because the compiler complained: section 02's second error offered `!` as a way to make
the message go away, and that is the worst reason to write one.

## The implicitly unwrapped optional

You will meet one more spelling in older Apple code: a type written `String!` rather than `String?`.
It is an optional that unwraps itself every time it is used, with a crash if it is `nil` at that
moment. It exists for values that are set just after an object is created and before anybody reads
them, which is how UIKit connects a screen's controls to code. `ios-apps` meets it in that role. In
your own types, write `?` and unwrap it on purpose.
