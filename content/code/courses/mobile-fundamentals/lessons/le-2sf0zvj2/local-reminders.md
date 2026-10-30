---
title: Reminders the phone schedules itself
version: 1
---

**"Your session starts in 15 minutes" does not need a server, a token or a push at all.** The app
knows the sessions and their times. It can ask the phone's own system to show a notification at a
given moment, and the system does, whether or not the app is running and whether or not there is a
network. That is a *local* notification. Lesson 15 said that no background job can run at 18:45
exactly; a scheduled local notification is the tool that can, because the system itself keeps the
appointment.

Each platform schedules one differently. The fragments below are adapted from Apple's article on
scheduling a notification locally, Android's guide to Doze, which names the alarm that may fire
while the phone dozes, and the documentation of `expo-notifications`, and **were not compiled or run for this course**:

```swift
let content = UNMutableNotificationContent()
content.title = "SQL Databases"
content.body = "Your SQL session starts in 15 minutes"
let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindAt)
let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
try await UNUserNotificationCenter.current()
    .add(UNNotificationRequest(identifier: "remind-s3", content: content, trigger: trigger))
```

```kotlin
// Android has no "show this at 18:45": an alarm wakes a receiver, which posts the notification
val alarms = context.getSystemService(AlarmManager::class.java)
val wake = PendingIntent.getBroadcast(
    context, 3, Intent(context, ReminderReceiver::class.java), PendingIntent.FLAG_IMMUTABLE,
)
alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, remindAt.toEpochMilli(), wake)
```

```tsx
import * as Notifications from "expo-notifications";

await Notifications.scheduleNotificationAsync({
  identifier: "remind-s3",
  content: { title: "SQL Databases", body: "Your SQL session starts in 15 minutes" },
  trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: remindAt, channelId: "reminders" },
});
```

**Each one is given an identifier**, `remind-s3`, so that the app can cancel it. Apple's article
says it plainly: a scheduled request stays active until its trigger fires or the app cancels it,
and you cancel it when it is no longer needed. When the student marks `s3` done, or moves it to
Saturday, the reminder for Friday has to go, or the phone will remind her of a session that no
longer exists.

## Working out the week's reminders

The interesting part is not the call to the system. It is deciding **which** reminders to schedule
and **when**, and that is plain logic you can run. `reminders.ts` takes the planner's sessions with
their start times, and for each one decides: done already, outside this week, already past, or a
reminder fifteen minutes before it starts. "Now" is given as an argument, as "today" was in lesson 1.

**The times are wall-clock times in the student's city, São Paulo**, and the system schedules an
instant. So the program converts "Friday 23 October at 19:00 in `America/Sao_Paulo`" into an instant
with the `Intl` API, which carries the world's time-zone rules, rather than by adding a fixed number
of hours that would be wrong in any city with summer time. Save it as `reminders.ts`:

```typescript
// reminders.ts: which of the week's sessions get a reminder, and at what instant
import { mondayOf, type Session } from "./planner.ts";

const ZONE = "America/Sao_Paulo";
const BEFORE_MIN = 15;
type Timed = Session & { title: string; at: string }; // at: HH:MM, wall-clock time in ZONE

// How many minutes ZONE is ahead of UTC at a given instant.
function offsetMin(instant: Date): number {
  const f = new Intl.DateTimeFormat("en-GB", {
    timeZone: ZONE, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  });
  const p = Object.fromEntries(f.formatToParts(instant).map((x) => [x.type, x.value]));
  const wall = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute);
  return (wall - instant.getTime()) / 60000;
}

// The instant at which the wall clock in ZONE reads `date` `time`.
function instantOf(date: string, time: string): Date {
  const guess = new Date(`${date}T${time}:00Z`);
  return new Date(guess.getTime() - offsetMin(guess) * 60000);
}

const local = new Intl.DateTimeFormat("en-GB", {
  timeZone: ZONE, weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
});

const sessions: Timed[] = [
  { id: "s1", courseId: "sql", title: "SQL Databases", date: "2026-10-19", at: "08:00", minutes: 50, done: true },
  { id: "s2", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-20", at: "19:00", minutes: 40, done: true },
  { id: "s6", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-21", at: "07:30", minutes: 30, done: false },
  { id: "s5", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-22", at: "18:30", minutes: 30, done: true },
  { id: "s3", courseId: "sql", title: "SQL Databases", date: "2026-10-23", at: "19:00", minutes: 60, done: false },
  { id: "s4", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-27", at: "08:30", minutes: 45, done: false },
];

const now = new Date(process.argv[2]); // given, never read from the clock here
const week = mondayOf(now.toISOString().slice(0, 10));
for (const s of sessions) {
  const start = instantOf(s.date, s.at);
  const remindAt = new Date(start.getTime() - BEFORE_MIN * 60000);
  const label = `${s.id} ${s.title.padEnd(19)} ${local.format(start)}`;
  if (s.done) console.log(`${label}  skip: done`);
  else if (mondayOf(s.date) !== week) console.log(`${label}  skip: not this week`);
  else if (remindAt <= now) console.log(`${label}  skip: already past`);
  else console.log(`${label}  remind at ${local.format(remindAt)} = ${remindAt.toISOString()}`);
}
```

Lesson 1's sessions had a date and no time, so this file gives each a start time, and adds one
session, `s6`, early on Wednesday morning, to have one that is already past. Run it at noon on
Wednesday 21 October, São Paulo time:

```
ana@dev:~/planner$ node reminders.ts 2026-10-21T12:00:00-03:00
s1 SQL Databases       Mon 19 Oct, 08:00  skip: done
s2 Mobile Fundamentals Tue 20 Oct, 19:00  skip: done
s6 Mobile Fundamentals Wed 21 Oct, 07:30  skip: already past
s5 Mobile Fundamentals Thu 22 Oct, 18:30  skip: done
s3 SQL Databases       Fri 23 Oct, 19:00  remind at Fri 23 Oct, 18:45 = 2026-10-23T21:45:00.000Z
s4 Mobile Fundamentals Tue 27 Oct, 08:30  skip: not this week
```

**One reminder out of six sessions**, and each skip has its reason. `s1`, `s2` and `s5` are done. `s6`
started at 07:30 this morning, so its reminder would be in the past. `s4` is next week, and gets its
reminder when the app plans that week. And `s3`, on Friday at 19:00, gets one at **18:45 São Paulo
time, which is 21:45 UTC**: the same moment, written twice, and the second form is the one a server
or a system stores. On a phone, this loop is what runs when the plan changes, cancelling the old
reminders by identifier and scheduling the new ones.
