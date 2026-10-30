---
title: Processing tasks, and the work the person watches
version: 1
---

**A refresh is short and frequent. A processing task is long and rare.** Apple's documentation
describes `BGProcessingTask` as a task that can take minutes, scheduled for periods of low activity
such as overnight while the device charges, and it is where work goes that would be rude at any other
time: rebuilding an index, cleaning old data, migrating a store. **Not run**, like everything in this
lesson that asks the system for time.

## Asking for one

The request carries two conditions the refresh request does not have:

```swift
// Maintenance.swift
import BackgroundTasks

let maintenanceID = "com.example.planner.maintenance"

func scheduleMaintenance() {
    let request = BGProcessingTaskRequest(identifier: maintenanceID)
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = true
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("could not schedule maintenance:", error)
    }
}
```

`requiresExternalPower` asks the system to wait for a charger, which in practice means overnight.
`requiresNetworkConnectivity` is false because the work is on the device. The identifier goes in
`BGTaskSchedulerPermittedIdentifiers` beside section 03's, and the capability needs *Background
processing* ticked as well as *Background fetch*; the `Info.plist` value for it is `processing`.

**The planner has little that deserves one.** Its store is one small file. A processing task earns its
place in an app with a real database to compact, a search index to rebuild or a model to retrain, and
lesson 13's SwiftData store, migrated after an update, is the closest the planner comes. Asking for
time the app does not need costs the person battery for nothing, and the system notices which apps
use the time they are given.

## Work the person starts and watches

The other long case is the opposite of overnight maintenance: the person presses *Export my year of
study* and then switches to another app. On iOS 26 and later, Apple's documentation describes
`BGContinuedProcessingTaskRequest` for exactly that: a task submitted from the foreground, **as a
result of something the person did**, which the system lets continue in the background while showing
its progress, and which the person can cancel from that display. The documentation also says the
system may end it under pressure and ends first the tasks that report little or no progress, so
progress reporting is part of the contract rather than decoration.

The planner targets iOS 17, so it cannot rely on this, and has nothing yet that takes long enough to
need it. **The rule it states is worth keeping either way: long work the person asked for should show
progress, and long work they did not ask for should wait for the charger.**
