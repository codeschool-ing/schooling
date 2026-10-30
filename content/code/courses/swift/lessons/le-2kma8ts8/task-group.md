---
title: Task groups, for a number of tasks known later
version: 1
---

The planner does not know how many courses a student has until it reads the list. **A task group
starts one child task per item, however many there are**, and hands back the results as each one
finishes. Here each course takes a different time to load, so the order of the answers is visible:

```schooling-example
{"language": "swift", "file": "Group.swift", "parts": [{"code": "func loadMinutes(for course: String) async -> Int {\n    try? await Task.sleep(for: .milliseconds(course.count * 50))\n    return course.count * 10\n}", "note": "The stand-in for the network again, with a delay that grows with the name: 150 milliseconds for `SQL`, 500 for `Statistics`. Different delays make the order of the answers something you can see."}, {"code": "let courses = [\"Swift\", \"Kotlin\", \"Statistics\", \"SQL\"]\n\nlet total = await withTaskGroup(of: (String, Int).self) { group in", "note": "`withTaskGroup` opens a group and runs the closure with it. `of:` says what each child task returns, here a course and its minutes together, so that each answer says which course it belongs to."}, {"code": "    for course in courses {\n        group.addTask {\n            (course, await loadMinutes(for: course))\n        }\n    }", "note": "**One child task per course**, started by `addTask`. The loop does not wait for any of them: it starts four tasks and finishes."}, {"code": "    var sum = 0\n    for await (course, minutes) in group {\n        print(\"\\(course): \\(minutes)\")\n        sum += minutes\n    }\n    return sum\n}", "note": "`for await` takes the results **in the order the tasks finish**, waiting whenever none is ready. What the closure returns becomes the value of `withTaskGroup`."}, {"code": "print(\"week: \\(total) minutes\")"}]}
```

```
ana@vm:~/sw/l14$ swift Group.swift
SQL: 30
Swift: 50
Kotlin: 60
Statistics: 100
week: 240 minutes
```

**The results came back in the order they finished, not the order they started.** SQL, the shortest
name and so the shortest delay, was first at 150 milliseconds; Swift came at 250, Kotlin at 300 and
Statistics last at 500, although Statistics was started third. A task group is a queue of answers, and
`for await` takes them as they arrive. The total does not depend on the order, so it is the same 240
however the four loads interleave, and the whole group took as long as its slowest child.

That is the first thing to remember about a group: **code that collects results by position is wrong
here.** If the planner needs to know which minutes belong to which course, each child must return the
course with its minutes, as these do with a tuple, and the caller puts them where they belong.

## The same guarantees as async let

Every task in the group is a child task. `withTaskGroup` does not return until all of them have
finished, so a group that is left early, with results still unread, waits for the rest before it
returns, and a group cannot leak work the way `Forgotten.swift` did. If the closure throws, or the task
running it is cancelled, the group cancels every child that is still running. Lesson 18 uses a group to
test several requests at once.

There is a throwing variant, `withThrowingTaskGroup`, whose children may throw. Its `for try await`
rethrows the first error, and by then the group has already cancelled the other children: one load
failing stops the rest, rather than leaving them to finish for nothing.

## Choosing between them

| you have | use |
|---|---|
| one piece of work, and you need its result before going on | `await` |
| a fixed handful of independent pieces | `async let` |
| as many pieces as a list has items | a task group |
| work started from code that is not `async`, such as a button | `Task { … }` |

The first three create no new unstructured task, and the compiler keeps track of them for you. The
fourth is the bridge from section 04, and the one you have to keep track of yourself.
