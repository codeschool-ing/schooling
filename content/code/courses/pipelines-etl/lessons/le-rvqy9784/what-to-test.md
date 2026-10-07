---
title: What to test, and when it runs
version: 1
---

Ten tests is a small suite, and it already covers the things most likely to go wrong in this
pipeline. A rule of thumb for which tests to write comes out of what each one found:

- **A unit test for every decision that takes an input from outside**: each rule of the validator,
  each rule of a staging model about dates, money and status. These are where inputs nobody has seen
  yet arrive, and a unit test is the only test that can try them before they do.
- **An integration test for every path from source to report**, run on a real slice, with answers
  worked out independently. Few of them, because each one is slow and covers a lot.
- **A test for each property the pipeline promises**: idempotency, totals that add up, a mart that
  agrees with its fact table. These are cheap to state and catch whole families of bug.
- **A test for each bug, once it is found**, so that it stays fixed: the float price is in the
  suite now, and it will be in it after whoever touches the validator next.

What not to test is as important. A test that repeats the code — that checks `quantity * price`
equals `quantity * price` — passes whatever the code does. A test against today's production data
changes its answer every night and teaches people to ignore it.

And tests run **before** the change, not after. Lesson 12's data tests run in the nightly build,
because the data changes every night. These tests run when the code changes, on the machine of the
person changing it and again before the change is merged — which is where lesson 18 begins.
