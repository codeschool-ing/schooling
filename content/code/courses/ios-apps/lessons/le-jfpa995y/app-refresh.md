---
title: An app refresh task, from request to handler
version: 1
---

**An app refresh task takes three pieces, and missing any one of them fails without a message.** The
app declares it may refresh in the background, it asks the system to run a named task no earlier than
some date, and it says what to do when the task runs. This section was written from Apple's
documentation for `BGAppRefreshTaskRequest`, `BGTaskScheduler` and SwiftUI's
`backgroundTask(_:action:)`, and **none of it was run**.

## The declaration

In Xcode, the app target's *Signing & Capabilities* tab gains the *Background Modes* capability with
*Background fetch* ticked, and `Info.plist` lists every task identifier the app will schedule, under
`BGTaskSchedulerPermittedIdentifiers`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist (the background keys only) -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.example.planner.refresh</string>
    </array>
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
    </array>
</dict>
</plist>
```

The identifier is reverse-DNS like the bundle identifier from lesson 1, and by convention it starts
with it. **An identifier that is not in this list cannot be scheduled**: Apple's documentation for the
error `notPermitted` gives exactly two causes, an identifier missing from this array and a background
mode missing from the other.

## The request

The app asks for the next refresh whenever the plan changes and when it goes to the background:

```swift
// Refresh.swift
import BackgroundTasks
import PlannerCore

let refreshID = "com.example.planner.refresh"

func scheduleRefresh(pending: Int) {
    let request = BGAppRefreshTaskRequest(identifier: refreshID)
    request.earliestBeginDate = nextRefresh(after: .now, pending: pending, calendar: .current)
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("could not schedule a refresh:", error)
    }
}
```

`nextRefresh` is section 06's function, from the planner's package. **A request is not a promise**:
`earliestBeginDate` only says the task must not run before then. Submitting a new request with the
same identifier replaces the old one, so asking again whenever something changes is safe.

## The handler

SwiftUI attaches the work to the app's scene, with the same identifier:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    let repository: PlannerRepository
    @State private var model: PlannerModel

    init() {
        let api = APIClient(base: URL(string: "https://planner.example.com")!)
        let file = URL.applicationSupportDirectory.appending(path: "planner.json")
        let repository = try! PlannerRepository(source: api, store: FileStore(url: file))
        self.repository = repository
        _model = State(initialValue: PlannerModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            CourseListView(model: model)
        }
        .backgroundTask(.appRefresh(refreshID)) {
            _ = await repository.syncUntilCancelled()
            try? await repository.refresh()
            scheduleRefresh(pending: await repository.pendingCount)
        }
    }
}
```

**The handler is an `async` closure, and the task is complete when it returns.** Apple's documentation
for `backgroundTask(_:action:)` says the system cancels the task if the closure has not returned when
its time is up, and suggests `withTaskCancellationHandler` to notice. That cancellation is ordinary
Swift task cancellation, which is why section 07 can practise the whole expiration on Linux: it
cancels a task and watches what survives.

The handler schedules the next refresh before it returns, because a refresh task runs once. An app
that forgets that line refreshes in the background exactly one time.

The model is held in `@State` so that it is made once, not every time `body` is evaluated; lesson 6 is
about why that matters. The `try!` in `init` is a sketch's shortcut: a planner that cannot read its own file at launch has
nothing to show, and lesson 14 is where that failure is handled properly.
