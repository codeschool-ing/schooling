---
title: One JavaScript codebase, two native apps
version: 1
---

**A React Native app is written in JavaScript, or TypeScript, and draws real native views.** The
code runs in a JavaScript engine inside the app. React Native turns what it describes into the
platform's own widgets: a `<Text>` becomes a `TextView` on Android and a `UILabel` on iOS, a
`<FlatList>` a scrolling list on each. One codebase, two apps, each looking like its platform.

The common mistake is to think of such an app as a web page in a frame, the way some older
frameworks worked. It is not: there is no browser and no HTML. To a test it looks like any other
native app, which is why Appium can drive it. Lesson 15's page source of a React Native app is
full of `android.widget` classes like Tickets's. What a test cannot see from outside is the
JavaScript side, where most of the app's behaviour actually lives.

## `testID`: one name, two platforms

Lesson 14 made the resource id the first handle for a test. Lesson 15 said the trouble with
running one test on both platforms is that the two apps name their elements separately. React
Native removes that trouble for its own components with one property, **`testID`**:

| written once | on Android it becomes | on iOS it becomes |
|---|---|---|
| `<Button testID="refresh" … />` | the resource id the accessibility tree reports, `refresh`, with no package in front | the accessibility identifier, `refresh` |

So `by.id('refresh')` in Detox finds the same button on both platforms, and so would one Appium
locator per platform. **The promise between developers and testers of lesson 14 is kept once, in
the JavaScript**, and both apps inherit it.

## The app of this lesson

This lesson does not rebuild Tickets in React Native screen for screen. It writes the list alone,
in one file. There are the shows from boxoffice and a refresh button. There is an error line when
boxoffice cannot be reached, and a line at the bottom naming the show you tapped and its seats. That is enough for a
spec to load, tap and check, and small enough to read whole in section 05.

**No React Native app was built or run for this course.** Building one downloads Gradle and
libraries from Google's repository, which the recording machine cannot reach. Running it needs an
emulator, which that machine cannot start, as lesson 14 showed. Everything else in this lesson ran there:
creating the project, checking its code with TypeScript, installing Detox and asking it to test.
