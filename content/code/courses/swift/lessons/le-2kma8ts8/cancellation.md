---
title: Cancellation is a request
version: 1
---

A student opens a course, and the planner starts loading its sessions. Before they arrive the student
goes back, and the answer is no longer wanted. **Cancelling a task does not stop it.** It sets a flag
on the task that the task's own code is expected to read, and Swift's own functions read it:

```swift
// Cancel.swift
func loadMinutes(for course: String) async throws -> [Int] {
    try await Task.sleep(for: .milliseconds(500))
    return [45, 30, 60]
}

let task = Task {
    do {
        let minutes = try await loadMinutes(for: "Swift")
        print("loaded \(minutes)")
    } catch {
        print("stopped: \(error)")
    }
}

try? await Task.sleep(for: .milliseconds(100))
task.cancel()
await task.value
```

```
ana@vm:~/sw/l14$ swift Cancel.swift
stopped: CancellationError()
```

`task.cancel()` was called 100 milliseconds in, while `loadMinutes` was asleep. **`Task.sleep` checks
the flag, and when it is set it stops sleeping and throws `CancellationError`.** That is why
`Task.sleep` is a throwing function, and why `loadMinutes` is now `async throws`: the error travels up
like any other error from lesson 12, to the `catch`. "loaded" never printed.

## The `try?` that swallowed it

Every earlier section of this lesson wrote `try? await Task.sleep(…)`, and that was harmless while
nothing cancelled anything. Once something does, `try?` turns the cancellation into `nil` and the
function carries on. Here is a loop that adds up five courses, one sleep each, written both ways:

```swift
// Cooperate.swift
let courses = ["Swift", "Kotlin", "SQL", "Statistics", "Git"]

func totalCarelessly() async -> Int {
    var total = 0
    for course in courses {
        try? await Task.sleep(for: .milliseconds(100))
        print("  added \(course)")
        total += course.count * 10
    }
    return total
}

func totalCarefully() async throws -> Int {
    var total = 0
    for course in courses {
        try await Task.sleep(for: .milliseconds(100))
        print("  added \(course)")
        total += course.count * 10
    }
    return total
}

print("carelessly:")
let careless = Task { await totalCarelessly() }
try? await Task.sleep(for: .milliseconds(250))
careless.cancel()
print("result:", await careless.value)

print("carefully:")
let careful = Task { try await totalCarefully() }
try? await Task.sleep(for: .milliseconds(250))
careful.cancel()
print("result:", await careful.result)
```

```
ana@vm:~/sw/l14$ swift Cooperate.swift
carelessly:
  added Swift
  added Kotlin
  added SQL
  added Statistics
  added Git
result: 270
carefully:
  added Swift
  added Kotlin
result: failure(Swift.CancellationError())
```

**The careless version finished the job anyway, and faster.** Two courses were added in the 250
milliseconds before the cancel. After it, every `Task.sleep` threw at once, `try?` discarded each
error, and the loop raced through the last three and returned the full 270 as though nothing had
happened. The careful version let the error propagate: it stopped after the same two courses, and its
`result`, a `Result` from lesson 12, carries the `CancellationError`.

## Cooperative, so it is your code's job

Cancellation in Swift is **cooperative**: a task stops where its code looks at the flag, and nowhere
else. Swift's own suspending functions look, and your own loops are yours to make look. Two ways:

- `try Task.checkCancellation()` throws `CancellationError` if the task has been cancelled, which suits
  a function that already throws;
- `Task.isCancelled` is a `Bool`, for code that would rather stop early and return what it has.

A loop that computes for a long time without awaiting anything never sees the flag at all, so put one
of the two at the top of each pass.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-tree\" aria-label=\"A tree of tasks. The task you cancel has three child tasks, two async lets and a task group with two tasks of its own, and amber arrows carry the cancellation down to all of them. To one side, a task started with Task inside it is drawn dashed: it is unstructured, not a child, and keeps running.\"><defs><marker id=\"l14-tree-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-tree-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the task you cancel</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">task.cancel()</text><path d=\"M360 60 L110 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"40\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">async let x</text><path d=\"M360 60 L270 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"200\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">async let y</text><path d=\"M360 60 L430 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"360\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">withTaskGroup</text><path d=\"M430 146 L380 196\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"330\" y=\"198\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">addTask</text><path d=\"M430 146 L500 196\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"450\" y=\"198\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">addTask</text><text x=\"240\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">child tasks: cancelled with their parent</text><path d=\"M470 40 L560 40 L560 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l14-tree-ah2)\"></path><rect x=\"560\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"630\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Task { … }</text><text x=\"630\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">unstructured:</text><text x=\"630\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">keeps running</text></svg>", "caption": "Cancellation follows the tree of child tasks, and stops at a task that was never a child."}
```

**Cancellation flows down the tree.** Cancelling a task cancels its child tasks, the `async let`s and
the members of its groups, and each of those stops wherever its own code checks. An unstructured
`Task { … }` started inside it is not a child, and is not cancelled with it: section 04's word,
unstructured, again.
