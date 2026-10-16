---
title: Where it lives, and how it is reached
version: 1
---

A runbook kept on the system it describes is lost with it. The page that explains how to recover the
database cannot be in a wiki whose database is the one that is down, or on the primary's disk, or
behind a single sign-on that is itself part of the outage.

- **Two places, at least**: the team's usual documentation, and a copy somewhere that depends on none
  of the systems it describes, such as a repository on another provider, or printed and filed beside
  the on-call phone. The repository is better, because it has a history and a diff: a change to the
  runbook is reviewed like a change to the code, and `runbook-check.sh` runs on every change.
- **Secrets are referred to, not written down**: the runbook says which entry in the password manager
  holds the replication password, and how to reach the password manager when the usual way in is down,
  sometimes called the **break-glass** procedure: an account sealed for emergencies, whose every use
  is noticed and reviewed.
- **Access is tested** like everything else: in a rehearsal, the person following the runbook uses only
  what they can reach from where they are, and every "I would just ask Ana" is a line missing from the
  page.

## The course, as one page

The runbook is where this course ends up, because it is where everything in it is used. Lesson 1's
restore that somebody watched succeed is its "last tested" line. Lessons 2 to 10 are the backups it
points to, where they live and who can delete them. Lessons 11 to 21 are the machinery its scenarios
describe. Lesson 22 is how it is used on the night, and lesson 23 is how it is kept honest. The test of
all of it is the one at the top of this lesson: somebody else, with only the page, at the worst
possible time, bringing the shop back.
