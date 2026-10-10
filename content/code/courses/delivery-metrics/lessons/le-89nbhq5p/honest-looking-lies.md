---
title: A catalogue of honest-looking lies
version: 1
---

Each move below improves a number without improving delivery. Each one has been made, somewhere, by people who believed they were doing the reasonable thing, and each can be argued for in a meeting. They are listed so that you can recognise them, in a report or in your own habits.

## Deployment frequency

- **Split one release into many.** Deploy each service, each change or each configuration file separately, at the same minute. The count multiplies; users receive the same code at the same time.
- **Deploy nothing.** A pipeline run that redeploys the same version, or a change to a comment, counts as a deployment if nobody defined one.
- **Change what counts.** Move from "one per release" to "one per service" in the middle of a quarter. Lesson 5 called this out as the definition that multiplies the metric overnight.

## Lead time for changes

- **Start the clock later.** Measure from the merge instead of the first commit, or from the last commit before merge after squashing a week's work into one. The review queue disappears from the number.
- **Merge early, deploy behind a flag.** Long-lived work hidden behind a feature flag can be merged daily and reported as fast, while the feature itself takes months. Flags are a good practice; reporting the merges as delivery is the trick.

## Change failure rate

- **Narrow the definition after the fact.** "A rollback within the hour wasn't really a failure." "That incident was caused by the database, not the deployment." Each exclusion is plausible; together they empty the numerator.
- **Fix forward without recording it.** A broken deployment followed twenty minutes later by a quiet second deployment that repairs it shows two successes and no failure.
- **Grow the denominator.** Every trick that inflates deployment frequency also lowers the failure rate, because the rate divides by deployments.

## Time to restore

- **Start at the declaration.** If the clock starts when somebody declares an incident, the hour nobody noticed is gone.
- **Close the incident at mitigation and open a ticket for the rest.** Sometimes right, as lesson 14 says. As a habit used on the number, it moves recovery into a ticket nobody measures.

## Flow metrics

- **Split cards when they get old.** An item at forty days becomes two new items at zero, and the ageing chart looks fresh.
- **Move stuck work off the board.** A blocked column outside the clock, or a separate list, as the Billing team did with `BIL-189`, removes the oldest item from every chart.
- **Close and reopen.** A bug closed as fixed and reported again next week counts twice as throughput.

## What they have in common

Every move changes **what is counted**, not **what happens to the work**. That gives the general test, which the next two sections apply with a program: **if the number moved, ask which events changed**. If no change reached a user sooner, no failure was avoided and no item finished faster, the number moved by itself.
