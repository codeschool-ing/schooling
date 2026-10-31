---
title: What may be shipped that way
version: 1
---

Two kinds of rule decide what an over-the-air update may contain: what is technically possible, and what
the stores allow.

## What is possible

| may change in an update | needs a new build |
|---|---|
| any JavaScript or TypeScript: screens, logic, text, styles | a library with native code, added, removed or upgraded |
| images, fonts and other assets the bundle imports | a permission, or its sentence |
| an `EXPO_PUBLIC_` value, which is fixed into the bundle | the app's name, icon, splash screen, package name |
| | anything in `app.json` that prebuild writes into the native projects |
| | the Expo SDK or React Native version |

**An update that needs native code the build does not have does not fail gently.** JavaScript that calls a
native module missing from the build crashes the moment it reaches that call, on every phone that took the
update. Lesson 17's `requireNativeModule` throws exactly so. The next section is how that is prevented.

## What the stores allow

- **Apple** allows code downloaded after review when it runs in a JavaScript engine and does not change
  the app's primary purpose, or add features that would have needed review. A fix, a text change, a small
  improvement to an existing screen are what updates are for. A new feature that review never saw is
  exactly what the rule is about.
- **Google Play**'s policy forbids an app from updating itself outside Play, with an exception for code that
  runs in a virtual machine or an interpreter, as JavaScript does here, without direct access to Android's
  APIs.

*These are this course's reading of both stores' published guidelines, and both are written by people who
reserve the right to judge each case.* The practical rule is the same either way: **an update fixes and
improves what was reviewed; anything new goes through the store.**
