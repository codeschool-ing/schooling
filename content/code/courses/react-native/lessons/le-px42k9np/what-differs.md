---
title: What really differs between the two
version: 1
---

**Most of an app is the same on both platforms; a short list of things is not**, and each item on it
is a place where a user of one platform expects something a user of the other would find strange. These
are the ones the planner meets, from the platforms' own design guidance, Apple's *Human Interface
Guidelines* and Google's *Material Design*.

## Going back

**Android has a system back action** — a button, or a swipe from the edge of the screen in gesture
navigation — that every app must answer. React Navigation, in lesson 8, answers it for you by going back
a screen. An app that needs to intervene, to ask before discarding a half-filled form, listens with
`BackHandler`. **iOS has no system back**: going back is the button at the top left of a pushed screen,
or a swipe from the left edge, and both belong to the navigation, which again lesson 8 provides.

## The top and the bottom of the screen

Both platforms draw over the app: a **status bar** at the top, and on iPhones without a home button a
**home indicator** at the bottom; Android phones with gesture navigation have a gesture bar there too.
Many phones also have a camera cut-out in the top edge. The space each takes varies by model, and the
app must keep its content out of it. That is the next section.

## Drawing

| | iOS | Android |
|---|---|---|
| shadows | four shadow properties | `elevation` |
| the system font | San Francisco | Roboto |
| a pressed control | dims | a ripple, `android_ripple` on a `Pressable` |
| a switch, a date picker, an alert | drawn by UIKit | drawn by Android |

**Do not copy one platform's look onto the other.** A ripple on an iPhone, or a dimming row on Android,
reads as an app that was made for somebody else. `Pressable`'s `android_ripple` prop gives Android its
ripple and does nothing on iOS, which is exactly the shape of a good platform difference.

## Behaviour that lives outside your app

Permissions are asked differently, and Android 13 added one iOS has always had, for notifications;
lessons 13 and 16 are about both. The keyboard pushes content differently, which is lesson 11. Background
work has different rules on each, which is lesson 15. And the stores review apps by different rules,
which is the `mobile-delivery` course.

## And the one difference that is the web

The web build has no status bar, no back action of the phone's kind, no haptics and no secure storage.
It is a stand-in for this course's purposes, and it answers `"web"` when asked. The planner shows the
difference in one sentence at the foot of its screen, from the three files of the last section.
