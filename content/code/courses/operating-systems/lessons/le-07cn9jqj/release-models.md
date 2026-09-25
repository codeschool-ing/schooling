---
title: Fixed releases and rolling ones
version: 1
---

Distributions differ in **how change arrives**, and it is the difference that matters most on a
machine somebody depends on.

## Fixed releases

Ubuntu, Debian, Fedora, RHEL and openSUSE Leap publish **numbered releases**. Inside one release,
the versions of the programs are **frozen**: the server's `bash` today is the same version of `bash`
it had on the day 24.04 came out, with security fixes applied to it. New features wait for the next
release, and moving to that release is a deliberate step, `do-release-upgrade` in lesson 3.

That is what makes a fixed release dependable. An ordinary update is there to close a hole or fix a
bug, not to change what a program does, and a script written in the first year still works in the
fifth.

## Rolling releases

**Arch**, **openSUSE Tumbleweed** and Debian's **sid** have **no releases at all**. Every package
moves to its newest version when it is ready, and an update can bring a new major version of anything
on any day. There is never an upgrade to do, because the system is always the latest.

That suits a developer's laptop, where the newest compiler matters and a breakage costs one person an
afternoon. It does not suit the office server, where nobody wants the file share's software to change
behaviour the week the accountant closes the year.

## Ubuntu's two kinds

Ubuntu publishes a release every **April and October**, numbered by year and month: 24.04 is April
2024. Every second April the release is an **LTS**, *long-term support*. The ones between are
**interim** releases, supported for **nine months**, and meant for trying what is coming.

Section 04 puts numbers on it, and the server can read them itself.
