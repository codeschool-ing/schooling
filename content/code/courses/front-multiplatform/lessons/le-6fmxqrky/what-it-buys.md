---
title: What the native path buys, and what it costs
version: 1
---

**Lesson 6 asked when an app needs native views. Now that the planner has both, the answer can be made
concrete**, feature by feature, rather than as a matter of taste.

## What it buys

- **The platform's own controls.** A text field is the system's text field, with its keyboard, its
  autocorrection, its selection handles and its accessibility, on each platform as that platform does
  it. A WebView's field is a web field that looks almost the same.
- **Lists that scroll like the platform's.** `FlatList`, in lesson 8, draws only the rows on the screen
  and recycles them as you scroll; lesson 6's measurement is the reason that matters.
- **Gestures and animation off the JavaScript thread.** Libraries such as React Native's gesture and
  animation packages run a swipe or a transition on the native side, so a busy JavaScript thread does
  not make it stutter.
- **A way into the native world when it is needed.** An Expo app can include native modules in Swift and
  Kotlin, like a Capacitor plugin, and libraries for widgets and background work exist for it.

## What it costs

- **The screens, written again.** Nothing of `view.ts` survived, and nothing of the HTML and CSS of a
  real app would. The rules and the data did.
- **No CSS.** Styles are objects, layout is flexbox only, and nothing cascades. Lesson 8 shows the
  differences that surprise web developers.
- **Two platforms that differ, still.** One codebase, yes; but a shadow, a font or a keyboard behaves
  differently on Android and iOS, and both have to be tried. A WebView hides more of that.
- **A native build in the end.** The browser and Expo Go take you a long way, and a release needs a real
  Android and iOS build, which lesson 9 is about.

**For the planner, the honest score is close.** The native version gives nothing the person would
miss today, and costs a second set of screens. The day the planner shows a list of a thousand sessions
with a swipe to mark one done, the score changes, and lesson 6's three questions are how you notice.
