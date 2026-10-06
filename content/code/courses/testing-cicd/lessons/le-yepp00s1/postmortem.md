---
title: The postmortem
version: 1
---

A **postmortem** is the written account of an incident, made after it is over. Its purpose is to
change something, so the same failure is less likely or less harmful next time. Here is a short one
for the incident of lessons 10 and 11.

## What happened

1.6.0 added a delivery estimate by state. Its table of states skipped the CEP prefix 57, Alagoas, and
any quote to Alagoas raised `KeyError: 57`, answered as a 500. The tests passed: their four examples
missed Alagoas. The smoke test passed: it does not ask for a quote. Green took all the traffic, and
77 of 1,551 requests failed before the switch back to blue.

## What limited the damage

- Blue was still running, so switching back took three milliseconds.
- The error was logged with its cause, so the diagnosis took one `grep`.
- Released as a canary instead, the same bug failed 2 requests, and `canary.py` stopped it with
  nobody watching.

## What changes

- **A regression test** checks that every prefix has an estimate. Done in 1.6.1.
- **The estimate is behind a flag**, so the next problem with it can be turned off without a deploy.
  Done in 1.6.1.
- **Releases go out as canaries** with the stop criteria of this lesson, instead of a full switch.
- **`canary.py`'s rule is reviewed**, because one error can abort a good release between 50 and 99
  answers.

## Blameless

The account names **what** happened, not **who** let it happen. Ana wrote `range(40, 57)` and the
review missed it; neither fact is a cause anybody can act on. "Be more careful" is not a change. A
test, a flag and a rule are changes, and they protect the next person, who will be just as careful
and will make a different mistake. A team whose postmortems look for culprits soon has postmortems
that hide them.
