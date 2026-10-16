---
title: Why write it down
version: 1
---

A **runbook** is the procedure for one symptom: what to look at, what to do about each thing you
might find, how to tell it worked, and whom to call when it did not. It is written in daylight by
somebody with time, for somebody without it — very often the same person, woken at three in the
morning by an alert, reading a terminal with one eye.

The common objection is that the person who knows the server does not need one. **That person is
exactly who the runbook is for.** They are the one paged, they are the one on holiday when the
page goes to somebody else, and at three in the morning they are not the engineer they are at
three in the afternoon. People skip steps when tired, trust a memory of last time, and type the
command that fixed a different problem. A page of steps written by the rested version of the same
person is the cheapest defence there is against all three.

## What a runbook is not

It is narrower than the documents beside it, and keeping it narrow is what makes it usable.

- It is **not a description of the system**. Where the server is, how it is backed up and how it
  would be rebuilt is documentation for recovery, and db-reliability lesson 24 is about writing
  that.
- It is **not the account of an incident**. Running one, the roles people take, and the review
  afterwards belong to db-reliability lesson 22.
- It is **not a training text**. This course explained why a replication slot can fill a disk
  (lesson 7) and what a full disk does to the server (lesson 9). The runbook carries none of the
  explanation. It carries the three commands that understanding turns into, and the numbers at
  which each one matters.

## What it buys

**The same steps in the same order every time**, so two nights can be compared and a step that
was skipped is visible. **A second person can do it**, which turns "only Ana can fix that" into a
page anybody on call can follow. And **it is the first draft of automation**: a step that never
needs judgement — run this query, compare with that number — is a step that can become a check in
monitoring or a line in a script like lesson 23's, and a runbook is where such steps are found.

The rest of this lesson writes one for a single symptom, the disk under PostgreSQL filling, runs
every step of it on your server, and keeps a log while doing so.
