---
title: Why an image, and not a copy of the files
version: 1
---

Lesson 12 left one question open that no log can answer: **which files were in the 612 MB** that left the file
server. The answer is on the server's disk, in what was there that night, what was read, and what was deleted
since. Getting it is forensics, and forensics starts with a rule that sounds fussy and is not: **nobody
examines the original.**

A **forensic image** is a copy of a disk **bit for bit**: every sector, from the first to the last, whether a
file uses it or not. That is the difference from copying the files:

| | copying the files | a forensic image |
|---|---|---|
| **files that exist** | yes | yes |
| **deleted files** whose data is still on the disk | no | yes |
| **free space**, and the leftovers in it | no | yes |
| **file system metadata**: times, owners, the journal | partly, and the copy changes some of it | yes, untouched |
| **can be proved identical** to the original | no | yes, by its hash |

The last row is the point. A hash of the whole disk taken before the copy, and the same hash of the image after
it, prove that the image is the disk, down to the last byte. **Every analysis then happens on a copy of the
image**, and anybody who doubts a finding can make their own copy from the stored image, check the hash, and
look for themselves.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"From left to right: the original disk, read through a write blocker, is copied into an image; a working copy is made from the image. The same SHA-256 hash is written under the disk, the image and the working copy. The original and the image are stored and never analysed; all analysis happens on the working copy.\"><rect x=\"10\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">original disk</text><text x=\"90.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stored, sealed</text><rect x=\"190\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">write blocker</text><text x=\"270.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads only</text><rect x=\"370\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">image</text><text x=\"450.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stored, never opened</text><rect x=\"550\" y=\"30\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">working copy</text><text x=\"630.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 17 opens this</text><path d=\"M170 60 L190 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190 60 L182.0 56.0 L182.0 64.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M350 60 L370 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 60 L362.0 56.0 L362.0 64.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 60 L550 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 60 L542.0 56.0 L542.0 64.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"90\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">same SHA-256</text><text x=\"450\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">same SHA-256</text><text x=\"630\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">same SHA-256</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same hash at every step is what makes the copy evidence</text></svg>", "caption": "One hash, three copies. Analysis touches only the last one."}
```

There are two ways to image a server. A **dead** acquisition switches it off and images the disk from another
machine; nothing on the disk changes while it is copied, and the memory is lost, which is why lesson 13 collects
the volatile state first and lesson 17 captures memory. A **live** acquisition images the disk while the server
runs, and the image is then a picture of a moving target: still valuable, and documented as such. For a
virtual machine, a snapshot of its disk file is the usual way, and the same hashing rules apply.
