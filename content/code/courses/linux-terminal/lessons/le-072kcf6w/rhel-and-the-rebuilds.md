---
title: Red Hat, and what happened to CentOS
version: 1
---

This family is where enterprise Linux lives, and it is the one with a story — a story you need,
because the names changed recently enough that most of the documentation you will find is about a
world that no longer exists.

## Three positions, not three products

| | what it is | who pays |
|---|---|---|
| **Fedora** | upstream. New things land here first, released twice a year, supported about 13 months | nobody |
| **RHEL** | Red Hat Enterprise Linux. Ten-year support, certifications, a support contract | a subscription |
| **Rocky, Alma** | RHEL rebuilt from source, free, binary-compatible | nobody |

Read that as a pipeline: an idea proves itself in Fedora, is stabilised into RHEL, and RHEL is
rebuilt by others for people who want the compatibility without the contract.

## The story, briefly

**CentOS used to be the free RHEL.** For years, the answer to "I want RHEL but cannot pay for it"
was CentOS — a rebuild, version for version, released a few weeks behind. An enormous number of
servers ran it.

In late 2020 Red Hat ended that, and turned CentOS into **CentOS Stream**, which sits *upstream*
of RHEL rather than downstream. Stream is a preview of what the next RHEL minor release will
contain. It is a reasonable thing to exist, and it is **not** what the people running CentOS
wanted: they wanted the thing behind RHEL, not the thing in front of it.

**Rocky Linux and AlmaLinux were founded in response**, within months, both doing what CentOS had
done. Rocky was started by one of CentOS's own founders. Both are free, both track RHEL closely,
and both are what you should expect to meet on a server today where you would once have met
CentOS.

## Why this matters to you rather than being trivia

**Because you will read documentation that says CentOS and means Rocky or Alma.** Years of blog
posts, Stack Overflow answers and vendor instructions were written for CentOS 7 or 8. Almost all
of it applies unchanged — the commands are the same — but the names and the repository URLs are
not.

**And because CentOS 7 is out of support.** It ended in June 2024, and machines running it are
still out there receiving nothing. Section 09 is about what that means; here it is enough to
recognise the name as a warning rather than a neutral fact.

## What you actually type

The family's package manager is `dnf`, and `yum` is its older name — on current systems `yum` is
usually kept as a link to `dnf` so old instructions keep working:

| | |
|---|---|
| install | `sudo dnf install nginx` |
| update everything | `sudo dnf upgrade` |
| search | `dnf search nginx` |
| what package owns this file | `rpm -qf /path` |

Two habits from this family that differ from Debian's, and lesson 7 comes back to both:

- **`dnf` refreshes its metadata automatically.** There is no `apt update` step to forget.
- **Extra software often comes from EPEL** — Extra Packages for Enterprise Linux — a repository
  you add deliberately, because RHEL's own set is small and conservative on purpose.

## And SELinux is on

This family enables **SELinux** by default, in enforcing mode. It is a second permission system
above the one lesson 4 teaches, and it will at some point deny something that the ordinary
permissions clearly allow.

That is not a malfunction and the answer is not to switch it off, which is what every forum post
will tell you to do. Lesson 4 names it properly. What matters now is recognising the shape:
**on Red Hat, a denial that makes no sense against `ls -l` is usually SELinux**, and there is a
log that says so.
