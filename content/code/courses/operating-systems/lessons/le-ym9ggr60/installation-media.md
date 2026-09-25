---
title: Making the installation USB and starting from it
version: 1
---

Windows is installed from a *USB stick* made with Microsoft's *Media Creation Tool*, which
downloads the current version and writes it to the stick. It needs a stick of at least **8 GB**, and it
erases everything on it. The same tool can instead save an **ISO** file, a disk image, which is what a
virtual machine (the virtualization course) boots from.

## Starting the computer from the stick

A computer normally starts from its internal disk. To start from the USB stick instead, you tell the
firmware, and there are two ways:

- *The boot menu*: a key pressed right after power-on, which shows a one-time list of devices to start
  from. The key depends on the maker, often *F12*, *F11*, *F9* or *Esc*, and the first screen
  usually says which.
- *The firmware settings*, where the permanent boot order lives. Useful when the boot menu key is
  disabled, and a place to be careful: changing the order and forgetting it makes the computer try the
  stick every morning.

If the stick does not appear in the list, the usual reasons are that it was made for the wrong kind of
firmware, or that the firmware is set to start only from internal disks. Leave **Secure Boot on**:
Microsoft's installer is signed, and switching it off to install Windows is never necessary.

## What happens next

The stick starts a small version of Windows, **Windows PE** (*Preinstallation Environment*), whose only
job is to run the installer. It asks for the language and the keyboard, for the product key (you can
skip it when the machine has a digital licence), and for the edition when the key does not decide it.
Then comes the question the next section is about: **where do you want to install Windows?**

The same stick has another use worth remembering. Its first screen has a **Repair your computer** link,
which opens the recovery tools of lesson 17 on a machine whose own recovery no longer starts.
