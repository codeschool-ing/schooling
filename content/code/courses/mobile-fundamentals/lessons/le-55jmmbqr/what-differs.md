---
title: What is genuinely different, and what only looks different
version: 1
---

**Most of what separates an Android app from an iOS app is convention, and a few things are real
constraints.** Telling them apart early saves a lot of arguing later, because a convention can be
followed or broken by a designer, and a constraint is enforced by the system whatever anybody
decides.

## The real differences

- **Back.** Every Android phone has a system *back* action, a gesture from the edge of the screen or
  a button, and the app has to answer it. An iPhone has none: going back is a button the app draws,
  or a swipe the navigation provides. Lesson 10 is about what that does to an app's screens.
- **How much the system lets an app run in the background.** Both stop an app that is not on screen,
  and iOS is stricter about it: an app there gets a few named kinds of background work and nothing
  else. Android allows more, with rules that tightened in almost every release. Lesson 15 compares
  the two.
- **Distribution.** An Android app can be installed from a file, which makes testing on a friend's
  phone a matter of sending them the file. An iPhone runs only apps signed through Apple, and a
  tester gets one through Apple's TestFlight. Lesson 20 shows what each store asks for.
- **Review.** Every app and every update goes through Apple's review before it reaches the App Store,
  and Google reviews apps for Play too. Both reject, for different reasons and at different speeds.

## The conventions

On iOS the tabs sit in a bar at the bottom of the screen; Material Design offers tabs at the top as
well as a navigation bar at the bottom. Material draws a floating button for the main action, and
iOS puts that action in the navigation bar at the top. Lists, switches and dialogs look different. **These are
the two companies' design guides**, Material Design and the Human Interface Guidelines, and lesson
18 reads them side by side. A user notices when an app ignores them, and an app can still ignore
them and work.

## And what is the same

Here is the part this whole course is about. On both platforms:

- the **system owns the app's lifecycle**: it starts, pauses and kills the process when it decides
  to (lessons 4 and 5);
- the **screen** is small, changes shape when the phone turns, and has notches and bars in it
  (lessons 7 to 9);
- **permissions** are asked of the user, at a moment the app chooses, and can be refused for good
  (lesson 12);
- the **network** comes and goes, and a request can simply never return (lesson 14);
- the **battery** belongs to the user, and the system enforces that (lesson 15);
- every app lives in a **sandbox**, with storage nobody else can read (lesson 16).

Those rules hold whichever platform, language and toolkit you choose after the fork. That is why
this course comes first and needs no phone to teach them.
