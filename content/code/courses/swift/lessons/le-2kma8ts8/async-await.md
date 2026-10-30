---
title: async and await
version: 1
---

**`async` marks a function that can pause, and `await` marks each place where it might.** The two
words are all of the syntax. Here is the program of section 02 again, with the same two delays and
the same output, and no closure in it:

```swift
// Planner.swift
func loadCourse(named name: String) async -> String {
    try? await Task.sleep(for: .milliseconds(200))
    return name
}

func loadMinutes(for course: String) async -> [Int] {
    try? await Task.sleep(for: .milliseconds(200))
    return [45, 30, 60]
}

print("asking for the course")
let course = await loadCourse(named: "Swift")
print("got \(course), asking for its sessions")
let minutes = await loadMinutes(for: course)
print("\(course): \(minutes.reduce(0, +)) minutes")
```

```
ana@vm:~/sw/l14$ swift Planner.swift
asking for the course
got Swift, asking for its sessions
Swift: 135 minutes
```

The order on the page is the order in time. `let course = await loadCourse(named: "Swift")` reads like
an ordinary call that returns a `String`, and it is one, with a difference you cannot see in the
output: **while it waits, the thread it was running on is free** to run other work. When the answer
arrives, the function carries on from the line after the `await`, perhaps on a different thread. The
semaphore has gone too, because the top level of a script may use `await` directly and the program
waits for each line before the next.

`Task.sleep(for:)` is the asynchronous way to wait, and it stands in for the network here. Section 07
explains why it can throw and what the `try?` in front of it throws away.

## await is required, and so is a place to await from

The compiler holds both ends of the rule. A call to an `async` function without `await` is refused,
and so is an `await` inside a function that is not itself `async`:

```swift
// Report.swift
func loadCourse(named name: String) async -> String {
    name
}

func report() {
    let course = await loadCourse(named: "Swift")
    print(course)
}

report()
```

```
ana@vm:~/sw/l14$ swiftc Report.swift -o report
Report.swift:7:24: error: 'async' call in a function that does not support concurrency
 4 | }
 5 | 
 6 | func report() {
   |      `- note: add 'async' to function 'report()' to make it asynchronous
 7 |     let course = await loadCourse(named: "Swift")
   |                        `- error: 'async' call in a function that does not support concurrency
 8 |     print(course)
 9 | }
```

**The error is about `report`, not about the call.** A function that is not `async` runs from start to
end without pausing, so it has no way to wait for anything, and the compiler says so: an `async` call
in a function that does not support concurrency. Its note offers the first way out, marking `report`
`async`, which moves the question to `report`'s caller. Somewhere at the top of every chain there has
to be a place that starts asynchronous work from code that is not asynchronous. In a script that place
is the top level; in an app it is a **task**, section 04's subject.

## What `await` promises, and what it does not

`await` is a **suspension point**: a place where the function may pause and other code may run before
it continues. It is not a promise that anything runs in parallel. In `Planner.swift` the two loads ran
one after the other, 200 milliseconds each, because the second needs the first's answer. Sections 05
and 06 run independent work at the same time, and the timings show the difference.
