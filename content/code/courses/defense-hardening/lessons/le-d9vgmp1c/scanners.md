---
title: Scanners that log in, and scanners that guess
version: 1
---

**A vulnerability scanner either reads the machine from inside or infers it from outside, and the
difference decides how much its report can be trusted.** The script of the last section is the first
kind in miniature. The second kind is what a scanner does when it has no credentials: it connects to
each open port, reads what the service says about itself, and matches that against what it knows.

From `admin`, ask `nmap` to identify the services on `web` the way an unauthenticated scanner does:

```
ana@admin:~$ nmap -sV -p 22,80 web | grep -E "^(PORT|[0-9])"
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.20 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    nginx 1.24.0 (Ubuntu)
```

It names each program and its version from the first thing the service sends. For OpenSSH that
includes Ubuntu's packaging revision, `3ubuntu13.20`, so here an outside scan and the package database
agree. For nginx it says only `1.24.0 (Ubuntu)`, and **that is where unauthenticated scanning goes
wrong**. Ubuntu fixes nginx's flaws by changing the packaging revision and leaving `1.24.0` alone, so
a scanner reading the banner cannot tell a patched nginx from one two years behind. Depending on how
it was written, it either reports every flaw ever fixed in 1.24.0, a wall of false positives that
teaches people to ignore it, or none of them.

And lesson 1 removed the version from nginx's banner altogether, which leaves the outside scanner
with nothing at all. Hiding a version makes the attacker's first question harder, and it makes the
defender's unauthenticated scan blind in exactly the same way. **The authenticated check is the one
that knows**, and the outside scan has a different job: finding services nobody knew were listening,
which is lesson 1's use of it.

## The tools that do this at scale

None of these was run for this course; each is described from its own documentation.

| tool | what it is |
|---|---|
| **OpenVAS / Greenbone** | the open-source network scanner, with a feed of tests; scans with or without credentials |
| **Nessus** (Tenable), **Qualys**, **Rapid7 InsightVM** | commercial scanners with agents that live on each machine and report from inside |
| **OVAL** data | machine-readable advisories that Ubuntu, Red Hat and others publish; `oscap oval eval` checks a machine against them |
| **`pro fix`** on Ubuntu | Canonical's client, which looks up a CVE or USN and says whether, and how, it applies to this machine |

**OVAL is the real form of this lesson's feed.** Ubuntu publishes one file per release with every
USN, the packages and the fixed versions, and OpenSCAP, which lesson 2 uses for configuration, can
evaluate it. Downloading it needs the internet, which the lab does not have, so this course shows the
mechanism with a feed you can read in one screen.

Agents are what most organisations end up with, for a reason the lab already showed: an agent is
inside the machine, so it reads the package database like the script did, and it reports from
laptops that are rarely on the office network when the scanner runs.
