---
title: Three teams, three answers
version: 1
---

**The same seven questions, asked by three different teams, point three different ways.** The teams
below are made up, and each is drawn so that one or two criteria dominate. Watch which answers do
the deciding, because that is the skill this lesson is about; the tool at the end of each story
matters less than the route to it.

## A bank's Android team

Two developers who have written Kotlin for Android for years are asked for a banking app. It must
sign the user in with a fingerprint, keep a token in the phone's secure storage, and pass the bank's
security review. Android comes first, because most of the bank's customers use it; iOS is planned
for the following year.

- Languages: Kotlin, and nothing else. Swift and TypeScript would both be new.
- Device features: biometrics and secure storage, where a mistake is a security defect rather
  than a bug.
- Platforms: one now, the second later.

**The answer is native Android, with Kotlin Multiplatform in view.** For one platform, native costs
nothing extra, and it puts the security-critical features in the team's own language with no
bridge in between. When iOS arrives, the rules already written in Kotlin can move into a shared
module, and the iOS screens are written in SwiftUI. The decision is to start native and keep the
logic free of Android so that it can be shared later.

## A startup with a web app

Four web developers have a planner-like web app that people already use, written in React and
TypeScript. Investors want it in both stores in three months. It is lists, forms, a few
notifications and storage on the device; nothing animates under the finger.

- Languages: TypeScript and React, every day.
- Time to market: three months, for two platforms at once.
- Performance: modest. Lists of a few hundred rows.

**The answer is React Native, with a wrapper as the fallback.** React Native keeps the language and
the React way of building screens, gives each phone its own native controls, and shares the logic
they already have. A wrapper would be faster still, because it keeps the screens too; if the three
months were six weeks, that would win. The team should write down that the choice between the two
rested on the deadline, because when the deadline is gone the reasons for a wrapper go with it.

## A studio building a drawing app

A small studio is building a sketching app: custom brushes, layers, a canvas that follows the finger
with no visible lag. The designers want the same canvas, pixel for pixel, on both phones. The team
knows some Dart and some Swift.

- Performance: dominant. Every stroke is drawn while the finger moves.
- Platforms: both, and the same drawing on each.
- Device features: touch and a stylus, and little else.

**The answer is Flutter, unless the stylus says otherwise.** Flutter paints every pixel itself, so
one drawing looks the same on both phones, and its code is compiled to native code rather than run
by an interpreter. But if the app's selling point becomes a stylus feature that only one platform
offers, the balance moves towards native on that platform, because that feature lives on the far
side of the border.

## What the three have in common

**None of them chose by asking which tool is best.** The bank chose by its language and its security
features, the startup by its deadline and its existing code, the studio by what it draws. Each
answer would be wrong for the other two teams. And each one came with a condition under which it
would change, which is the most useful sentence in any of these decisions to write down.
