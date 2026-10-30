---
title: Waiting without stopping
version: 1
---

An app asks a server for a student's courses, and the answer takes 200 milliseconds to arrive. **The
wrong picture is a program that stands still for those 200 milliseconds.** On a phone that program
is a screen that does not scroll, does not answer a tap and, after a few seconds of it, gets killed
by the system. The right picture is a program that asks, goes on doing other work, and comes back to
the answer when it arrives.

For most of Swift's life, "comes back to it" meant a **completion handler**: you passed the function
a closure, and the function called it later, from wherever the answer turned up. Lesson 3 showed
closures that are kept after the call returns, marked `@escaping`; a completion handler is exactly
that. Here is the planner loading a course and then its sessions, written that way:

```swift
// Callbacks.swift
import Dispatch

func loadCourse(named name: String, completion: @escaping (String) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) {
        completion(name)
    }
}

func loadMinutes(for course: String, completion: @escaping ([Int]) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) {
        completion([45, 30, 60])
    }
}

let finished = DispatchSemaphore(value: 0)
print("asking for the course")
loadCourse(named: "Swift") { course in
    print("got \(course), asking for its sessions")
    loadMinutes(for: course) { minutes in
        print("\(course): \(minutes.reduce(0, +)) minutes")
        finished.signal()
    }
}
print("the request is on its way")
finished.wait()
```

```
ana@vm:~/sw/l14$ swift Callbacks.swift
asking for the course
the request is on its way
got Swift, asking for its sessions
Swift: 135 minutes
```

`DispatchQueue.global().asyncAfter` stands in for the network: it runs its closure on another thread
200 milliseconds from now. **Read the output against the source, and the order is the first
surprise.** "the request is on its way" is the last line of the program and the second line printed,
because `loadCourse` returned at once and only promised to call back. The two lines inside the
closures came afterwards, each 200 milliseconds after the one before. The semaphore at the end keeps
the program from finishing before they do: `wait()` blocks until `signal()` is called, and without
it the program would print two lines and exit.

## What completion handlers cost

The code works, and three things about it get worse as the program grows:

- **The order on the page is not the order in time.** Each step that waits pushes the next step one
  closure deeper, and a sequence of five requests becomes five levels of indentation.
- **Nothing makes you call the closure.** A function with an early `return` on an error path that
  forgets `completion(…)` compiles, and the caller waits for ever.
- **Errors have nowhere to go.** A closure cannot throw back to a caller that has already returned,
  so every handler grows a second parameter for the error, or a `Result`, which lesson 12 met.

Swift 5.5 added a way to write the same program as a sequence of ordinary lines, where the compiler,
not you, keeps track of what happens when the answer arrives. Section 03 is that program. Completion
handlers have not gone away: older libraries still offer them, and lesson 15 meets `Dispatch` again.
