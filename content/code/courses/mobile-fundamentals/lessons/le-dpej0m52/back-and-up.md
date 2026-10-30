---
title: Back, up, and what happens at the bottom of the pile
version: 1
---

**Every Android phone has a system *back*, and an iPhone has none.** That is the one difference in
navigation the system enforces, rather than a designer choosing. On Android, back is a button in the
navigation bar on older phones and a swipe in from either edge of the screen on newer ones. It belongs
to the system, not to the app: your app does not draw it and cannot remove it, and can only decide what
it does. On an iPhone, going back is a control the app draws. It is a back button at the top left of a
pushed screen, with a swipe from the left edge as a shortcut to it. Apple's guidelines on gestures
put it this way: people "expect to find a Back button in a top toolbar", and the swipe is offered
"while continuing to provide the Back button".

| | Android | iOS |
|---|---|---|
| who provides back | the system: a button, or a swipe from either edge | the app: a button it draws, and the edge swipe the navigation adds |
| on a pushed screen | pops it | the back button pops it |
| at the root of the first tab | the app leaves the screen | there is no back button to press |
| over a sheet or an open drawer | closes it | a button, or a swipe down, closes a sheet |

## Back at the root

**On Android, back at the root of the app takes the student out of it**, to whatever was before: the
home screen, or the app that opened yours. Android's navigation principles describe the start
destination as "the last screen they see before exiting the app". What happens to the app after that
changed in Android 12. According to Android's documentation on that release's behaviour changes, back
on the screen the launcher opened, at the root of its task, now moves the task to the background, as
the Home gesture does, where earlier versions finished that screen's activity. The app is not killed by it; it is in the background,
and lesson 4 says what the system may do to it from there.

**On iOS, the root of a stack simply has no back button.** There is nowhere inside the app to go back
to. A person leaves an iPhone app with the system's own gesture to go home, which is not
back and which the app never sees as a navigation event.

**Tabs add one more step on Android.** Back at the root of any tab other than the first returns to the
first tab, and only back at the root of the first tab leaves the app. That is the usual arrangement,
and the one Android's navigation library builds for a bottom bar. So the student who is on Week
presses back once to reach Courses, and once more to leave. The next two sections model exactly that.

## Predictive back

**From Android 13, a back swipe can show where it is going before the finger lets go.** Android calls
this *predictive back*. As the student swipes, the current screen shrinks and the one behind it shows;
at the root, the app's screen shrinks over a glimpse of the home screen. Lifting the finger commits;
sliding back cancels. Android's documentation on the predictive back gesture, as read on 30 October
2026, says it was behind a developer option on Android 13 and 14. From Android 15, the system
animations appear by default for apps that have opted in to it. The consequence for an app is that the
system must know *before* the swipe ends whether the app will handle back itself, so an app declares
in advance which screen is answering, instead of reacting once the press has happened.

## Up is not back

**Android has a second arrow, *up*, and the difference matters when a student arrived from somewhere
else.** Up is the arrow at the top left of the app bar. Android's navigation principles say that within
the app's own task, up and back behave identically, and then name two differences:

- **Up never exits the app.** At the start destination there is no up arrow at all, while back is
  still there and leaves.
- **After a link from another app, they part.** Back returns to the app the student came from. Up goes
  to the screen *above* this one in your app's hierarchy, through a back stack the navigation library
  builds for the occasion, because the student never walked through it.

The second case is lesson 11's subject: a link that opens the planner straight on one course has
skipped the Courses list, and up has to know it is there anyway. On iOS the back button at the top left
does the job of both, and after a link from another app the system adds a small control in the status
bar to return to the app the person came from.
