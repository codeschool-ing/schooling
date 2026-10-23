---
title: Where records live, and how they are agreed
version: 1
---

**Records live in the repository, next to the code they decide about, as plain text, and they are
agreed through the same review the code goes through.** That one arrangement solves most of what goes
wrong with decision logs kept anywhere else.

## In the repository

Carcará keeps them in each repository under `docs/decisions/`, one Markdown file per record, named
with the number and a slug: `0014-refund-late-approvals.md`. Decisions that cross repositories go in
the architecture repository, which every team can read. Three reasons this beats a wiki:

- **They are found.** An engineer reading the seat-hold code finds `docs/decisions` beside it; a wiki
  page needs somebody to know it exists.
- **They are versioned with the code.** Checking out last year's code checks out last year's
  decisions, so the two always match.
- **They are reviewed.** A record proposed in a pull request gets comments from the same people who
  review the code, and the merge is the moment it becomes *accepted*.

## Proposing a record

1. Write the record with status *Proposed* and open a pull request with it alone, or with a small
   spike that shows the option works.
2. Ask for review from the people who own what it changes, by name. For a cross-team record, that
   means one reviewer per affected team.
3. Discuss in the pull request, and change the text as the discussion improves it. The proposed
   record is the one document that is allowed to change.
4. Merge with the status set to *Accepted* and the date. If the answer is no, merge it as *Rejected*:
   the reasoning is still worth keeping.

## Tools, none of them required

Plain files and a text editor are enough, which is why lesson 1 listed nothing more. Tools exist to
save typing: **adr-tools**, a set of shell scripts by Nat Pryce, creates numbered files from a
template and updates the *superseded* links; **Log4brains** builds a browsable website from a
folder of records. Both are optional, and both work on the same Markdown files, so choosing one
never locks the records in.

## Linking from the code

The last habit closes the loop: where the code embodies a decision, a short comment points at it.

```kotlin
// Holds live in Redis with a 10-minute expiry: see docs/decisions/0009-seat-holds-in-redis.md
val held = redis.opsForValue().setIfAbsent("hold:$tripId:$seat", bookingId, Duration.ofMinutes(10))
```

The next person to wonder *why Redis?* is one click from the answer, and the answer includes the
cost that was accepted.
