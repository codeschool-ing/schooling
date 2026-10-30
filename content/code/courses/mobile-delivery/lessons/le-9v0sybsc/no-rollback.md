---
title: The rollback that does not exist
version: 1
---

**There is no rollback on a phone, and every plan that assumes one fails on the day it is
needed.** On a server, undoing a release means running the previous build again. On a phone, the
new version is installed, its data migrated, and the store will not hand people an older version
of an app they already have.

## Why the stores refuse to go back

- **Google Play refuses a version code lower than the one people have.** Lesson 9 explains the
  numbers; what matters here is that "upload the previous build" is refused, because its code is
  lower and, in any case, already used.
- **The App Store installs the newest version a device supports.** There is no way to publish an
  older version over a newer one.
- **The data has moved on.** A version that changed the database schema has already run its
  migration on every phone that installed it. The older version, installed on top, would open a
  database it does not understand. Lesson 20 comes back to that from the server's side.

## What there is instead: rolling forward

The way back is a **new version that behaves like the old one**: the previous code, or the previous
code with the one fix, built with a **higher** version code and released. It takes a build, a
review and a rollout, which on a good day is hours and on a bad day is two days, so it is not
something to discover during an incident.

| what a team says | what it can actually do |
|---|---|
| "roll back to 1.4.0" | release 1.5.1, whose code is 1.4.0's, with a higher version code |
| "pull the release" | halt the rollout; people who have 1.5.0 keep it |
| "switch the feature off" | only if the feature was behind a remote switch before release, lesson 19 |

The third row is the only instant one, and it exists only if somebody built it in advance.

## The same on three platforms

Kotlin, Swift and React Native apps are all installed binaries, so all three roll forward. React
Native has one more door: an over-the-air update can replace the JavaScript bundle without a store
release, within the limits lesson 6 described. It cannot replace native code, and it reaches only
apps that open and download it.
