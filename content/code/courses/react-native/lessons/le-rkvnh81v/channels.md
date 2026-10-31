---
title: Channels, rollouts, and the way back
version: 1
---

**EAS Update is Expo's update server**, and its words are worth learning, because they say where an update
goes:

- **A branch** is a line of updates, like a git branch: each `eas update` adds one to a branch.
- **A channel** is fixed into a build when it is built: `eas.json`'s `production` profile gets the
  `production` channel, `preview` gets `preview`. A build asks its channel for updates.
- **A channel points at a branch.** Pointing `production` at a different branch changes what every
  production build receives, without building anything.

So the safe path for a fix is the one that tests first:

1. `eas update --branch preview --message "Keep the week total when the server is slow"` publishes to the
   preview builds, which testers have.
2. Once it has been tried there, the same update goes to production, **to a percentage first**: EAS
   Update can send an update to, say, 10 percent of production builds, and raise the share as the crash
   reports stay quiet.
3. If it goes wrong, **`eas update:rollback`** points the channel back to the update before, or to the
   build's own embedded bundle, which every build carries.

*None of these commands was run for this course, because Expo's servers refused the machine that recorded
it; they are from Expo's documentation, for `eas-cli` 27.*

## When an update itself breaks

`expo-updates` protects a phone from the worst case: an update whose JavaScript crashes before the app has
started properly is marked bad, and the next launch runs the update before it, or the embedded bundle. That
is a net, not a plan. **An update is a release**: it goes through the same tests, the same review by a
person, and a channel with testers before the one with everybody, because unlike a store release it reaches
every phone within hours.

**And an update can never fix a build that cannot start.** If a native crash happens before JavaScript runs,
no update will ever be downloaded by that build. That case is a store release.
