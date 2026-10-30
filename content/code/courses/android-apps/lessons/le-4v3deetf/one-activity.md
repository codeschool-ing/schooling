---
title: One activity, and every screen inside it
version: 1
---

**A Compose app usually has one activity, and every screen is a composable inside it.** That is not
how Android began. For its first decade an app was a set of activities, one per screen. Moving from
the course list to a course's sessions meant asking the system to start another activity with an
**intent**:

```kotlin
startActivity(Intent(this, SessionsActivity::class.java).putExtra("courseId", "kotlin"))
```

That line, from a hypothetical `SessionsActivity`, is not part of the planner and was not run. It
shows what the old shape cost. Each screen was an entry in the manifest, and each was destroyed and
rebuilt on rotation on its own. Data travelled between screens as extras in a `Bundle`, so
everything passed had to be a few kinds of value the system can copy. And every transition was the
system's, with its animation and its rules about what Back does.

With one activity, a screen is a function. Going from the course list to a course is calling
another composable, the screen's arguments are ordinary Kotlin parameters, and Back is decided by a
**back stack** your code owns. Lesson 9 builds that with Navigation Compose. The single activity
still matters, because it is what the system knows about: it gets the lifecycle callbacks, it is
destroyed on rotation and rebuilt after process death, and it is what the launcher icon opens.

## Intents still matter

The planner will send and receive intents even with one activity, because an intent is also how
apps talk to each other:

- the launcher starts the planner with the `MAIN`/`LAUNCHER` intent from lesson 1 section 07;
- a notification, lesson 19, carries a `PendingIntent` that opens the planner on a given course;
- a link, `mobile-fundamentals` lesson 11, can open the planner from a browser through an
  `<intent-filter>` with a URL in it;
- the planner can hand a session to the calendar app with an intent it does not know the receiver of.

**Each of these is a door into the app from outside**, which is what `android:exported` controls. An
activity with `exported="true"` can be started by any app on the phone, with any extras it likes,
so whatever it reads from an intent is input from a stranger and is checked like any other input.
The planner exports exactly one activity, the one the launcher needs.

## What lessons 3 to 22 will assume

From here on, `MainActivity` stays as small as it is now: `setContent`, a theme, and one composable
that is the app. Everything that is not drawing moves out of it, into a `ViewModel` (lesson 10),
a repository (lesson 16) and a database (lesson 15). An activity that does as little as possible
is one the system can destroy and rebuild as often as it likes.
