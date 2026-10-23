---
title: A guide somebody else already argued
version: 1
---

**A secure configuration guide is a list of settings, each with the argument for it already
made.** Lesson 1 hardened `web` by eye: a scan, a list of accounts, a reading of `sshd -T`, and a
judgement about each finding. That works for one machine you understand. It does not work for the
fortieth, and it does not survive the question an auditor asks first: "against what?"

The commonest wrong picture is that a guide is a list of things to switch on. Most of a good one is
the opposite, the same work lesson 1 did, written down once so nobody has to rediscover it: remove
this package, refuse that login, set this file's permissions.

## The CIS Benchmarks

The **Center for Internet Security** publishes a Benchmark per product and per release: one for
Ubuntu 22.04, another for Ubuntu 24.04, one for Windows Server 2022, one for nginx. They are
written by volunteers from industry and government and agreed by consensus, and the PDFs are free
to download after registering; the tool that scores a machine against them in full, CIS-CAT Pro,
is for members. Each **recommendation** has the same parts:

| part | what it holds |
|---|---|
| a number and a title | a section number and a sentence such as `Ensure SSH root login is disabled`, so a report can name it |
| the profile | **Level 1** for settings any server can take without losing a function, **Level 2** for defence in depth that may cost one |
| the rationale | why the setting matters, which is the part that settles an argument |
| the audit | the command that shows whether the machine complies |
| the remediation | the change that makes it comply |
| the impact | what may stop working when you apply it |

Two profiles is the guide admitting that hardening has a price. Level 1 is meant to be safe to
apply everywhere. Level 2 removes things a particular machine may need: a Level 2 workstation
profile that disables USB storage is right for a reception desk and wrong for the person who
receives clients' documents on a stick, and lesson 5 is that argument in full.

**A Benchmark is written for one release.** Paths, package names and defaults change between
Ubuntu 22.04 and 24.04, so an audit command written for one can be wrong on the other, and the
section on SCAP shows what a tool does with a guide written for a different release.

## The other guides

CIS is not the only source, and an organisation usually answers to one in particular:

- the **DISA STIGs**, written by the United States Department of Defense for its own systems, more
  prescriptive and stricter than CIS Level 1;
- **Canonical's Ubuntu Security Guide** (`usg`), which applies and audits the CIS and STIG
  profiles on Ubuntu and comes with an Ubuntu Pro subscription;
- **Microsoft's security baselines** for Windows, delivered as Group Policy objects, which lesson 3
  explains;
- the vendor's own hardening guide for a product, which is often the only one that knows about the
  product's own settings.

None of them was run for this course, because each needs an account, a subscription or a
licence that the course does not ask you for. What this lesson runs is free and in Ubuntu's own
archive: **Lynis**, which audits against its own checks, and **OpenSCAP**, which reads guides
written in the standard machine-readable format. Then you write your own baseline, which is what
every organisation ends up doing with any of the guides above.

## A guide is a starting point, not a verdict

A guide decides what is reasonable for most machines of a kind. Your machine is one particular
machine with one particular job. So the work is always the same three steps: **measure against the
guide, apply what fits, and write down why for what does not.** The last section of this lesson is
about that third step, because it is the one that is skipped.
