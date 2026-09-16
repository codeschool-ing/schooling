---
title: What is actually being bundled
version: 1
---

Lesson 1 said "Linux" is the kernel and nothing else. That leaves a question it did not answer:
if the kernel is one program, what are Ubuntu, Debian, Rocky and Alpine?

**They are bundles.** Each one takes the same kernel and wraps four more things around it, and
every difference you will ever meet between two distributions is a difference in one of the four.

## The four things

| | what it is | why it differs |
|---|---|---|
| **the kernel** | the program lesson 1 described | version, and which patches were applied |
| **the userland** | `ls`, `grep`, `bash` — the commands | GNU on most, **busybox** on Alpine |
| **the package manager** | how software arrives — section 15 of lesson 1 | `apt`, `dnf`, `zypper`, `apk` |
| **defaults and policy** | which services start, where files go, how long it is supported | almost everything else |

The first two are mostly the same everywhere, which is why this course works at all. **The last two
are the whole of what distinguishes one distribution from another**, and the fourth is bigger than
the third.

## Policy is the invisible one

"Defaults and policy" sounds like the soft category. It is the one that decides what a machine is
like to live with:

- **How new is the software?** Debian ships versions that are years old and very well tested.
  Arch ships what was released this week. Neither is wrong; they are answers to different
  questions, and section 08 is about the trade.
- **How long is it supported?** Five years, ten years, or until the next release six months from
  now. Section 09 is about what happens when that window closes.
- **What is on by default?** A firewall, or not. SELinux enforcing, or AppArmor, or nothing.
- **Where do files go?** Mostly the same — the standard of lesson 1 section 13 — and not entirely.
  Apache's configuration is `/etc/apache2` on Debian and `/etc/httpd` on Red Hat.
- **Who decides?** A company with a support contract, or a volunteer project with a constitution.
  That is not a technical fact and it is the one that matters for a ten-year deployment.

## What a distribution is not

**It is not a different operating system.** A program compiled for one usually runs on another.
The kernel interface is the same, the commands are the same, the filesystem is the same. Somebody
who knows Ubuntu is not a beginner on Rocky; they are somebody who has to look up two commands.

**And it is not a fork of Linux.** All of them ship essentially the same kernel, from the same
place, with their own patches and their own version. There is no "Ubuntu Linux" separate from
"Red Hat Linux" at the kernel level — there is one kernel and a hundred ways of packaging the
things around it.

## Why there are so many

Because bundling is cheap and disagreeing is free. Anybody can take the kernel, pick a userland,
choose a package manager, decide on a policy, and publish the result. Most such attempts go
nowhere. A handful became the families of the next section, and **the ones that lasted did so by
being maintained, not by being clever.**

Which is the practical filter when somebody suggests a distribution you have never heard of: not
"is it good", but *who is going to be publishing its security updates in four years.*
