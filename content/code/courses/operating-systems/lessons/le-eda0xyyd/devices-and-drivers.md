---
title: Devices and drivers
version: 1
---

A keyboard, a printer, a disk, a network card: each one speaks its own language, set by whoever made
it. The kernel cannot know all of them, so each device comes with a **driver**, a piece of code that
translates between the kernel's general requests (*write these bytes*) and that device's specifics.

Drivers are why a new printer needs *something installed* before it works, and why an old scanner
can stop working after a system upgrade: its driver was written for the old kernel and nobody wrote
a new one. Lesson 16 is about exactly that.

## Devices as files, on Linux

Linux (and macOS, which shares the idea from Unix) shows devices as special files in `/dev`:

```
ana@server:~/office$ ls /dev | head -12
char
fd
full
hugepages
initctl
log
mqueue
net
null
ptmx
pts
random
ana@server:~/office$ ls -l /dev/null /dev/tty
crw-rw-rw- 1 root root 1, 3 Sep 25 09:59 /dev/null
crw-rw-rw- 1 root root 5, 0 Sep 25 09:59 /dev/tty
```

The `c` at the start of the permissions means *character device*: something read and written as a
stream of bytes. `/dev/null` is a device that swallows everything written to it; `/dev/tty` is the
terminal you are typing into. A disk would appear as a *block device*, with a `b`. The point is not
the names. It is that a program can write to a device with the same `write` it used on a file in the
last section, and the driver does the rest.

The list here is short because this is a server with no screen, printer or sound. On a desktop,
`/dev` also holds the disks, the webcam and the sound card.

## Devices on Windows

Windows does not show devices as files. It shows them in **Device Manager**, grouped by kind, each
with its driver's name and version. A yellow warning triangle on a device means its driver is
missing or failed to start, and it is usually the first place to look when a device *is plugged in
and does nothing*. The tool on macOS is **System Information**, where drivers are called *kernel
extensions*, and Apple has been moving them out of the kernel for safety.

## Why this matters for support

Most "it stopped working" calls about hardware are really about drivers: missing after a
reinstallation, replaced by a generic one by an update, or incompatible with a new system version.
Knowing that the device, the driver and the kernel are three different things is what lets you ask
the right question first.
