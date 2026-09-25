---
title: Five things before anybody uses it
version: 1
---

The same idea as lesson 2's list, with the Mac's names:

1. **Updates.** *System Settings > General > Software Update*, until it says the Mac is up to date,
   and turn on **automatic updates** in the same place. The first round after an erase can take more
   than one pass.
2. **FileVault on.** If it was skipped in Setup Assistant: *System Settings > Privacy & Security >
   FileVault*. Record the recovery key.
3. **A name.** *System Settings > General > Sharing*, at the bottom, sets the **local hostname**, which
   is how the Mac appears on the network. `OFFICE-MAC-01`, not *Ana's MacBook Pro*.
4. **The firewall.** macOS ships with it *off*. *System Settings > Network > Firewall*. On a laptop
   that joins café Wi-Fi it belongs on.
5. **A backup.** **Time Machine**, in *System Settings > General*, to an external disk or a network
   share. It keeps hourly copies for a day and daily ones for a month, and it is what *Restore from
   Time Machine* in Recovery reads.

The same from Terminal, for when there are several Macs:

```sh
softwareupdate --list                             # what is waiting
sudo softwareupdate --install --all --restart     # install it all, restart if needed
fdesetup status                                   # "FileVault is On." or Off
sudo scutil --set ComputerName "OFFICE-MAC-01"    # the name people see
sudo scutil --set LocalHostName "OFFICE-MAC-01"   # the name on the network (.local)
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

**None of these were run for this lesson.** Two of the Mac's names differ on purpose: *ComputerName* is
what people see in Finder, and *LocalHostName* is what the network uses, with `.local` added.

## Many Macs

A company with fifty Macs does not do any of this by hand. It uses *Apple Business Manager* with a
*device management* service (*MDM*): Macs bought through the company's account are registered to it
from the factory. When a new one first joins Wi-Fi, Setup Assistant enrols it, applies the
settings, turns on FileVault and stores the recovery key centrally. **Activation Lock is then managed
by the organisation**, not by whoever unpacked the Mac. It is lesson 2's Autopilot with Apple's name
on it, and it asks the same questions once rather than at every desk.
