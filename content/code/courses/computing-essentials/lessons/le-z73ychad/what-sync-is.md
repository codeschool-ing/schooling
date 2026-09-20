---
title: What sync actually does, which is less than people assume
version: 1
---

A synced folder is **a folder that is also on a server, and also on every other device signed in
to the same account.** A file changes; the change is uploaded; the server pushes it to everything
else. That is the whole mechanism.

It is not a copy, not a backup and not a version of the file — it is **the same file, in several
places, kept identical.** Every consequence in this lesson comes from the word *identical*.

## The states a file can be in

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 302\" role=\"img\" aria-label=\"Five rows describing the states a file in a synced folder can be in. Online only: it takes no disk space and opening it needs a connection. Downloaded: it takes its full size and opens offline. Changed here: it takes its full size and is waiting to upload. Uploading: the same, with the change on its way. In conflict: two full copies on disk and nobody has decided which one is the file.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Five states, and only one of them is the one people picture</text><text x=\"44\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the state</text><text x=\"300\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it takes on the disk</text><text x=\"676\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what a connection is needed for</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">online only</text><text x=\"300\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing at all</text><text x=\"676\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">opening it</text><rect x=\"24\" y=\"102\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">downloaded</text><text x=\"300\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its full size</text><text x=\"676\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing</text><rect x=\"24\" y=\"142\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">changed here</text><text x=\"300\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its full size</text><text x=\"676\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sending the change</text><rect x=\"24\" y=\"182\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uploading</text><text x=\"300\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its full size</text><text x=\"676\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">finishing</text><rect x=\"24\" y=\"222\" width=\"672\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"44\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">in conflict</text><text x=\"300\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two full copies</text><text x=\"676\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a person, not a connection</text><text x=\"24\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A folder can hold all five at once, and the icon beside each name is the only place it says so.</text></svg>", "caption": "The third and fourth rows are why a folder that says it is synced can still be losing work when the machine is closed."}
```

**Files on demand** is the first row: the file's name and size are on your disk and its contents
are not, until you open it. That is how a `2 TB` account fits on a `256 GB` laptop, and it is on
by default in OneDrive and Drive and an option in iCloud.

It produces three effects worth knowing:

- **A folder can report 400 GB and use 4 GB.** Which is the thing lesson seven said to check
  before trusting a disk-space figure.
- **A backup tool may copy the placeholders**, which are a few kilobytes each, and produce a
  backup of nothing at all. Every backup tool now has a setting for this and it is not always
  right by default.
- **Opening a file with no connection fails**, on a file that is visibly there. *Always keep on
  this device* is the per-file or per-folder fix, and arranging it on the aeroplane does not work
  for the same reason as last lesson.

## The icon is the interface

Every service puts a small mark on each file and folder, and it is the only place the state is
written down:

| | roughly |
|---|---|
| a cloud outline | online only. Nothing on the disk |
| a green tick, hollow | downloaded and current |
| a green circle, filled | downloaded and pinned. It will not be evicted |
| two arrows in a circle | uploading or downloading now |
| a red cross or an exclamation | something is wrong. Usually a conflict or a quota |

**The two arrows are the one to watch.** Closing a laptop while a file is uploading does not lose
the change — it resumes — but closing it and then editing the same file elsewhere is exactly the
situation in the next section.

## And the sentence that surprises everybody

**Deleting a file deletes it everywhere, in seconds.** Including from the laptop in a bag,
including from your partner's machine if the folder is shared, and including on devices that will
never be asked about it.

There is a bin, and it holds deleted files for thirty days on all three services, and that is the
whole of the protection. A file deleted and emptied from the bin is gone from every copy of it
that existed — which is the exact opposite of what a backup does, and the reason the last section
of this lesson exists.
