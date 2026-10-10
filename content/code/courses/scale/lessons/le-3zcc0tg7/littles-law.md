---
title: Little's law
version: 1
---

Degrading well is half of surviving an on-sale. The other half is having enough capacity that it
rarely comes to that, and capacity planning starts from one equation that holds for almost any
system that is not piling up work without limit:

**L = λ × W**

The average number of things inside a system, *L*, is the rate at which they arrive, *λ*, times how
long each one stays, *W*. It needs no assumption about how the arrivals are spread or how long each
one takes. It holds for a shop's queue, for a database's connections and for the box office's slots.

The course has been using it without saying so:

- **Lesson 9's load test.** 32 workers in a closed loop, and 105 sales a second. Each worker is
  always inside the box office, so *L* = 32, and *W* = 32 ÷ 105 = 0.30 s. The measured median was
  295 ms.
- **Lesson 9's timeout.** 32 slots, each held for the full one-second timeout while payments hung:
  *λ* = 32 ÷ 1 = 32 sales a second, at most, whatever the demand.
- **How many charges are in flight.** 100 sales a second, each spending about 30 ms in payments:
  3 charges at a time on average. If payments slows to one second a charge, the same 100 sales a
  second need 100 in flight, and the box office has 32 slots. Little's law says, before anything
  breaks, that a slower payments service turns into shed load at the box office.

That last use is the important one. **A slowdown somewhere downstream is an increase in *L*
everywhere upstream**: more threads, more connections, more memory, with no extra traffic at all.
It is why lesson 9 bounded the slots and lesson 10 bounded the retries: both keep *L* from growing
without anybody deciding it should.
