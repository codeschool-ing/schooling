---
title: Phones, rollouts, and building on three machines
version: 1
---

**On a phone the store is the updater**, and you decide only how fast a new version reaches people. Both stores
let you release to a fraction first:

| store | how | what you can do while it runs |
|---|---|---|
| Google Play | a **staged rollout**: the release goes to a percentage of the production track that you choose and raise | raise the percentage, or halt the rollout if the crash reports climb |
| App Store | a **phased release** over seven days, in steps Apple fixes | pause it, or release to everybody at once |

**A staged rollout is a test with real people**, and its value is in watching it: the crash and error reports of
the first days, from Play Console's vitals or Xcode's Organizer, against the version before. A bad update to 5%
of the people is a bad afternoon; to everybody, it is a week. *Neither store was used for this course.*

A store update also waits for review, and some people turn automatic updates off. **So an app should cope with
being old**: a planner `0.2.0` that opens data written by `0.3.0` should read it or say plainly that it cannot,
and never lose it. That is the same rule as the major number of semantic versioning, seen from the other side.

## Updates without the store

Lesson 9 showed the other kind for Expo: an update of the JavaScript alone, fetched by the app at start, with no
store in between. Capacitor apps have the same option through third-party services, Capgo among them, which
swap the `dist/` inside the installed app. **The store rules of lesson 9 apply to them unchanged**: an update may
fix and adjust what the reviewed app already does, and may not turn it into a different app. *None of these
services was used here.*

## Three systems, three machines

Lesson 13 said each desktop package is built on its own system. **A CI service with runners for all three does
that on every tag**, and GitHub Actions is the one most projects meet first. A workflow for the planner's
Electron packages, in `.github/workflows/release.yml`, would run on each tag that `npm version` makes:

```yaml
# .github/workflows/release.yml: build the desktop packages on each version tag.
name: release
on:
  push:
    tags: ["v*"]
jobs:
  desktop:
    strategy:
      matrix:
        os: [ubuntu-24.04, windows-2025, macos-15]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v5
        with:
          node-version: 22.22.0
      - run: npm ci
      - run: npm run build
      - run: npx electron-builder --publish never
      - uses: actions/upload-artifact@v5
        with:
          name: planner-${{ matrix.os }}
          path: release/*.*
```

**`matrix` runs the same job on three systems**, and each one builds the packages of its own: the AppImage and
the `.deb` on Ubuntu, the installer on Windows, the `.dmg` on the Mac. `--publish never` keeps electron-builder
from uploading anything itself; the packages land as the job's artifacts, to be checked before they are put
where the updater looks. The signing keys of lesson 14 would come in as the repository's secrets, in the
variables electron-builder reads for them, such as `CSC_LINK`.

*This workflow was not run: the planner has no repository on a CI service.* Pin each action to a full commit,
as the `actions/…@v5` tags here are only the short form: lesson 6 of `testing-cicd`, in its section "Actions, and pinning
them to a commit", explains why, and a workflow that signs releases is exactly where it matters.
