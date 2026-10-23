---
title: Fitness functions: checks that keep the architecture honest
version: 1
---

**A fitness function is an automated check that measures how well the system still has an
architectural characteristic it is supposed to have.** The term comes from *Building Evolutionary
Architectures*, by Neal Ford, Rebecca Parsons and Patrick Kua. The idea is older than the name: if
the documentation says something about the system that a program could verify, make the program
verify it, on every change.

## What can be checked

Many claims in an architecture document are checkable, and each turns a sentence into a test:

| the document says | the fitness function |
| --- | --- |
| *Ticketing reaches Pricing only through `FareQuote`* (lesson 2) | a dependency test fails if any ticketing class imports a pricing class other than the interface |
| *the booking service never talks to Redis directly* (lesson 3) | the same kind of test, on packages |
| *95% of purchases under 2 s at 2,000 a minute* (lesson 6, QS-01) | a load test before every São João fails the release if the percentile is over |
| *a scan is checked within a second with no network* (QS-02) | the offline scan test from lesson 6's matrix |
| *every decision record has a status and a date* (lesson 5) | a script that reads `docs/decisions/` and fails on a record without them |
| *every diagram in the repository has a title and an owner* | the same, for diagram files |

A structural check of the first kind, written with ArchUnit, a library for Java and Kotlin, reads
almost like the sentence it enforces:

```kotlin
@ArchTest
val ticketingUsesPricingOnlyThroughFareQuote: ArchRule =
    noClasses().that().resideInAPackage("..ticketing..")
        .should().dependOnClassesThat(
            resideInAPackage("..pricing..").and(not(simpleName("FareQuote")))
        )
```

The rule reads: no class in a ticketing package may depend on a class in a pricing package, unless
that class is `FareQuote`. It is shown to illustrate the shape and was not run for this course. Run on every pull request, it means **the component diagram of lesson 2 cannot drift
from the code without the build going red**, which no amount of good intentions achieves.

## Kinds of fitness function

The book separates them along a few axes, and two matter most when choosing:

- **atomic or holistic**: one characteristic in isolation, like a dependency rule, or several at once,
  like a load test that measures latency, errors and cost together;
- **triggered or continual**: run on an event, such as a pull request or a release, or all the time,
  like a production monitor that alerts when the 95th percentile of purchases passes 2 seconds.

## What not to check

Not every sentence deserves a test. **A fitness function is worth writing when the claim matters and
is likely to be broken by accident.** *Ticketing uses Pricing only through `FareQuote`* qualifies:
the shortcut was taken once already, in lesson 2. *The system is written in Kotlin* does not: nobody
will accidentally rewrite it in another language. A suite of checks nobody understands is its own
kind of dead documentation.
