---
title: Installing beside Windows
version: 1
---

A computer can keep Windows and add Linux on the same disk, choosing between them at every start. This
is called **dual boot**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 176\" role=\"img\" aria-label=\"A disk with Windows and Ubuntu installed side by side. From left to right: the EFI partition, shared, holding both boot loaders, Windows Boot Manager and GRUB; the MSR; the Windows partition C:, NTFS, which was shrunk first from inside Windows; the Recovery partition; and the Ubuntu partition, mounted as /, formatted ext4, with a swap file inside it. GRUB starts first and offers a menu of both systems.\"><defs><marker id=\"db-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one disk, two systems</text><rect x=\"20\" y=\"36\" width=\"60\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">EFI</text><text x=\"50.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shared</text><rect x=\"84\" y=\"36\" width=\"44\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"106.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MSR</text><rect x=\"132\" y=\"36\" width=\"250\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"257.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Windows (C:)</text><text x=\"257.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NTFS, shrunk first</text><rect x=\"386\" y=\"36\" width=\"90\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"431.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Recovery</text><rect x=\"480\" y=\"36\" width=\"220\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Ubuntu (/)</text><text x=\"590.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ext4, swap file inside</text><path d=\"M50 96 L50 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">holds both boot loaders: Windows Boot Manager and GRUB</text><text x=\"50\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">GRUB starts first and offers a menu</text><path d=\"M370 100 C420 130 520 130 580 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#db-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"480\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">space taken from C:, from inside Windows</text></svg>", "caption": "Ubuntu takes space Windows gave up, and shares its EFI partition. Nothing of Windows is erased, which is exactly why the steps before installing matter."}
```

Linux needs space that Windows is using, and three things must happen **from inside Windows, before the
installer runs**:

1. **Suspend BitLocker** (lesson 2) and have the recovery key at hand. Changing the partitions can make
   Windows ask for the key at its next start.
2. **Shrink C:** in Windows's *Disk Management*: right-click the partition, *Shrink Volume*. Windows knows
   which parts of its partition are in use; letting Windows do it is safer than letting another tool
   guess.
3. **Turn off Fast Startup** (*Control Panel > Power Options*). With it on, "shutting down" Windows is
   really a kind of hibernation that leaves its partition locked, and Linux can then only read it, not
   write to it.

After installing, the computer starts **GRUB**, Linux's boot loader, which shows a menu with both
systems. Both boot loaders live side by side in the shared EFI partition from lesson 2.

## The clock that is three hours wrong

The first thing people notice after setting up dual boot is the clock. The computer has a hardware
clock, and the two systems disagree about what it holds: **Windows stores local time in it, Linux stores
UTC**. In São Paulo that is a three-hour difference, and each system "fixes" the clock after the other
has used it.

`timedatectl` shows how Linux sees it:

```
ana@server:~$ timedatectl
               Local time: Fri 2026-09-25 13:11:43 UTC
           Universal time: Fri 2026-09-25 13:11:43 UTC
                 RTC time: n/a
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: no
              NTP service: inactive
          RTC in local TZ: no
```

This transcript comes from a virtual machine that borrows its clock from the computer running it, so it
has no hardware clock of its own: `RTC time: n/a`, and no time synchronisation of its own either. On a
real PC the line shows the hardware clock, and `RTC in local TZ: no` is the Linux habit. The usual fix
for dual boot is to tell Linux to do what Windows does:

```sh
timedatectl set-local-rtc 1    # tell Linux the hardware clock keeps local time, as Windows does
```

**Not run here**, since this machine has no hardware clock to change.
