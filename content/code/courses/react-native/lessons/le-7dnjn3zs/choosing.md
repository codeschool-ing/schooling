---
title: Choosing, and what this course chose
version: 1
---

**The question is not Expo or React Native.** It is the React Native you will write either way, and
two smaller questions underneath it: who writes the native projects, and who builds the app.

| your situation | start with | why |
|---|---|---|
| a new app, no native code yet | Expo, with prebuild | everything in this course works on day one, and nothing stops you adding native code later |
| a new app that you know needs a native SDK with no config plugin | Expo, with prebuild and a plugin you write | twenty lines of plugin are cheaper than two native projects maintained by hand |
| an existing Android or iOS app adding React Native to some screens | bare, following React Native's guide for existing apps | the native project already exists and belongs to its team |
| a team of native developers who will edit Gradle and Xcode daily | bare, or Expo with the folders committed | generation would fight the way they work |

## What this course uses

**Expo SDK 58, with React Native 0.88, and prebuild.** The planner starts in lesson 3 from Expo's
template, runs in a browser and in tests on the computer, gets its native folders generated when an
Android build is needed, and gains a native module of its own in lesson 17 without either folder
being edited by hand.

That choice is also what React Native's own documentation recommends for a new app, which matters
for a practical reason: the examples you find, in the documentation and in libraries' instructions,
increasingly assume it. Where a library's instructions say "edit `MainApplication.kt`", the Expo
version of the same instruction is its config plugin, and lesson 17 shows how to tell which one a
library has.

## A check on the decision

Three questions, before a team writes its first screen:

1. **Does any library the app needs carry native code and no config plugin?** If so, budget a
   plugin for each, or a bare project.
2. **Who builds the iOS app, on what?** A Mac on somebody's desk, or EAS Build. Lesson 20.
3. **Will anybody edit the native folders by hand?** If yes, commit them and treat the project as
   bare from the start, rather than discovering the edits after a `prebuild --clean`.
