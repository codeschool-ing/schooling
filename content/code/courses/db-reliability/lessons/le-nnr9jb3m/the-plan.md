---
title: The plan, before anything is touched
version: 1
---

A rehearsal is planned on paper first, and the paper is short:

| | for this lesson's rehearsal |
|---|---|
| **what fails** | the Patroni leader, killed as a dead machine would be (lesson 16) |
| **what we expect** | a new leader within about 30 seconds; orders fail meanwhile and succeed after, through port 5000; no order reported as saved is missing |
| **what we measure** | seconds without orders; orders failed; rows in the table against orders reported `ok` |
| **abort criteria** | the cluster is not whole and current before starting: three members, all running or streaming, no lag |
| **the way back** | start the killed node again; it rejoins as a replica (lesson 16) |
| **who is told** | everybody who would see the failures, before, and after with the results |

The expectation is written **before** the rehearsal, as a number. A rehearsal whose result is compared
with nothing confirms whatever happened; one compared with a written expectation can surprise you, and
the surprise is the finding.

The abort criteria matter most. A rehearsal is safe because the cluster can lose one node; started on a
cluster that has already lost one, it removes the second, and the rehearsal is the incident. So the
first thing the plan does is look, and refuse.

In production the plan grows: a time agreed with the business, a person whose only job is to call it
off, and the first rehearsals on a copy of production rather than on production itself. The order
does not change.
