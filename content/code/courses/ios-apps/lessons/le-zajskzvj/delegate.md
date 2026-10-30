---
title: The delegate, for the two moments the app is involved
version: 1
---

**Most of the time the system shows a notification without the app; there are two moments when it asks
the app instead.** One is a notification arriving while the app is already open on the screen. The
other is the person tapping a notification. Both are methods of `UNUserNotificationCenterDelegate`, and
an app that never sets a delegate gets the system's default for each. Nothing in this section was run;
it follows Apple's documentation for that protocol and for `UIApplicationDelegateAdaptor`, read on 30
October 2026.

## Where a delegate lives in a SwiftUI app

A SwiftUI app has no app delegate unless it asks for one. `UIApplicationDelegateAdaptor` is how it asks:
SwiftUI creates the delegate and calls its methods. Apple's documentation says to declare it once, in the
`App`, and that declaring it more than once is a runtime error. The planner's delegate sets itself as the
notification centre's delegate at launch, which has to happen before the app finishes launching for a
tap that opened the app to reach it:

```swift
// AppDelegate.swift
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var openSession: (String) -> Void = { _ in }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // The app is on screen: show the banner anyway, without the sound
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    // The person tapped it: open the session it is about
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.identifier
        if id.hasPrefix("reminder-") {
            openSession(String(id.dropFirst("reminder-".count)))
        }
    }
}
```

```swift
// PlannerApp.swift, with the delegate
@main
struct PlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
    }
}
```

## While the app is open

Apple's documentation for `userNotificationCenter(_:willPresent:)` is precise about the default, and it
surprises people: **if the delegate does not implement the method, the system behaves as if it had
answered "none"**, and a reminder arriving while the planner is open is not shown at all. The planner
answers `.banner` and `.list`: the banner appears over the app and the notification stays in Notification
Centre, without a sound, because the student is already looking at the app the reminder is about.

## When it is tapped

`userNotificationCenter(_:didReceive:)` receives the response, which carries the original notification
and its request. **The request's identifier is the address**, which is why section 03 made it
`reminder-` and the session's id: the delegate reads the id back and opens that session's course.
`openSession` is set by the app's root view, which owns the navigation path lesson 9 built, so the
delegate stays ignorant of screens.

The documentation adds that this method also hears about custom actions, buttons on the notification
like "Mark done", declared with `UNNotificationCategory` and `UNNotificationAction`, and that an app
which does not implement it never responds to them. The planner has none; a "Mark done" button that
changed the plan without opening the app is a reasonable next step, and it would arrive here.

## A string that is also a protocol

`hasPrefix("reminder-")` reads meaning out of an identifier, which this course avoids elsewhere: the
identifier is the planner's own convention, written in one function and read in one other. If a second
kind of notification is added, the honest version is a small enum with a function that writes the
identifier and one that parses it, tested in the package like lesson 9's deep links.
