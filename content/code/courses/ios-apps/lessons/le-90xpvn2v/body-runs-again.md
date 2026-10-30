---
title: The body runs again, and that is the design
version: 1
---

**SwiftUI reads a view's `body` whenever something the body depends on may have changed, and it
expects to read it many times.** A body is not a constructor that runs once. It is closer to a
formula in a spreadsheet: given the current inputs, it says what the screen is now. When an input
changes, SwiftUI asks again.

Three kinds of input make SwiftUI ask:

| what changed | example in the planner | lesson |
|---|---|---|
| a value the parent passed in | `CourseListView` gives a row a different course | 2 and 8 |
| state the view owns | the minutes typed into `SessionForm` | 6 |
| a property of an observable model the body read | the plan's sessions, in `PlannerModel` | 7 |

**The third row is the one that surprises people, in a good way.** SwiftUI does not re-run every
body that has a model in it. It records which properties of the model a body read while it ran, and
only a change to one of those makes it ask that body again. A body that shows a course's title is not
asked again when a note on another screen changes. Section 05 rebuilds that recording in plain Swift,
with the same Observation framework SwiftUI uses, and counts the runs.

## What a body must not do

Because SwiftUI decides how often a body runs, the body cannot have opinions about it:

- **no side effects.** Starting a download, writing a file or adding to a list inside `body` repeats
  it every time the body runs, and the number of runs is not yours to know. Work that starts with a
  view goes in a modifier made for it, `.task`, which lesson 12 uses;
- **no expensive work.** Sorting a thousand sessions inside `body` happens on every run. Compute it
  where the data changes, or keep it in the model, as lesson 7 does;
- **no assumption about order.** A parent's body may run without its child's, and a child's without
  its parent's.

Nothing in this section was run for the course. The three inputs are the ones Apple's documentation
for `State`, `Binding` and `Observable` describes, read on 30 October 2026. How often SwiftUI reads a
body in a given app is something only a run on a Mac would show, and the course quotes no number for
it.
