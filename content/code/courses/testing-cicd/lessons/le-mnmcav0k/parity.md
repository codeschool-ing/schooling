---
title: Keeping environments alike
version: 1
---

**Parity** is the degree to which environments resemble each other where they are not meant to
differ. Every gap in parity is a place where a release can pass in one environment and fail in the
next, and this course has already met three of them:

- **The time zone.** Lesson 5's dispatch draft passed on a laptop in São Paulo and failed on every
  machine set to UTC. A developer's laptop and a server rarely share a zone unless somebody makes
  them.
- **The database engine.** Lesson 1 section 06 warned against testing against SQLite and deploying
  on PostgreSQL: the two disagree on types and on SQL.
- **The interpreter's version.** Lesson 5's matrix ran three Pythons because production might run
  any of them.

## The three gaps

*The Twelve-Factor App* names the gaps between development and production by their causes:

| gap | what it is | how it closes |
|---|---|---|
| **time** | code written today reaches production weeks later | small changes, deployed often |
| **people** | developers write it, someone else deploys it | the same pipeline deploys everywhere |
| **tools** | a lighter stack in development than in production | the same engine, the same versions, in containers if need be |

The third gap is the one teams open on purpose, for convenience: SQLite instead of PostgreSQL, an
in-memory queue instead of the real broker, the newest Python on a laptop and an older one on the
server. Each one makes development faster and each one is a class of bug that only production will
find. **A container image is the usual cure**: the same image, with the same interpreter and the same
libraries, runs on the laptop, in CI and in production, and the only thing left to differ is
configuration. In the `devops` track, `docker` lesson 25 runs a test suite inside the same container
the pipeline uses, for this reason.

## What parity cannot give you

Parity of software is achievable. **Parity of data and of load is not**, not fully, and it is the
next section's subject: a staging environment can run the same artifact, the same engine and the same
configuration shape, and still be a small, quiet copy of a large, busy system. Knowing which gaps you
have closed and which you have not is the useful part, because it says what a green staging run
actually proves.
