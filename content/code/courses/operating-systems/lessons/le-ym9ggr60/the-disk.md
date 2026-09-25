---
title: The disk: partitions, and what "clean" erases
version: 1
---

**A partition is a slice of a disk that the system treats as a separate area.** On a computer with
UEFI firmware, Windows Setup divides the disk it installs to into four:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A disk drawn as a bar split into four partitions, as Windows Setup creates them on a UEFI computer. First the EFI system partition, 100 MB, FAT32, holding the boot loader. Then the MSR, 16 MB, reserved and empty. Then the Windows partition, the rest of the disk, NTFS, drive C:, holding the system, the programs and the files. Last, a Recovery partition of about 1 GB holding WinRE, used for repairs. Only C: is shown in File Explorer.\"><defs><marker id=\"lo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one disk, GPT</text><rect x=\"20\" y=\"36\" width=\"90\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"65.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">EFI system</text><text x=\"65.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 MB, FAT32</text><rect x=\"112\" y=\"36\" width=\"60\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"142.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MSR</text><text x=\"142.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 MB</text><rect x=\"174\" y=\"36\" width=\"420\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"384.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Windows (C:)</text><text x=\"384.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rest, NTFS</text><rect x=\"596\" y=\"36\" width=\"104\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"648.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Recovery</text><text x=\"648.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">about 1 GB</text><path d=\"M65.0 98 L65.0 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the boot loader</text><path d=\"M142.0 98 L142.0 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"142.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reserved, empty</text><path d=\"M384.0 98 L384.0 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"384.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the system, programs, your files</text><path d=\"M648.0 98 L648.0 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"648.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">WinRE, for repairs</text><rect x=\"20\" y=\"182\" width=\"28\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"58\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dashed: hidden from File Explorer</text></svg>", "caption": "Four partitions, and File Explorer shows one. Deleting the other three to \"free space\" is how a PC stops starting."}
```

- *EFI system partition*: small, formatted in FAT32 so the firmware can read it, and holding the
  boot loader from lesson 1. Every system on the machine keeps its boot loader here.
- *MSR* (*Microsoft Reserved*): a few megabytes Windows keeps for itself. It contains nothing you
  will ever look at.
- *Windows*: drive C:, formatted in *NTFS*, Windows's own filesystem. The system, the
  programs and the users' files all live here.
- *Recovery*: the *Windows Recovery Environment* (WinRE), a small repair system that starts when
  Windows cannot. Lesson 17 uses it.

The disk itself uses a partition table called **GPT**, which UEFI requires. Older computers used
**MBR**, which is limited to disks of 2 TB, and you will still meet it on old machines and USB sticks.

## The screen that decides

*Where do you want to install Windows?* lists every partition on every disk. To install cleanly on a
disk that had Windows before, you **delete each partition on that disk** until it shows as one area of
*unallocated space*, select it and press Next; Setup creates the four above by itself.

That is the moment data is lost, and it is lost without further warning. Three habits prevent the
common accidents:

1. **Look at the sizes before deleting anything.** A computer with two disks shows both, and the
   second one often holds somebody's files.
2. **Unplug other drives** (external disks, second internal disks) when you can. Setup cannot delete
   what it cannot see.
3. **Never delete the small partitions of a working system** from inside Windows to "gain space".
   Without the EFI partition the machine has no boot loader, and without Recovery it has no repair
   tools. The figure's caption is not a joke.
