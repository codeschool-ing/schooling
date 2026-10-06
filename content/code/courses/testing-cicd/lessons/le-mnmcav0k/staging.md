---
title: What staging can tell you, and what it cannot
version: 1
---

Staging is where a release is proved deployable before it meets a customer. It earns its cost when it
catches what no earlier stage could, and it misleads when a team believes it caught more than it did.

## What it can show

- **The deploy works**: the artifact unpacks, the process starts with a real configuration, the smoke
  test passes. Lesson 7's typo in a port was found by exactly this.
- **The integrations answer**: the carrier's sandbox accepts the request, a message reaches the
  queue, the database migration runs.
- **The release behaves end to end**: the acceptance tests of lesson 1 run against the deployed
  program, through its real interface.
- **People can look at it**: a product owner can try the new screen before customers do.

## What it rarely shows

- **Load.** Staging sees the team's traffic, not the customers'. A query that takes 5 ms on a
  thousand rows can take seconds on ten million.
- **Real data.** Seeded data is tidy. Production holds the CEP with a space in it, the address of 300
  characters and the order from 2019 in a format nobody remembers. Lesson 3 section 11 explained why
  staging should not hold a copy of it.
- **The real integrations.** A sandbox is not the live API, as section 04 showed.
- **Time.** A memory leak that takes three days to matter will not show in a staging run of an hour.

## So what does a green staging mean?

It means **this release can be deployed and does what its tests say, in conditions like
production's**. It does not mean the release is safe at production's scale. That gap is why lessons
10 and 11 exist: releasing to a small share of real traffic first, watching it, and having a fast
way back. Teams that understand this keep staging lean and cheap, and spend their effort on watching
production and on rollback. Teams that do not keep adding to staging, trying to make it production,
and never quite get there.

The repository that publishes this course has no staging at all, and its reasoning is the same
reasoning run the other way: for a small platform, the checks before the release plus a fast,
rehearsed way back cover what a staging environment would.
