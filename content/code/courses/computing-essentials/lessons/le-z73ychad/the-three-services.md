---
title: The three services, and what each is actually built around
version: 1
---

They do the same job and they were designed by three companies with three different assumptions
about what a person is doing, and that assumption is the thing to know.

| | built around | the folder it syncs |
|---|---|---|
| **iCloud Drive** | *your devices*, and keeping them the same | optionally Desktop and Documents themselves |
| **OneDrive** | *your work account*, and the machine being replaceable | Desktop, Documents and Pictures, redirected |
| **Google Drive** | *the browser*, with the desktop app added later | a virtual drive, or a mirrored folder |

## What each one does that the others do not

**iCloud** is the only one that syncs things that are not files: messages, passwords, health data,
the arrangement of a home screen. Its *Desktop and Documents* option is genuinely useful and
genuinely surprising, because turning it on **moves** those folders into iCloud — and turning it
off later leaves them in iCloud and gives the Mac empty ones, which is the single most alarming
five minutes this service produces.

**OneDrive** has *Known Folder Move*, which does the same redirection on Windows, and it is what
most companies turn on for everybody. It is the reason a new work laptop can be signed into and
be *your* machine twenty minutes later.

**Google Drive** offers two modes and the difference matters: **streaming** puts a virtual drive
on the machine with nothing stored locally until opened, and **mirroring** keeps a full copy of a
chosen folder. Streaming is the default and it is the one that fails on an aeroplane.

## What they cost, honestly

The free tiers are `5 GB` for iCloud, `5 GB` for OneDrive and `15 GB` for Drive, and the last one
is shared with Gmail and Photos, which is the subject of the space section.

Paid tiers are all roughly the same price per terabyte, and all three bundle things you may
already be paying for — Office with OneDrive, extra features with the others. **The comparison
that matters is not price. It is which ecosystem your machines and your colleagues are already
in**, because the cost of being the only person on a different one is paid in every shared folder.

## The one thing to check in all three

**Where the folder actually is on the disk.** All three can be pointed at a different location,
and all three default to somewhere inside the home folder — which means lesson eight's backup of
the home folder is already backing up a placeholder version of everything in them.

Two consequences:

- **Exclude the synced folder from the backup, or set it to keep files locally.** Backing up
  placeholders is backing up nothing; backing up the full contents duplicates what is already
  offsite. Either is defensible; the accident is not knowing which you have.
- **A second account's folder is a second folder.** Signing into a work OneDrive and a personal
  one produces two folders, two quotas and two sets of rules, and files moved between them by
  dragging are *copied out of one and into the other*, with whatever sharing that implies.
