---
title: Filesystem, a file of the plan
version: 1
---

**Filesystem reads and writes files in folders the system gives the app.** The planner's "Export plan"
writes the whole plan as JSON, then reads it back and reports its length, which is the shortest way to
know the file is really there:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Export plan' --wait 300 | tail -n 3
  - button "Export plan"
  - button "Where am I?"
  - status: exported 599 characters to planner-export.json
```

The `directory` option is the important one, because the same path means a different place in each:

| `Directory` | where it is | who can see it |
|---|---|---|
| `Data` | the app's private data folder | only the app; removed with it |
| `Cache` | a folder the system may empty | only the app |
| `Documents` | the user's documents; on iOS, the Files app can show it | the user, and other apps through the system |
| `External`, `ExternalStorage` | Android's shared storage | other apps, with permissions that differ by Android version |

**`Data` needs no permission on any platform**, which is why the planner uses it. Writing where other
apps can read is where the permission rules start, and the plugin's own documentation lists, per
Android version, which permission a folder needs. Most apps never need them: to hand a file to the
person, the usual way is to write it to `Cache` and open the system's share sheet with the
`@capacitor/share` plugin, which needs no storage permission at all.

## On the web it is not a folder

In Chromium, the export above went into **IndexedDB**, the browser's database, in one the plugin
calls `Disc`. There is no file anywhere on the disk with that name, and nothing outside the page can
open it. The call worked, the length was right, and that is all the web can show: the behaviour that
matters on a phone, that the file is in a folder and survives an update of the app, was not part of
this run.
