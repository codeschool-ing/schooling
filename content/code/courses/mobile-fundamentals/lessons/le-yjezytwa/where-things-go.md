---
title: Where each kind of file goes, and what the backup takes
version: 1
---

**The question that places a file is not "how big is it" but "if this file vanished tonight, could
the app make it again?"** If yes, it is a cache, and the system is welcome to delete it. If no, it
is the user's data, and it goes where the system will neither delete it nor forget to back it up.
Everything else in this section is that question asked of the folders each platform offers.

## The folders, by name

| | Android | iOS |
|---|---|---|
| the app's own data, kept and backed up | `filesDir`, the databases folder, shared preferences | `Library/Application Support` |
| documents the user made and may see | shared storage, through the system's pickers | `Documents`, which the backup takes |
| kept, but not backed up | `noBackupFilesDir` | a file in Application Support marked `isExcludedFromBackup` |
| a cache the system may delete | `cacheDir` | `Library/Caches` |
| scratch space for a moment | `cacheDir` too | `tmp` |

The rows come from Android's guides to app-specific storage and to Auto Backup, and from Apple's file
system guide and its article on optimising an app's data for iCloud Backup, all read on 30 October
2026. The fragments below get the two most used folders on each platform, adapted from the same
pages and from the documentation of `expo-file-system`; **they were not compiled or run for this
course**:

```kotlin
val plan = File(context.filesDir, "plan.json")      // kept, backed up
val week = File(context.cacheDir, "week.json")      // may be deleted when space is low
```

```swift
let plan = URL.applicationSupportDirectory.appending(path: "plan.json") // kept, backed up
let week = URL.cachesDirectory.appending(path: "week.json")             // may be purged
```

```tsx
import { File, Paths } from "expo-file-system";

const plan = new File(Paths.document, "plan.json"); // kept, backed up
const week = new File(Paths.cache, "week.json");    // may be deleted by the system
```

## What the backup takes, and when

**On Android, Auto Backup copies an app's data to the user's Google Drive** for any app that targets
Android 6 or later, unless the app turns it off. By default it takes shared preferences, the files
in `filesDir`, and the databases; it always leaves out `cacheDir` and `noBackupFilesDir`. The limit
is **25 MB per app**, and an app over it is simply not backed up. The backup runs when at least 24
hours have passed since the last one, the device is idle and on Wi-Fi, which the documentation says
is roughly every night in practice.

**On iOS, iCloud Backup takes the app's container except the folders the system may purge**:
`Library/Caches` and `tmp` are excluded by default. Apple's article asks for the reverse discipline
as well, because a backup that carries megabytes of thumbnails the app could rebuild is slower for
the user and uses their iCloud space for nothing.

**The backup is also how data comes back**, and that has a consequence people meet the hard way. A
file that identifies *this* phone does not belong on the next one. Android's Auto Backup guide gives
the example: Firebase Cloud Messaging makes a new registration token on every new device, the token
that push messages are addressed to in lesson 17, and if the old one is restored the app may behave
unexpectedly. That kind of file belongs in the "kept, but not backed up" row.

## The planner's files, placed

| file | could the app make it again? | where |
|---|---|---|
| `planner.db`, the courses and sessions | no: the student typed them | the app's data folder, backed up |
| `prefs.json`, the tab and the theme | no, but losing it costs a tap | preferences, backed up |
| `week.json`, the copy of the server's answer | yes: ask the server | the cache |
| the sign-in token | yes, by signing in again, and it must not travel | the Keychain or the Keystore |

**The cache row is the one lesson 14 left open.** Its `screen.ts` kept the server's week in a file
beside the program. On a phone that copy goes in the cache: losing it costs one request, and the
screen already knows what to say when there is no copy at all. The `mobile-offline` course gives the
whole sandbox its lesson 1, and the cache, with how large it may grow, its lesson 17.
