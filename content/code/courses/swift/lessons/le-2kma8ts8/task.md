---
title: Task, where asynchronous work starts
version: 1
---

Section 03 ended on a question: `report()` is not `async`, and it needs the answer of something that
is. **A `Task` is the bridge.** `Task { … }` starts the closure as a separate piece of asynchronous
work and returns at once, handing back a value that represents the work:

```swift
// Tasks.swift
func loadMinutes(for course: String) async -> [Int] {
    try? await Task.sleep(for: .milliseconds(200))
    return [45, 30, 60]
}

func startLoading() -> Task<Int, Never> {
    Task {
        let minutes = await loadMinutes(for: "Swift")
        print("the task finished")
        return minutes.reduce(0, +)
    }
}

let task = startLoading()
print("startLoading returned")
let total = await task.value
print("total: \(total)")
```

```
ana@vm:~/sw/l14$ swift Tasks.swift
startLoading returned
the task finished
total: 135
```

`startLoading` is an ordinary function, with no `async` in its signature, and it started
asynchronous work anyway. It returned before the task had done anything, so "startLoading returned"
came first. **`Task<Int, Never>` is the task's type**: it produces an `Int`, and `Never` says it
cannot fail. `await task.value` waits for the task and gives its result, so the top level waited 200
milliseconds there and printed the total last.

An app starts most of its asynchronous work this way, from code that is not asynchronous: the
handler for a tap on a button is an ordinary function, and the request it sends lives in a `Task`.
`ios-apps` writes those handlers; the mechanism is this one.

## A task nobody waits for

The task keeps running after `startLoading` returns, and nothing about it waits for the program. A
task that is started and never awaited is exactly as long-lived as the process that holds it:

```swift
// Forgotten.swift
Task {
    try? await Task.sleep(for: .milliseconds(200))
    print("saved")
}
print("done")
```

```
ana@vm:~/sw/l14$ swift Forgotten.swift
done
```

**"saved" never appeared.** The top level printed "done", reached its end, and the process exited
with the task still asleep. Nothing reported it, because from Swift's point of view nothing went
wrong. In an app, which runs until the user closes it, the same task would finish; in a script, a
command-line tool or a test, it is a line of work that silently did not happen. Keep the `Task` value
and `await` it when the work matters, or `await` the work directly.

## Unstructured, and why the word matters

A task made with `Task { … }` is **unstructured**: it is not tied to the function that created it. The
function returns, and the task goes on by itself, which is what the bridge needs and also what made
"saved" disappear. Swift's other kind of task is a **child task**, created inside an `async` function
and guaranteed to finish before that function returns. Sections 05 and 06 make child tasks, and that
guarantee is what lets the compiler cancel and wait for them on your behalf.

There is also `Task.detached { … }`, which starts a task that inherits nothing from the code that
created it. You will rarely need it, and lesson 15 shows the one thing a plain `Task` inherits that
makes the difference: the actor it was started on.
