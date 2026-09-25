---
title: Safe mode and recovery, on all three
version: 1
---

## Windows

- **Safe mode**: hold **Shift** while choosing *Restart*, then *Troubleshoot > Advanced options > Startup
  Settings > Restart*, and press **4**. Only basic drivers and services load. If the problem disappears,
  it is a driver, a service or a startup program, lesson 14's lists.
- **WinRE**, the Windows Recovery Environment, is the menu that path passes through, and it also starts
  on its own after two failed starts in a row. It offers **Startup Repair**, **System Restore** (lesson
  15's restore points), **Uninstall Updates**, a **Command Prompt** and **Reset this PC** from lesson 2.
  Lesson 2's installation stick starts the same environment when the disk's copy is damaged.

## macOS

- **Safe mode**: on Apple silicon, start into the startup options (lesson 4), select the disk, hold
  **Shift** and choose *Continue in Safe Mode*; on Intel, hold **Shift** at start. It checks the disk and
  loads only what is needed.
- **Recovery**, lesson 4: *Disk Utility > First Aid* checks and repairs the disk, and *Reinstall macOS*
  keeps the data.
- **Console**, in *Applications > Utilities*, is the log viewer, and `log` is the command:

```sh
log show --last 1h --predicate 'eventMessage CONTAINS "error"' | tail
log stream --process Finder                      # like tail -f, for one process
```

**Not run for this lesson.**

## Linux

- **Recovery mode**: in GRUB's *Advanced options*, each kernel has a recovery entry that starts with
  almost nothing and offers a root shell. Keeping **the previous kernel** in that menu is what makes a
  bad kernel update a restart away from fixed.
- **`rescue.target`** and **`emergency.target`**, systemd's minimal modes, are what recovery mode uses:
  the first mounts the disks and starts almost no services, the second not even that.
- **Lesson 3's live USB** starts a whole Linux from the stick, from which a broken installation's disk
  can be mounted, checked with **`fsck`**, and its files copied off.

## The rule for all three

**Before repairing anything in recovery, copy off what matters**, if the disk still reads. A repair that
fails can leave less than was there before it started.
