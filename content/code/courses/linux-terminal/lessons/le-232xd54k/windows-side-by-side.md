---
title: The table, once
version: 1
---

Seventeen sections have each made one comparison in passing. This is the whole of it in one place,
to be read once and returned to — and then the course stops talking about Windows until lesson 10,
which gives PowerShell the serious treatment it deserves.

## The table

| | Linux | Windows |
|---|---|---|
| **path separator** | `/` | `\` |
| **where a path starts** | one tree at `/` | a drive letter — `C:`, `D:` |
| **a second disk** | mounted at a directory | gets its own letter |
| **case in filenames** | `a.txt` ≠ `A.txt` | the same file |
| **what makes a file run** | a permission bit | the `.exe` extension |
| **hidden files** | a name beginning with `.` | an attribute on the file |
| **line endings** | `LF` | `CRLF` |
| **machine configuration** | text files in `/etc` | the registry |
| **installing software** | a signed repository, one command | download and run an installer |
| **updating** | one command, no reboot | per-program, and reboots |
| **background programs** | daemons, run by systemd | services, run by the SCM |
| **administrator** | `root`, uid 0 — you ask with `sudo` | Administrator — you click Yes |
| **the shell** | bash — text in, text out | PowerShell — objects in, objects out |
| **logs** | text in `/var/log` | the Event Log, via its viewer |
| **remote access** | SSH, from the start | RDP, or SSH more recently |

## The four rows that are not just naming differences

Most of that table is two ways to spell one idea. Four rows are genuinely different ideas, and
they are the ones that change how you work.

**Configuration as text.** This is the largest one. Because `/etc` is text, every tool in lesson 8
administers this machine: you can `grep` the configuration, `diff` two machines, put `/etc` in
git, and send somebody a change as a patch. A binary registry can be edited, exported and scripted
— but not by the tools you already have, and not reviewed by a person reading a diff.

**Text as the interface between programs.** `|` is the subject of lesson 8 and the reason small
commands compose into anything. PowerShell answers the same problem by passing **objects**, which
is a real and arguably better answer — lesson 10 makes that case honestly rather than defending
this one. What matters here is that they are different answers, not different syntax.

**The permission bit, not the extension.** On Windows, `.exe` means runnable and renaming a file
changes what the system will do with it. On Linux, running is a bit in the mode, so a file called
`backup` with no extension runs and `virus.exe` sitting in your home directory does not —
section 11 and lesson 4.

**Updating without a reboot.** Section 15 already made the case. It is the reason the machines
running the internet run Linux, and it is not a preference.

## What actually transfers

You are not starting over on either side:

- **The ideas transfer completely.** Files, directories, processes, permissions, users, services
  and logs exist in both. You are learning a system, not a vocabulary.
- **The commands do not**, natively. Lesson 10 gives you the PowerShell equivalents and the traps
  — the aliases that make `ls` work there and then behave differently.
- **And WSL removes the question.** A real Linux beside Windows, where everything in this course
  applies unchanged. If you are on Windows, section 04 already had you install it.

## What this course does from here

It stops comparing. Everything after this section is Linux on its own terms, because the
comparison has done its job: you now know which of your habits transfer and which are Windows
habits you were treating as computing.

Lesson 10 is the one exception, and it is not a comparison — it is PowerShell taught as its own
thing, because a mixed shop is the normal shop and knowing one shell is knowing half your job.
