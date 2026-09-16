---
title: Debian, Ubuntu, and the file that lies to you
version: 1
---

This is the family you are most likely to be standing in. Most tutorials assume it, most cloud
images default to it, and the Docker image in every example is built on it.

## Debian

A volunteer project, started in 1993, with a written constitution and a social contract. It is
not a company's product and there is nobody to buy support from — which is the point, and also
the reason a business may not choose it.

**Its defining habit is caution.** A stable release ships versions that are one to three years
old, because they have been tested for one to three years. Nothing moves until it is dull.
Section 08 argues the case; for now, Debian is what you pick when you want a machine you can
forget about.

## Ubuntu

Canonical's product, built on Debian, released every six months — and every two years one of
those is an **LTS**, supported for five years and extendable to ten.

The version number is the date: **24.04** is April 2024, **22.04** is April 2022. Every LTS is an
April release of an even year, which makes `24.04`, `22.04` and `20.04` LTS and `24.10` not. That
is the most useful thing to know about Ubuntu's versions, and it takes one sentence.

Every release also has a codename, and the codenames are alphabetical two-word animals — 24.04 is
*Noble Numbat*. They appear in repository configuration, so they are worth being able to look up:

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
```

Read the last two lines together: **`ID=ubuntu`, `ID_LIKE=debian`.** That is a machine telling
you which distribution it is and which family it belongs to, and it is the whole subject of
section 11.

## The file that lies

Here is the same machine, asked the older question:

```
ana@vm:~$ cat /etc/debian_version
trixie/sid
```

**That is an Ubuntu machine claiming to be Debian trixie.** It is not lying exactly — the file
records which Debian snapshot this Ubuntu was built from — but if you read it as "which system am
I on" you get a wrong answer with total confidence.

`/etc/debian_version`, `/etc/redhat-release` and the rest are older, per-family files that
predate the standard. They still exist, they are still written, and they are the reason
`/etc/os-release` was invented: **one file, every distribution, the same field names.** Ask the
new question.

## What Ubuntu added, and what it costs

| | |
|---|---|
| **PPAs** | third-party repositories, one command to add. Convenient, unsigned by Canonical, and lesson 7 ranks them by risk |
| **snaps** | a second packaging system alongside `apt`, sandboxed and self-updating. Genuinely contentious: some software ships only this way, and some people remove it on principle |
| **an LTS worth relying on** | five years by default, ten with a subscription, which is why it is the default on every cloud |

You can see the third-party repositories on a machine directly — they are files:

```
ana@vm:~$ ls /etc/apt/sources.list.d/
deadsnakes-ubuntu-ppa-noble.sources
docker.list
ondrej-ubuntu-php-noble.sources
ubuntu.sources
```

Four entries: Ubuntu's own, Docker's, and two PPAs. **Each of those is somebody you have decided
to trust**, and the list is worth reading when you inherit a machine — section 15 of lesson 1 said
the risk moved outside the repository, and this directory is where it moved to.

## And the derivatives below

Linux Mint, Pop!_OS, Zorin and others are built on Ubuntu, which is built on Debian. They change
the desktop and a few defaults; underneath, `apt` works, the paths are the same, and
`ID_LIKE=debian` holds. **If you can drive Ubuntu you can drive any of them** — which is exactly
what the family in section 03 was promising.
