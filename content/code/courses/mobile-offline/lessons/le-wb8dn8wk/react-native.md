---
title: "React Native: expo-background-task, and the rules underneath"
version: 1
---

**A React Native app runs in the background under exactly the rules of the platform it is on;
the library only spares you the native code.** Expo's `expo-background-task`, in Expo SDK 53 and
later, schedules a task through WorkManager on Android and through `BGTaskScheduler` on iOS, so
everything in the two previous sections still holds: fifteen minutes at the least, no guarantee
of when, about thirty seconds on iOS, nothing after a force stop.

*The listing in this section was not run for this course: a background task needs an Android or
iOS device, or an emulator, and neither was available. It follows the `expo-background-task`
documentation on docs.expo.dev.*

```tsx
import * as BackgroundTask from "expo-background-task";
import * as TaskManager from "expo-task-manager";

const SYNC = "planner-sync";

// At the top level of a module, never inside a component.
TaskManager.defineTask(SYNC, async () => {
  try {
    await sync();
    return BackgroundTask.BackgroundTaskResult.Success;
  } catch {
    return BackgroundTask.BackgroundTaskResult.Failed;
  }
});

export async function scheduleSync() {
  await BackgroundTask.registerTaskAsync(SYNC, { minimumInterval: 15 }); // in minutes
}
```

**Why the top level matters.** When the system decides to run the task, it may start the app with
no screen at all: no component is mounted, no navigation exists, and the JavaScript runs from the
first module onwards. A task defined inside a component would not exist yet, and the run would do
nothing. The same goes for whatever `sync` uses: the database must be opened by the task itself,
not by a screen that was never drawn.

**Ask whether it is allowed.** `BackgroundTask.getStatusAsync()` answers whether background tasks
are available or restricted, for instance because the person turned off Background App Refresh on
iOS. A planner that finds them restricted loses nothing important if its sync also runs on launch
and on save, as the first section said it must.

One point is particular to how the task is started. When the app is open, the task runs in the
same JavaScript environment as its screens, so a background sync and one a screen started can run
at the same time and drain the same outbox twice. When the app is closed, the task is a fresh
launch that knows nothing of the last one. **So guard the outbox in its rows, not in memory**: the
rows record what is in flight, which is how lesson 8 marks them, and the idempotency keys of lesson
10 absorb the rare duplicate that gets through.
