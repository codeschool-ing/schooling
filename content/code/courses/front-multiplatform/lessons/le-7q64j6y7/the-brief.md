---
title: The brief: your app, on one more platform
version: 1
---

**The project is a web app of yours, made into an app for one platform, released, and shown in your
portfolio.** Not the planner: the planner was the course's, and every step of it is already in these lessons.
Yours is a web app you wrote, in any framework or in none, from an earlier course or from your own work. If
you have none that you would show, the planner is allowed as a starting point, as long as the app you release
does something the course's did not.

## What you hand in

| part | what it is |
|---|---|
| **a decision note** | one page: which route you took, and why, in the terms of lesson 10 |
| **the app**, on one platform | an Android package, a desktop package, or both, built from a tagged commit |
| **one feature of the device** | at least one thing a website cannot do: a file, a notification, the camera, the window's menu |
| **a release** | the packages, `SHA256SUMS`, its signature and your public key, and release notes |
| **a version that moves** | at least two releases, so the second one shows that the numbers and the update path work |
| **the repository** | the code, with no key in it and a README that says how to build and how to install |

**The route is yours to choose**, and the decision note is where you choose it. Lesson 10 ended on that: the
reasons matter more than the choice. A good note fits on a page and answers four questions:

```
# Decision: how my app reaches <the platform>

## What the app is
One paragraph: what it does, who it is for, and what it runs on today.

## What the platform has to add
The device features or the desktop features the app needs that a browser does not give it.

## The route
Capacitor, React Native, Electron or Tauri, and the one or two you did not take.

## Why
What the route reuses of the code you have, what it costs, and who will maintain it.
What you would need to see to change your mind.
```

**What "released" means depends on the route, and none of it needs a store.** An Android APK signed with your
own key, offered as a download, is a release; so is an AppImage and a `.deb` from your site. The stores are
optional, cost money, and lesson 14 said what each asks for. If you publish to one, say so in the README with a
link; if you do not, say how a person installs the file instead.

**What your computer cannot run is said, not hidden.** An iOS build without a Mac, a Windows installer without
Windows: the note says which platforms you built and tested, and which you did not, exactly as this course
marked each step it could not run.
