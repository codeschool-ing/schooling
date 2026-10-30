---
title: "iOS: BGTaskScheduler, and the upload that outlives the app"
version: 1
---

**On iOS you register a task by name, ask for it to run no earlier than some time, and finish
before the system's deadline; the system picks the moment.** The framework is `BackgroundTasks`,
and it has the two kinds of task of the first section: `BGAppRefreshTask`, with about thirty
seconds, and `BGProcessingTask`, for longer work the system runs when the phone is idle.

*The listings in this section were not run for this course: Xcode and the iOS simulator run only
on a Mac, and the course was recorded on Linux. They follow Apple's documentation for
`BackgroundTasks` and `URLSession`.*

## Declare it

The task's name goes in the app's `Info.plist`, and the refresh mode in its background modes; the
system refuses to schedule a name it does not find there:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>org.example.planner.refresh</string>
</array>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
```

## Register, ask, finish

```swift
import BackgroundTasks

// In application(_:didFinishLaunchingWithOptions:), before it returns.
BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.example.planner.refresh", using: nil) { task in
    handleRefresh(task as! BGAppRefreshTask)
}

func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "org.example.planner.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("could not schedule the refresh: \(error)")
    }
}

func handleRefresh(_ task: BGAppRefreshTask) {
    scheduleRefresh()
    let sync = Task { await Planner.sync() }
    task.expirationHandler = { sync.cancel() }
    Task {
        await sync.value
        task.setTaskCompleted(success: !sync.isCancelled)
    }
}
```

Three things in `handleRefresh` are not optional.

- **It asks for the next run first.** A refresh request is used once; an app that forgets to submit
  another gets no more refreshes.
- **`expirationHandler` is the system saying time is up.** Here it cancels the sync, and
  `Planner.sync` has to notice the cancellation between steps and stop with its progress saved.
- **`setTaskCompleted` must be called**, early or late. The system measures how an app behaves in
  the background, and one that overruns or never reports gets fewer chances.

A SwiftUI app can write the same handler as a scene modifier, `.backgroundTask(.appRefresh(...))`,
whose closure is cancelled when the time runs out.

## Uploads that outlive the app

Thirty seconds is too short to send a photo attached to a session. For that, iOS has **background
`URLSession`**: the app hands a transfer to the system, and the system carries it on while the app
is suspended or even after it has been terminated, then wakes the app to say how it went.

```swift
let config = URLSessionConfiguration.background(withIdentifier: "org.example.planner.uploads")
let session = URLSession(configuration: config, delegate: uploader, delegateQueue: nil)
session.uploadTask(with: request, fromFile: photoURL).resume()
```

The upload must come from a file, because the app may not be alive to hand over bytes, and the
results arrive through the `delegate`. The exception is the one from the first section: a person
who swipes the app away has cancelled its background transfers too.
