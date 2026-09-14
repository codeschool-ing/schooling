---
title: The date somebody chose for you
version: 1
---

Every fixed release has an end. On a day decided years in advance, the people maintaining it stop
— and the machine keeps working, which is exactly what makes this dangerous.

**Nothing breaks at end of life.** The software runs, the services start, the site serves. What
stops is the security updates, and the machine becomes a thing that is quietly accumulating known,
published, unpatched vulnerabilities while behaving perfectly.

## The windows

| | standard support | with a subscription |
|---|---|---|
| **Ubuntu LTS** | 5 years | 10, with Ubuntu Pro |
| **Ubuntu interim** (`24.10`) | 9 months | — |
| **Debian stable** | ~3 years, plus ~2 of LTS | — |
| **RHEL** | 10 years | extendable |
| **Rocky, Alma** | matches RHEL | — |
| **openSUSE Leap** | ~18 months per version | — |
| **Alpine** | 2 years per release | — |
| **Fedora** | ~13 months | — |
| **rolling** | not applicable | — |

Two of those are worth a second look. **Ubuntu's interim releases last nine months**, which is
shorter than many people's deployment plans — installing `24.10` on a server because it was the
newest is a decision with an expiry date attached. And **Fedora's thirteen months** is not a
defect: Fedora is where things are proven before RHEL, and it says so.

## What to do about it, in order

**1 · Know the date.** `/etc/os-release` gives you the version; the distribution publishes the
date. It is a fact about every machine you run, and it belongs wherever you keep facts about
machines.

**2 · Plan the upgrade before the date, not after.** Moving from one major version to the next is
a real piece of work — configuration formats change, defaults change, a service is replaced. It
takes a week you have, or a weekend you do not.

**3 · Rebuild rather than upgrade, where you can.** In a world of containers and infrastructure as
code, the cheaper answer is frequently to build a new machine on the new version and move the
work across, rather than to upgrade a machine in place. The old one is then a thing you delete
instead of a thing you trust.

## Why this lands on you

Because the machine will not tell you. There is no dialog, no countdown, and `apt upgrade` on an
end-of-life release reports that everything is up to date — **which is true and reads as
reassuring**, and means only that no more updates are ever coming.

That is the honest shape of it: the failure mode of a lifecycle is silence, and the same is true
of the scheduled job in lesson 13 and the backup in lesson 10. **A system that has stopped
protecting you looks identical to one that has nothing to do.** Learning to check things that
report nothing is most of what operations is.

## And the fact that dates this course

CentOS 7 ended in June 2024, after ten years. It ran an enormous part of the internet. Machines
running it are still out there — still working, still serving, still receiving nothing — and the
people responsible for a good number of them do not know the date has passed.

That is the whole section in one example, and it is why the reflex in the next section is
`/etc/os-release` rather than `uptime`.
