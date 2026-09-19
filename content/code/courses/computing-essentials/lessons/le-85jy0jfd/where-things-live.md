---
title: Where things actually live, and the folder that is not a place
version: 1
---

Every system puts the same handful of things in roughly the same handful of places, and knowing
which is which turns "somewhere on the computer" into an address.

| | Windows | macOS | Linux |
|---|---|---|---|
| **your things** | `C:\Users\ana` | `/Users/ana` | `/home/ana` |
| **installed programs** | `C:\Program Files` | `/Applications` | `/usr/bin` and others |
| **the system** | `C:\Windows` | `/System` | `/etc`, `/var`, `/usr` |
| **settings, per user** | `AppData` | `~/Library` | `~/.config` |
| **temporary rubbish** | `C:\Users\ana\AppData\Local\Temp` | `/tmp` | `/tmp` |

**The home folder is the only one that is yours**, and it is the only one that has to be backed
up. Everything else is either reinstallable or is the operating system, and both come back from
an installer.

## The Desktop is a folder

This surprises people and it is worth a paragraph. **The desktop is not a special surface. It is
a folder** — `C:\Users\ana\Desktop` — and the background of your screen is a window showing its
contents.

Which means: files on the desktop are in the home folder and are backed up like anything else;
a desktop with four hundred items is a folder with four hundred items and it loads slowly; and
tidying the desktop is moving files between folders, nothing more.

## Downloads, and the folder everybody uses as a filing cabinet

`Downloads` is where a browser puts things, and it is the folder most people's important
documents actually live in. It is also the folder most likely to be emptied by a cleanup tool, and
the one where a file named `document(3).pdf` is impossible to identify.

**Treat it as an inbox rather than a drawer.** Everything in it is either processed into
somewhere with a name or deleted. That habit is the single largest tidiness gain available, and it
costs about a minute a week.

## Hidden files, and why they are hidden

A file whose name starts with a dot — `.config`, `.ssh` — is hidden on macOS and Linux. On
Windows hiding is a flag on the file rather than a naming convention.

They are hidden because they are settings that programs manage, not because they are secret. You
can show them — `Ctrl+H` on Linux, `Cmd+Shift+.` on macOS, a checkbox on Windows — and you should
know they exist, because **a backup that skips hidden files skips every program's settings.**

## AppData, Library and the one thing to take from them

When a program remembers something — your preferences, your logins, a half-finished document —
it does not keep it beside the program. It keeps it in your home folder, in one of those
settings directories.

**So the useful rule is: reinstalling a program does not reset it.** That is why a program that
is misbehaving is still misbehaving after a reinstall, and why deleting the settings folder is
the step that actually helps. It is also why backing up your home folder backs up far more than
your documents.
