---
title: Fixed, LTS and rolling
version: 1
---

Every distribution has to answer one question: **when do you get new versions of software?** There
are three answers, they are genuine trade-offs rather than degrees of quality, and the answer a
distribution gives is most of what it is like to live with.

## The three

| | what it does | you get | you give up |
|---|---|---|---|
| **fixed** | versions frozen at release, security fixes only | a machine that behaves the same for years | software that is one to three years old |
| **LTS** | a fixed release with a much longer window | five or ten years of the above | the same, for longer |
| **rolling** | updates continuously; there is no version | today's software, always | a machine that changes under you |

**Debian stable, RHEL, Ubuntu LTS and openSUSE Leap are fixed.** Arch and openSUSE Tumbleweed are
rolling. Fedora is fixed with a very short window, which makes it behave like something in
between.

## What "frozen" actually means

It does not mean nothing changes. A fixed release still receives **security fixes**, and that is
the whole point: the maintainers take the fix for a vulnerability and apply it to the old version
rather than shipping a new one.

That is called **backporting**, and it produces a fact that confuses people constantly:

> A scanner reports that your `nginx 1.18` is vulnerable. The distribution's `nginx 1.18` is not —
> the fix was applied to it three weeks ago, and the version number did not move.

So version numbers on a fixed release are not a reliable way to judge whether software is patched,
and a security tool that only compares numbers will report a machine full of problems that are not
there. The package manager knows the truth; lesson 7 is where you ask it.

## Why anybody chooses rolling

Because old software is not free either. On a fixed release you are three years behind a language
runtime, a database has a feature you cannot use, and a bug you hit was fixed upstream in a version
you will not see until the next release. For a developer's own machine, that is a real cost.

Rolling pays for it with attention: an update can change something you depended on, on a Tuesday,
because there is no release to hold it back. **That is fine on a laptop and unacceptable on
forty servers**, which is why almost nothing production-facing rolls.

## Version numbers that mean something

| | |
|---|---|
| `Ubuntu 24.04` | year and month — April 2024, and an LTS because it is April of an even year |
| `Debian 12` | sequential, roughly every two years, each with a Toy Story codename |
| `RHEL 9.4` | major dot minor. Major is a decade-long line; minor is a refresh within it |
| `Alpine 3.20` | major dot minor, about every six months |
| `Tumbleweed` | none, and asking is the wrong question |

The one worth internalising is Ubuntu's, because it is the one you will read most often, and
because the date *is* the number: `20.04` is old, `24.04` is current, and you can tell at a glance
without looking anything up.

## Which to pick

Section 12 argues three cases properly. The compressed version:

- **A server somebody else maintains** — fixed, with the longest window you can get. Boring is the
  feature.
- **Your own development machine** — whatever your team and your documentation assume, which in
  practice means Ubuntu LTS, unless you enjoy the maintenance that rolling asks for.
- **A container image** — the question barely applies. The image is rebuilt from a tag on every
  deploy, and lesson 7's *pinning* is how you control what you get.
