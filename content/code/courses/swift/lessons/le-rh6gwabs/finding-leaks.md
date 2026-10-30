---
title: Finding a cycle you did not see being written
version: 1
---

Section 03's leak printed nothing. A cycle is the absence of a line, and absences are hard to notice
by reading output. **So the tools for leaks all work the same way: they look at what is still in
memory, and ask what holds it.** On a Mac those tools are in Xcode; on Linux, the compiler carries one
of its own.

## On a Mac: the memory graph and Instruments

This part was not run for this course, because Xcode exists only for macOS. It is described from
Apple's documentation for Xcode.

- **The memory graph debugger.** While an app runs from Xcode, the button labelled *Debug Memory
  Graph* pauses it and lists every object alive at that moment, grouped by class. Selecting one draws
  the references that hold it, and a cycle is drawn as a loop. Objects Xcode can prove are leaked are
  marked with a purple warning sign.
- **Instruments, with the Leaks template.** Instruments records the app while you use it, and the
  Leaks instrument checks memory at intervals and lists the allocations nothing reachable points to,
  with a picture of the cycle and the code that allocated each object.

`ios-apps` uses both on a real app. What they show is the same thing this lesson shows with
`deinit`: which objects are alive that should not be.

## On Linux: the address sanitizer's leak check

The compiler can build a program with **AddressSanitizer**, a set of checks it inserts into the
machine code. On Linux it includes **LeakSanitizer**, which runs when the program exits and reports
every block of memory that nothing reachable points to. A cycle is exactly that: two objects reachable
only from each other. Section 03's program, unchanged, built with `-sanitize=address`:

```
ana@vm:~/sw/l11$ swiftc -sanitize=address Cycle.swift -o cycle-asan 2>&1 | grep -c "warning: Cannot export"
141
ana@vm:~/sw/l11$ ./cycle-asan 2>&1 | swift demangle --simplified | grep -E "leak of|SUMMARY|__allocating_init"
Indirect leak of 40 byte(s) in 1 object(s) allocated from:
    #3 0x56408b09cddb in Course.__allocating_init(name:) crtstuff.c
Indirect leak of 40 byte(s) in 1 object(s) allocated from:
Indirect leak of 32 byte(s) in 1 object(s) allocated from:
    #3 0x56408b09d327 in StudySession.__allocating_init(minutes:) crtstuff.c
SUMMARY: AddressSanitizer: 112 byte(s) leaked in 3 allocation(s).
```

The build prints 141 lines of warnings from the linker about symbols it cannot export, and `grep -c`
counts them rather than showing them; they are about the sanitizer's own code and the program is built
correctly. The run then ends with a report. Its names come out **mangled**, the compiler's encoding of
a Swift name into a symbol, so `swift demangle --simplified` turns them back into Swift, and `grep`
keeps the lines worth reading:

- **three leaked allocations, 112 bytes.** One is a `Course`, one is a `StudySession`, and the third
  is the storage of the `sessions` array that `append` created;
- **where each was made**, in `plan()`, through `Course.__allocating_init(name:)` and
  `StudySession.__allocating_init(minutes:)`, the code `Course(name:)` and `StudySession(minutes:)`
  compile into;
- **"Indirect" on every one**, which is LeakSanitizer's word for memory held only by other leaked
  memory: the signature of a cycle.

The same check on section 04's program, where the back reference is `weak`:

```
ana@vm:~/sw/l11$ swiftc -sanitize=address Weak.swift -o weak-asan 2>/dev/null
ana@vm:~/sw/l11$ ./weak-asan 2>&1 | grep -c "leak of"
0
```

No leak report, so `grep -c` counts zero lines of one. **A sanitized build is slower and larger**, so it is a
build for looking, not for shipping.

One thing the sanitizer does that you must know before trusting its output: the program's own
`print` lines did not appear in the first run. LeakSanitizer ends the process its own way after the
report, and anything still in the output buffer is lost, which is why these runs were filtered for the
report alone.

## The habit that finds most of them

Neither tool replaces the cheapest one: **a `deinit` that prints, in every class you suspect.** Run the
flow that should end an object's life, leaving a screen in an app, returning from `plan()` here, and
look for the line. A missing `deinit` line is a cycle until proved otherwise, and the place to look is
every stored property and every stored closure of that class.
