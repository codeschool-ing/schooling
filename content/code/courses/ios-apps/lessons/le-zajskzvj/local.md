---
title: A local notification, from content to request
version: 1
---

**A local notification is scheduled by the app itself and delivered by the system, whether or not the
app is running then.** Apple's article on scheduling a notification locally lists the three pieces: the
content, a trigger, and a request that joins them with an identifier. Nothing in this section was run;
it follows that article and the documentation for the classes it names, read on 30 October 2026.

## The planner's reminder

```swift
// Scheduling the reminder for one session
import UserNotifications
import PlannerCore

func scheduleReminder(for session: StudySession, course: Course) async throws {
    let content = UNMutableNotificationContent()
    content.title = course.title
    content.body = "\(session.minutes) minutes planned for tomorrow"
    content.sound = .default
    content.threadIdentifier = course.id

    let when = reminder(forDay: session.date, at: 19)
    let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)

    let request = UNNotificationRequest(identifier: "reminder-\(session.id)",
                                        content: content, trigger: trigger)
    try await UNUserNotificationCenter.current().add(request)
}
```

`reminder(forDay:at:)` is section 04's function, from the package: the one piece of this code that ran
for the course. The rest is the article's three pieces in order.

**The identifier is the session's, and that is the decision this code turns on.** Apple's documentation
for `UNNotificationRequest` says a request with the identifier of one already scheduled replaces it.
So rescheduling after the student moves a session to another day is the same call again, with no
duplicate reminder for the old day; and cancelling one, when the session is marked done or deleted, is
one line:

```swift
// Cancelling the reminder of a session that is done
UNUserNotificationCenter.current()
    .removePendingNotificationRequests(withIdentifiers: ["reminder-\(session.id)"])
```

The article puts it as a habit: you cancel a request "when conditions change and you no longer need to
notify the user", and its example is the planner's case, a reminder for something already completed.
**A reminder for a session already done is worse than none**, because the next one is read with less
attention.

`threadIdentifier` is the same grouping as the payload's `thread-id` in section 07: a course's reminders
gather under one heading on the lock screen.

## What `add` does not promise

`add` schedules; it does not deliver. The person may have turned notifications off since saying yes,
or put the phone in a Focus that silences the app, and the app is not told when either of those keeps
a reminder from being seen. So the planner never relies on a reminder as the only record of anything:
the session is in the plan whether or not the reminder fired.
