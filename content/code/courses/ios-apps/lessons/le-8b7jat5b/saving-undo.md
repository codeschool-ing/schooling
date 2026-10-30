---
title: Saving, autosave and undo
version: 1
---

**In SwiftData a change is made in a context and stored by a save, and in a SwiftUI app the save is
usually not yours to call.** Apple's documentation for `ModelContext.autosaveEnabled` says that when it
is on, the context calls `save()` after changes to the records it knows, and also "at various times
during the lifecycle of windows, scenes, views, and sheets". The property is `false` by default, and
SwiftData sets it to `true` for the container's `mainContext`, which is the context section 03's
modifier puts in the environment. Nothing in this section was run; it follows that documentation, read
on 30 October 2026.

## When to call `save()` anyway

Autosave runs at moments SwiftData chooses. Two moments in the planner are worth not leaving to it:

- **before something leaves the app.** Lesson 14 sends new sessions to the server; it should send what
  is stored, so it saves first and reads afterwards.
- **after work outside the main context.** A context you create yourself, for an import running off the
  main actor, does not autosave unless told to, and its changes reach the store only when it saves.

```swift
// Saving before a sync
do {
    if context.hasChanges { try context.save() }
} catch {
    syncError = error      // shown on the screen: lesson 12's error state
}
```

Apple's documentation for `save()` suggests checking `hasChanges` first, "otherwise, SwiftData may
perform unnecessary work". And `save()` throws: a full disk or a broken constraint is an error the
screen has to show. **A `try?` here would be a save that fails without a word**, and the student would
find out next week that the sessions they added were never stored.

## Undo

Undo is not on by default. Apple's documentation for `ModelContext.undoManager` says its default value
is `nil`, and that assigning an `UndoManager` enables undo for the context. The SwiftUI modifier takes
the short route:

```swift
// PlannerApp.swift, with undo
WindowGroup {
    CourseListView()
}
.modelContainer(for: [CourseRecord.self, SessionRecord.self], isUndoEnabled: true)
```

The documentation for that parameter says to use the `undoManager` in the scene's environment to manage
undo. A screen reads it with `@Environment(\.undoManager)` and offers an Undo button after a delete.

**Undo is the gentler answer to a mistaken swipe.** A confirmation dialog before every delete trains
people to tap "Delete" without reading it; an Undo after the delete costs a tap only for the person who
needs it. For the planner, deleting a session gets Undo, and deleting a course, which cascades to every
session under it, gets both a confirmation and Undo.

The documentation adds a cost: undo records every change, so for an import of many records at once it
suggests setting `undoManager` to `nil` for the duration.
