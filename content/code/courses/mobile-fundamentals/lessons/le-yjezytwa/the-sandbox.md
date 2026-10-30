---
title: The sandbox, and what lives in it
version: 1
---

**On a laptop a program can read most of your files: your documents, another program's settings,
the folder you downloaded yesterday.** A phone does not work like that, and it is the first thing
about storage worth unlearning. Every app is installed into a folder of its own, its *sandbox*, and
the system lets it read and write there and almost nowhere else. Another app cannot open the
planner's files, and the planner cannot open theirs.

Three consequences follow, and each one shapes a decision later in this lesson:

- **Nothing else can read it.** Android's documentation on app-specific storage, as read on 30
  October 2026, says it plainly: other apps cannot access files stored within internal storage. That
  makes the sandbox the right place for the student's plan, and the wrong place for a photo they
  expect to see in their gallery.
- **It goes when the app goes.** Uninstalling an app removes its sandbox, on both platforms. A file
  the user would want to keep after deleting the app, a photo or an exported PDF, belongs in shared
  storage, through the system's own pickers, which is what the courses after the fork teach.
- **It is not one undivided folder.** Inside it the system has opinions about each part: which one
  is copied to the user's cloud backup, and which one it may empty on its own when the disk runs
  low.

## The folders, and the system's opinion of each

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-sandbox\" aria-label=\"Two sandboxes side by side. Android, the app's own folder: files and databases and shared preferences, kept and backed up by Auto Backup; no_backup, kept and not backed up; cache, not backed up, and the system may delete it when storage is low. iOS, the app's container: Documents, the user's documents, kept and backed up; Library, Application Support, kept and backed up; Library, Caches, not backed up, and the system may purge it; tmp, not backed up, purged when the app is not running. Other apps cannot reach into either.\"><rect x=\"14\" y=\"30\" width=\"336\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"370\" y=\"30\" width=\"336\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">Android: the app's own folder</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">iOS: the app's container</text><rect x=\"26\" y=\"44\" width=\"312\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files/</text><text x=\"38\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">databases/</text><text x=\"38\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shared_prefs/</text><text x=\"330\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept · backed up</text><rect x=\"26\" y=\"112\" width=\"312\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">no_backup/</text><text x=\"330\" y=\"127.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept · not backed up</text><rect x=\"26\" y=\"152\" width=\"312\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cache/</text><text x=\"330\" y=\"167.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">may be deleted by the system</text><rect x=\"382\" y=\"44\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Documents/</text><text x=\"686\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept · backed up</text><rect x=\"382\" y=\"90\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Library/Application Support/</text><text x=\"686\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept · backed up</text><rect x=\"382\" y=\"136\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Library/Caches/</text><text x=\"686\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">may be deleted by the system</text><rect x=\"382\" y=\"182\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tmp/</text><text x=\"686\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">may be deleted by the system</text><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">other apps cannot reach in</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">all of it goes when the app is uninstalled</text></svg>", "caption": "The same three promises in two spellings: kept and backed up, kept and not backed up, and a cache the system may empty on its own."}
```

**The two platforms name their folders differently and agree on the idea.** There is a place for
the app's own data, which the backup takes, and a place for a cache, which the backup skips and the
system may delete. iOS adds a place for documents the user made, which the Files app can show them if
the app allows it. Apple's file system guide says of `tmp/` that the system may
purge it when the app is not running, and Android's documentation says the same of `cacheDir` when
the device is low on storage.

**"The system may delete it" is the line that decides where a file goes.** Put the student's study
plan in the cache and it works perfectly for weeks, through every test, until the day the phone is
nearly full and the system clears caches to make room. Nothing fails. The plan is simply empty, and
it looks exactly like a plan nobody has written yet. That is the reason the next section is a table
of what goes where, and why it starts from the question *could the app make this again?*

## What the planner keeps

The planner has four kinds of thing to store, and each one lands somewhere different:

| what | an example | where it goes |
|---|---|---|
| the student's data | courses and sessions | a database, in the app's own data folder |
| small settings | the last tab open, a theme | preferences |
| something fetched that can be fetched again | the week, as the server sent it in lesson 14 | the cache |
| a secret | the token that signs the student in | the Keychain or the Keystore, never a file |

The rest of this lesson takes them in that order, with a file on your computer standing in for each
one. Your `~/planner` folder plays the part of the sandbox: a folder that belongs to one program and
that nothing else reads.
