---
title: APFS: one container, several volumes
version: 1
---

In lesson 2 Windows cut the disk into partitions, each with a fixed size. macOS formats the internal
disk with **APFS**, the *Apple File System*, and does it differently.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"An internal Mac disk drawn as one APFS container, a single pool of free space, holding five volumes. Macintosh HD, the system, sealed and read-only. Macintosh HD - Data, your files, apps and settings, where everything changes. Preboot, what starts the Mac. Recovery, the repair system. And VM, the swap. None of them has a fixed size; each takes space from the same pool as it needs it. Finder shows only one disk, Macintosh HD.\"><defs><marker id=\"ap-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the internal disk</text><rect x=\"20\" y=\"34\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one APFS container: one pool of free space</text><rect x=\"36\" y=\"70\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"111.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Macintosh HD</text><text x=\"111.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the system</text><text x=\"111.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sealed, read-only</text><rect x=\"196\" y=\"70\" width=\"190\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"291.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Macintosh HD - Data</text><text x=\"291.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your files, apps, settings</text><text x=\"291.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">where everything changes</text><rect x=\"396\" y=\"70\" width=\"92\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"442.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Preboot</text><text x=\"442.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what starts it</text><rect x=\"498\" y=\"70\" width=\"100\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"548.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Recovery</text><text x=\"548.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the repair system</text><rect x=\"608\" y=\"70\" width=\"76\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"646.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">VM</text><text x=\"646.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">swap</text><path d=\"M36 196 L386 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 190 L36 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M386 190 L386 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"211\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Finder shows one disk: Macintosh HD</text></svg>", "caption": "Unlike the Windows partitions in lesson 2, no volume has a size of its own. They share the container's free space, and Finder shows the first two as one disk."}
```

The disk holds an **APFS container**, and the container holds **volumes**. A volume looks like a disk in
Finder, but it has no size of its own: every volume takes space from the container's shared free space
as it needs it. Nobody has to guess in advance how big the system should be.

## Two volumes that look like one

The two that matter are these:

- **Macintosh HD** is the system. It is **sealed**: read-only, and checked against a signature from
  Apple every time the Mac starts. Nothing, not even an administrator, writes to it while macOS is
  running. An update replaces it whole.
- **Macintosh HD - Data** holds everything that changes: the users' folders, the apps they install,
  the settings.

Finder joins the two and shows one disk, **Macintosh HD**. That split is what makes the first option in
section 04 possible: macOS can be replaced without touching the data beside it.

## Encryption from the start

On Apple silicon, and on Intel Macs with the T2 security chip, the internal disk is **always
encrypted by the hardware**. What **FileVault** adds is that the key is locked behind a user's password,
so the disk cannot be read until somebody signs in. Section 05 turns it on.

This is also why erasing a modern Mac is fast. Destroying the key makes every byte on the disk
unreadable, so nothing has to be overwritten.

## Seeing it

**Disk Utility**, in *Applications > Utilities* and on the Recovery screen, shows the container and
its volumes; choose *View > Show All Devices* or it shows only the volumes. From Terminal:

```sh
diskutil list                            # every disk, container and volume
diskutil apfs list                       # the APFS containers, with shared free space
```

**Neither was run for this lesson.** An external disk for Windows and Mac alike is formatted
**exFAT**, which both read and write; an APFS disk is not readable on Windows without extra software.
