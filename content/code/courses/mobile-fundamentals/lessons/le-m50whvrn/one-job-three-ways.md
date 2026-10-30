---
title: The planner's daily sync, written three ways
version: 1
---

**The planner has one piece of work that does not need the student to be looking: sending the
sessions marked done today to the server, and bringing back any change made on another device.**
Nobody waits for it, a few hours late costs nothing, and it is cheapest on Wi-Fi with the phone on
its charger. That is exactly the job the systems in the previous section are built for. It should
be one batched job a day with constraints, not a timer.

Below is that job in each platform's own words. The three fragments are adapted from Android's
guide to defining work with WorkManager, Apple's article on using background tasks to update an app,
and the documentation of Expo's `expo-background-task`, and **they were not compiled or run for this
course**. `syncWeek` stands for the app's own code that does the sending; it is the same in all
three and is not shown.

## Android, with WorkManager

```kotlin
class SyncWeekWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        if (syncWeek()) Result.success() else Result.retry()
}

val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.UNMETERED)
    .setRequiresCharging(true)
    .build()
val daily = PeriodicWorkRequestBuilder<SyncWeekWorker>(1, TimeUnit.DAYS)
    .setConstraints(constraints)
    .build()
WorkManager.getInstance(context)
    .enqueueUniquePeriodicWork("sync-week", ExistingPeriodicWorkPolicy.KEEP, daily)
```

**The constraints say when it is cheap, and the interval says how often at most.** If the phone
spends a day off its charger, the run is late, or skipped, and the documentation says so. `retry()`
hands a failed attempt back to WorkManager, which tries again later with a backoff of its own,
the same idea lesson 14 wrote by hand. `enqueueUniquePeriodicWork` with a name means that calling
it at every launch keeps one job rather than piling up a new one each time.

## iOS, with BGTaskScheduler

```swift
// Registered while the app launches, for an identifier listed in Info.plist
BGTaskScheduler.shared.register(forTaskWithIdentifier: "app.planner.sync", using: nil) { task in
    scheduleSync() // ask for the next one first
    let work = Task { task.setTaskCompleted(success: await syncWeek()) }
    task.expirationHandler = { work.cancel() }
}

func scheduleSync() {
    let request = BGProcessingTaskRequest(identifier: "app.planner.sync")
    request.requiresExternalPower = true
    request.requiresNetworkConnectivity = true
    request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
    try? BGTaskScheduler.shared.submit(request)
}
```

**iOS has no periodic request: each run asks for the next one.** The handler schedules the next
sync before it starts this one, so a run that is cut short still leaves one waiting. The
`expirationHandler` is the system saying the time it granted is over; the task must stop, and
`setTaskCompleted` tells the system how it went. `earliestBeginDate` is a day away, which is the
earliest the system may run it, not the time it will.

## React Native, with expo-background-task

```tsx
import * as BackgroundTask from "expo-background-task";
import * as TaskManager from "expo-task-manager";

// Defined at the top level of the app, not inside a component
TaskManager.defineTask("sync-week", async () => {
  const ok = await syncWeek();
  return ok
    ? BackgroundTask.BackgroundTaskResult.Success
    : BackgroundTask.BackgroundTaskResult.Failed;
});

await BackgroundTask.registerTaskAsync("sync-week", { minimumInterval: 24 * 60 }); // minutes
```

**The JavaScript is short because the native half is the library's.** On Android it becomes a
WorkManager job, on iOS a `BGTaskScheduler` task, and the rules of each apply unchanged. Expo's
documentation of `minimumInterval`, as read on 30 October 2026, says the value is in minutes, with a
default of 12 hours and a minimum of 15 minutes. On iOS, it adds, short intervals are often ignored,
and tasks tend to run in windows such as overnight.

## What the three have in common

| | Android | iOS | React Native |
|---|---|---|---|
| the work | a `Worker` | a launch handler | a task defined with `TaskManager` |
| the cheap moment | `setRequiresCharging`, `NetworkType.UNMETERED` | `requiresExternalPower`, `requiresNetworkConnectivity` | battery and network, decided by the library |
| how often | at most once per interval | once, then the handler asks again | at most once per `minimumInterval` |
| when exactly | when the constraints and the system allow | when the system chooses | either of those |

**None of the three can say "at 08:00".** That is the lesson of the whole section: background work
on a phone is a request, and the system grants it when it suits the battery. Something that has to
reach the student at a particular moment, like a reminder that a session starts in fifteen minutes,
is a notification, and lesson 17 is about those. The `mobile-offline` course builds the full sync on
top of these jobs in its lesson 16; the `android-apps` course teaches WorkManager in its lesson 18
and `ios-apps` background tasks in its lesson 16, whichever route you take.
