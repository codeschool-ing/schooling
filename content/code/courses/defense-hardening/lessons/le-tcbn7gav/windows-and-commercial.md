---
title: The same ideas on Windows and in products
version: 1
---

**Nothing in this section was run for this course.** There is no Windows machine in the lab;
what follows is taken from Microsoft's documentation and the vendors' own.

## Account lockout, Windows's fail2ban

Windows counts failed logins per **account** rather than per address. The *account lockout
threshold*, set by Group Policy under *Account Policies, Account Lockout Policy*, locks an account
after a number of bad passwords, for a set duration. Microsoft's security baseline suggests ten.
The difference matters: counting per account protects one account from a guesser anywhere, and
lets anybody who knows a name lock its owner out on purpose, which is why the threshold is not set
low. fail2ban counts per address and never locks an account at all.

## Attack surface reduction rules

Microsoft Defender's **attack surface reduction** rules are a HIPS built from behaviours that
ordinary work almost never needs, each of which can be set to *audit* or *block*: Office
applications starting child processes, scripts launching downloaded executables, processes reading
credentials out of the memory of the system's authentication process. Microsoft's own guidance is
the one this lesson gives: **run each rule in audit mode first**, read what it would have blocked,
and switch to block only where nothing legitimate appears.

## Controlled folder access

**Controlled folder access** protects chosen folders, such as Documents, from being changed by any
program not on an allowed list. It is aimed at ransomware, which encrypts every file it can reach,
and it is a small mandatory access control: the question is not which account is writing, but
which program.

## File integrity and HIPS in products

Commercial EDR products, lesson 8's subject, include most of this lesson in one agent: integrity
monitoring of chosen paths, rules that block behaviours, and a central console where the alerts of
every machine are read. Wazuh, open source, monitors file integrity and runs active responses, its
name for automatic actions such as blocking an address, in the same spirit as fail2ban. OSSEC, from
which Wazuh grew, did both before either was called EDR.

The engineering underneath is what this lesson ran by hand: a log or an event, a count or a
comparison, a threshold, and an action that somebody checked actually works.
