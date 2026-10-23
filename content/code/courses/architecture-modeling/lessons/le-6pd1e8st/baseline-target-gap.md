---
title: Baseline, target and the gap between them
version: 1
---

**Phases B, C and D each describe two architectures, the baseline as it is now and the target as it
should be, and the work is defined by the gap between them.** TOGAF's technique for finding that
gap systematically is the **gap analysis matrix**, and it is one of the parts of the framework worth
using even in a company that uses nothing else.

## The matrix

Put the building blocks of the baseline in rows and those of the target in columns. Each cell where
a row and a column are the same thing is **carried over**. A baseline row with no match in the target
is **eliminated**; a target column with no match in the baseline is **new**. The application
domain of Carcará's programme:

| baseline ↓ · target → | ticketing | passenger web app, with counter mode | boarding app, reading QR on paper | *eliminated* |
| --- | --- | --- | --- | --- |
| **ticketing** | carried over | | | |
| **passenger web app** | | changed: counter mode | | |
| **boarding app** | | | changed: reads paper QR | |
| **station back office** | | | | **eliminated: deliberately?** |
| **station receipt print module** | | | | **eliminated: deliberately?** |
| ***new*** | | | | |

## The question in the last column

The matrix's real value is the question it forces on every eliminated item: **was it eliminated on
purpose, or did the target forget it?** TOGAF's guidance is to check each one, because an accidental
elimination is a capability the business loses without anybody deciding it.

For the station back office, the check found two such capabilities:

- **cash refunds at the counter**, which lesson 7's stakeholders already showed were invisible
  elsewhere. The target had no place for them; they were added to the counter mode.
- **the end-of-day cash report** each agent prints for the station manager. Nobody had mentioned it,
  because it ran by itself at closing time. It became a requirement of the counter mode too.

The receipt print module, on the other hand, was eliminated deliberately: printing moves into the
counter mode, which prints the QR receipt.

## Transition architectures

When the gap is too big to close in one step, the plan defines **transition architectures**:
intermediate states, each one stable and usable on its own. Carcará's three were the pilot stations,
the coastal routes and the rest. Each transition architecture is a full description in its own
right: at the end of the first quarter, two stations run the target and twenty-four run the
baseline, and **both must work**, including a passenger who buys at a pilot station and boards at
another.

That last sentence is the thing transition architectures exist to catch: **the states in between are
architectures too**, often the most complicated ones, and they are the ones nobody draws unless a
method makes them.
