---
title: When two devices disagree, and why nobody can fix it
version: 1
---

Sync keeps copies identical by carrying changes between them. That works as long as changes
arrive one at a time. When two arrive from different places, describing different versions of the
same file, **there is no correct answer** — the service cannot know which of two human intentions
should win.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"Three numbered steps describing how a conflict happens: the laptop goes offline with the file open, the file is edited on the desktop as well, and then the laptop reconnects. Below, three rows name what each service does about it: OneDrive keeps both and marks one with the device name, Drive keeps both as separate versions, and iCloud keeps both and appends a number. A note says none of the three merges anything.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">One file, two devices, and nobody is wrong</text><text x=\"44\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1</text><text x=\"70\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the laptop goes offline with the file open</text><text x=\"44\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">2</text><text x=\"70\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the same file is edited on the desktop</text><text x=\"44\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3</text><text x=\"70\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the laptop reconnects</text><path d=\"M24 158 L696 158\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"24\" y=\"176\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">OneDrive</text><text x=\"676\" y=\"191\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">both kept, one marked with the device name</text><rect x=\"24\" y=\"214\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Drive</text><text x=\"676\" y=\"229\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">both kept, as separate versions of one file</text><rect x=\"24\" y=\"252\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"267\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">iCloud</text><text x=\"676\" y=\"267\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">both kept, with a number added to one name</text><text x=\"24\" y=\"304\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">None of the three merges anything. All three hand you two files and the decision.</text></svg>", "caption": "The only arrangement that avoids this is editing in one place at a time, or not having a file at all — which is what the last lesson's documents are."}
```

## What you get, and what to do with it

All three hand you **two files and the decision.** The names differ — `report (Ana's MacBook).docx`,
`report (1).docx`, a second version in the history — and the substance does not.

The mistake is to open the newer one, decide it looks right, and delete the other. **The older
one may hold an hour of work the newer one never had**, because it was edited on the device that
was offline. Open both. It takes two minutes and it is the only way to know.

For a Word or Excel file, *Compare* in the Review tab does this properly and produces a marked-up
document showing every difference. It is the most useful feature in Office that nobody knows is
there.

## Why it happens more than it should

- **A file left open in an application.** Word, Excel and most editors hold the file and write it
  back when you save, so a document open on two machines is a conflict waiting for the second
  save. Closing the file is what ends it, not closing the laptop lid.
- **A machine that sleeps rather than syncs.** The change is queued and sent on wake, which may
  be after somebody else has edited.
- **Two people in one shared folder.** The commonest version at work, and the reason the previous
  lesson exists: a document on a server has no files to conflict.

## The rule

**A file is edited in one place at a time, or it should not be a file.**

If two people genuinely need to work on something at once, it belongs in Docs or in the web
version of Office — where there is one copy and the editing is merged as it happens. Sync is for
carrying a file between *your own* devices, and it is very good at that.

## And the one that is worse than a conflict

Some file types cannot be conflicted safely at all, because they are **one file holding a
database**: an Outlook `.pst`, a QuickBooks company file, an Access database, a photo library.
Two machines writing to one of those over sync does not produce two copies — it can produce one
corrupt copy.

**Do not put a live database file in a synced folder.** Every service says so in a support page
nobody reads, and the failure is the only one in this lesson that loses everything rather than
making a mess.
