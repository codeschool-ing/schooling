---
title: macOS Recovery: the installer is already inside
version: 1
---

On Windows and Linux the first step was a USB stick. On a Mac it usually is not, because **every Mac
carries a small second system for repairs**, called *macOS Recovery*, in its own part of the disk.
From it you can reinstall macOS, erase or repair the disk, and restore from a backup.

## Getting there

**Apple silicon.** Shut the Mac down. Press the power button and **keep holding it** until *Loading
startup options* appears. Choose *Options*, then *Continue*. The same screen lists every disk the
Mac can start from, which is how you choose a USB installer too.

**Intel.** Turn the Mac on and immediately hold one of these until the Apple logo appears:

| keys | what Recovery installs |
|---|---|
| **Command-R** | the macOS that was last installed on this Mac |
| **Option-Command-R** | the latest macOS this Mac supports, downloaded |
| **Shift-Option-Command-R** | the one that came with the Mac, or the closest still available |

The last two are **Internet Recovery**: the Mac downloads the recovery system from Apple before it
starts. It needs a network, and it works when the disk itself is empty or new.

## What is on the Recovery screen

A short list of utilities: *Reinstall macOS*, *Disk Utility*, *Restore from Time Machine*, and
*Safari* for reading instructions. Terminal is in the *Utilities* menu. You will need Recovery again
in lesson 17, when a Mac does not start, and it is the same screen.

## When you do want a stick

Some jobs want a bootable installer anyway: many Macs to install and a slow connection, or a Mac whose
Recovery is damaged. It is made from another Mac, in Terminal:

```sh
softwareupdate --list-full-installers     # the versions Apple offers this Mac
softwareupdate --fetch-full-installer     # downloads "Install macOS …" into /Applications
sudo "/Applications/Install macOS Tahoe.app/Contents/Resources/createinstallmedia" \
     --volume /Volumes/Untitled           # erases the stick and makes it an installer
```

**None of these were run for this lesson.** `createinstallmedia` **erases the whole stick**, like `dd`
in lesson 3. It asks once, naming the volume, and that question is the moment to read the name after
`--volume`.

A Mac with Apple silicon that cannot start even into Recovery can be **revived** from a second Mac
with Apple's *Apple Configurator* and a USB-C cable. That is rare, and it is the one repair that needs
another Mac in the room.
