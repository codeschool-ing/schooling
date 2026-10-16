---
title: Before the real thing
version: 1
---

A load test is only as good as its resemblance to the day it rehearses. A few rules decide that
resemblance, and each is a way load tests have lied to somebody.

- **Test something shaped like production.** The same number of copies, the same instance sizes,
  the same database settings and, above all, the same amount of data: a schema change that is instant on a
  thousand rows takes seconds on two million, which lesson 6 measured.
- **Never load-test somebody else's system.** The box office's payments service is a stand-in the
  lab owns; a real payment provider's production API is not a test target, and neither is any third
  party's. Providers offer sandboxes with their own rate limits, and a test either stays inside them
  or replaces the provider with a stub that answers the way the provider does, slow and fast, right
  and wrong.
- **Keep test traffic recognisable.** Tickets sold by a load test must be easy to find and remove,
  and must never reach a real buyer's account, a real email or a report somebody uses to decide
  something. A header, a tag on the account, a separate show: decided before the first run.
- **Test failure, not only load.** Lessons 9 to 11 built guards and fallbacks; a load test with a
  replica stopped halfway, or payments slowed to a second, is the only way to know they work at the
  load they were built for. Teams that do this on purpose, in production, with everybody watching,
  call it a **game day**; done continuously by a program, it is **chaos engineering**.

## What the course built

Twelve lessons ago the box office was one program and one database, and a hot row stopped it at
under 140 sales a second. Since then it has grown copies and a replica, learnt what each kind of
database is for and changed its schema without stopping. It has reported what it does in metrics,
logs and traces, defended itself with limits, shedding and a breaker, retried without charging
twice, degraded instead of failing, and been planned for and tested at the load of an on-sale.

None of those steps made the box office *scale* on its own. Each one moved a limit, measured where
the next one was, or made a failure say what it was. That is the work, and it does not end: the
next limit is always the one nobody has measured yet.
