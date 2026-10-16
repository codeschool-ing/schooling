---
title: After the rehearsal
version: 1
---

The results go into the same form as lesson 22's write-up, with the expectation beside each number,
and the differences become actions with owners and dates. A rehearsal that found nothing is still
written down: it is the evidence that, on that date, the failover worked in so many seconds, and the
next rehearsal is compared with it.

Then it is repeated, on a schedule, because everything it tested keeps changing: Patroni and
PostgreSQL get upgraded, the application gets a new driver, somebody edits `haproxy.cfg`. Every
quarter is common. And each time a little more is made real:

1. a **switchover** (lesson 16), which loses nothing;
2. a **killed leader**, as in this lesson, in a test environment;
3. the same, with the real application and its real traffic, in a test environment;
4. a killed leader **in production**, at an agreed time, with the people from lesson 22 ready;
5. the failures that are harder to arrange: etcd lost (lesson 16), a frozen leader (lesson 17), a
   whole region (lesson 20).

None of the later steps is safe before the earlier ones have passed, and a team that has done the
fourth one is a team that has seen its own failover work with customers on it. That is the claim this
course has been building towards since lesson 1, made with evidence.
