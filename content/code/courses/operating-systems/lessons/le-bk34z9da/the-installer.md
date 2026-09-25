---
title: The stick, the live session and the installer
version: 1
---

The ISO goes onto a USB stick with a tool that writes it whole: *Rufus* or *balenaEtcher* on Windows,
*balenaEtcher* on macOS, and on Linux the *Startup Disk Creator* or `dd`:

```sh
lsblk                                         # find the stick: its size tells you which it is
sudo dd if=ubuntu-24.04-desktop-amd64.iso of=/dev/sdX bs=4M status=progress
#                                             ^ the WHOLE stick, not a partition like sdX1
```

**That `dd` was not run for this lesson**, and it is the one command in this course to type slowly.
`of=` is the device it writes over, entirely and without asking. Pointed at the wrong letter, it erases a
disk instead of a stick; `lsblk` first, and read the sizes.

You start the computer from the stick exactly as in lesson 2: the boot menu key. Leave **Secure Boot on**.
Ubuntu's boot loader is signed with a key the firmware already trusts, so it starts normally.

## Try before installing

The stick starts a complete **live session**: Ubuntu running from the stick, without touching the disk.
It is worth ten minutes before installing, because it answers the questions that matter on real
hardware: does the Wi-Fi work, the screen resolution, the sound, the printer? If they do not work here,
they will not work after installing either, and it is better to know now.

## Choices the installer asks for

- *Language, keyboard and time zone.* For the office: Portuguese (Brazil) keyboard, and São Paulo time.
- *Installation type*, the one that deserves care:
  - *Erase disk and install Ubuntu*: the whole disk, like lesson 2's clean install.
  - *Install alongside Windows*: shares the disk, the next section.
  - *Manual installation*: you draw the partitions yourself.
- *Encryption.* The installer can encrypt the whole disk (**LUKS**) with a passphrase asked at every
  start. It is Linux's answer to BitLocker, and for a laptop that leaves the office it is not optional.
- *Proprietary drivers.* An option to install drivers that are not open source, mostly for graphics
  and Wi-Fi. With Secure Boot on, installing them may ask you to set a password and confirm it once,
  on a blue screen at the next start, called **MOK** enrolment. It looks alarming and is expected.
- *Your account.* Name, computer name and password. This first account can run administrator
  commands with `sudo` (section 05).
