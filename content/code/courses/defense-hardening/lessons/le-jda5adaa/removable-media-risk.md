---
title: The other port on every workstation
version: 1
---

**A USB socket is a network port that skips the network.** Everything the first half of this lesson
filtered travels over the network, past the switch of lesson 4 and the firewall of the last section.
A USB stick plugged into a workstation reaches the machine directly, and three different risks come
in through the same socket.

**Data walks out.** A stick holds more client records than anybody could email, and copying them
leaves no trace on the network. For an accounting firm holding tax documents and identity numbers
for every client, this is the one that ends in a letter to the data protection authority. Lesson 9
is about the data side of it; this lesson is about the socket.

**Malware walks in.** A file on a stick bypasses the mail filter and the web proxy. This is how
malware reaches networks that are not connected to the internet at all, and why the files on removable
media are the first thing endpoint protection scans, lesson 7's subject.

**The device lies about what it is.** A USB device announces its own class. Something that looks like
a stick can announce itself as a keyboard, and a keyboard is trusted to type: the operating system
accepts its keystrokes as the person at the desk. Defences against this one cannot rely on the file
system at all, because there is no file; they have to decide which devices may connect.

## What the controls decide

| control | what it decides | stops |
|---|---|---|
| no driver for USB storage | sticks and disks are not mounted at all | data out, files in; not a device posing as a keyboard |
| a device allow-list | only devices whose identity is on a list may connect | unknown devices of every class, if the list is exact |
| read-only storage | sticks may be read, not written | data out; not malware in |
| scanning on insertion | files are checked before they are opened | known malware in; nothing else |

As with lesson 2's Level 2 profile, the strongest setting costs a function. The reception desk takes
nothing on a stick. The person who receives a client's documents on one needs a path for them, and
the answer is a decision about that person's machine, written down, not an exception nobody records.

The next section builds the first two on Linux and names the Windows equivalents. The lab cannot
plug in a device, and that section says exactly where it stops.
