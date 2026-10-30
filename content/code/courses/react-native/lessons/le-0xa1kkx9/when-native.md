---
title: Do you need a native module?
version: 1
---

**Every library in this course with native code is a native module somebody else wrote.** The camera,
SQLite, location, notifications: each is a package with Kotlin, Swift and a JavaScript face, and an Expo
config plugin for its declarations. Writing your own is the same work, done for something nobody packaged.

Ask three questions before writing one:

1. **Is there a library?** The [React Native Directory](https://reactnative.directory) lists thousands,
   with which platforms each supports and whether it works with the new architecture. A maintained library
   is better than your own module for almost anything a second app could also want.
2. **Is it reachable from JavaScript already?** React Native exposes a lot through its own modules:
   `Linking`, `AccessibilityInfo`, `Platform`, `Appearance`. A module for something they already answer
   is code to maintain for nothing.
3. **Does it have to be synchronous, or fast?** A native function can be called synchronously through
   JSI, lesson 1's interface, and runs at native speed. Heavy computation, image processing, audio, can
   belong there for that reason alone.

**The planner's case is small on purpose.** Which day does the person's calendar start the week on? It is
Sunday in Brazil and the United States, Monday in most of Europe, and the person can change it in the
phone's settings. React Native's JavaScript has no portable way to ask, and each platform's calendar
answers in one line. A module with one function is the smallest honest example, and it shows every step a
bigger one takes.

## Expo Modules and Turbo Modules

There are two ways to write a module for today's React Native:

- **Turbo Modules** are React Native's own: a TypeScript spec, code generated from it by Codegen, and
  native classes that implement the generated interfaces, in Java or Kotlin and in Objective-C++.
- **The Expo Modules API** describes the module in Kotlin and in Swift directly, with a small language
  of `Name`, `Function`, `AsyncFunction`, `Events` and `View`, and generates nothing you have to read. It
  sits on the same JSI, so a call costs the same.

**This course uses the Expo Modules API**: it is Swift rather than Objective-C++ on iOS, it needs no
generated code, and it is what every Expo library uses, so it is the same shape as everything you
installed. A Turbo Module is the right choice for a library meant to be used without Expo's packages.
