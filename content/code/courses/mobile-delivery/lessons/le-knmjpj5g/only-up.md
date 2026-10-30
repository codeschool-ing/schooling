---
title: The number that only goes up
version: 1
---

**A version code that goes down is a release no phone can install, and a version code used twice is
a release no store will take.** Both rules exist so that "newer" means one thing everywhere, and both
are enforced when you upload, not when you build.

## Android and Google Play

- **An update must have a higher `versionCode` than the installed app.** Android refuses to install
  a lower one over a higher one, which is lesson 8's missing rollback seen from the phone.
- **Google Play refuses a `versionCode` it has seen before** for the app, on any track. Lesson 7's
  rebuilt 42 was refused for exactly this.
- **The largest value Google Play allows is 2,100,000,000.** A scheme that multiplies the version
  parts into the code has to stay under it.

## iOS and the App Store

- **The version string, `CFBundleShortVersionString`, must increase from one App Store version to
  the next.** It is up to three numbers separated by dots.
- **The build number must be unique among the builds uploaded for a version.** Two uploads of 1.5.0
  can be build 1 and build 2, or 1050002 and 1050003; they cannot both be 1050003.
- Apple compares the build number as dot-separated integers, so `10` is newer than `9`, not older as
  text sorting would have it.

## The failure that teaches it

A team ships 1.5.0 and then discovers a bug in the 1.4 line that some customers stay on. It builds
**1.4.1**, a perfectly sensible name, with the code its scheme gives 1.4.1, which is lower than
1.5.0's. Google Play refuses it for production, because production already holds a higher code, and
a phone on 1.5.0 would never accept it anyway. **On a phone there is one line of versions, and it only
moves forward**: the fix is 1.5.1, with the fix in it, and the next section's script refuses the
1.4.1 before anybody uploads it.
