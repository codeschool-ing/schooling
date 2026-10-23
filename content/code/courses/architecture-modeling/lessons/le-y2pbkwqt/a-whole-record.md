---
title: A whole record, from the late payment
version: 1
---

**Lesson 4's state table found a cell nobody had decided: a payment approved for a ticket that had
already expired.** The decision Tainá wrote into the table became this record. It is shown whole,
then taken apart.

```localised
# 14. Refund automatically a payment approved after its hold expired

Status: Accepted, 2025-07-03
Deciders: Tainá (architecture), Payments team, Sales team

## Context and forces

- A seat is held for ten minutes while the passenger pays (ADR-0009).
- The payment gateway confirms some payments late: 0.4% of approvals
  arrive more than ten minutes after the charge was requested, by
  webhook (ADR-0011).
- When the hold has expired, the seat may already be sold to somebody
  else. On 20 June 2025 this put two passengers on seat 14 of the
  18:40 to Feira de Santana.
- The code had no rule for this case; it marked the booking paid.
- A passenger must never pay for a seat they did not get.
- Station agents cannot override a sold seat at the door.

## Decision drivers

1. Nobody pays without a seat.
2. Nobody loses a seat they already have.
3. No manual work for agents or drivers.

## Considered options

A. Mark the booking paid and move the other passenger.
B. Extend every hold to 30 minutes, so late approvals are rare.
C. Refund automatically, keep the ticket Expired, and offer the
   nearest free seats on the same trip.

## Decision

We choose C. When an approval arrives for an Expired ticket, the
booking service requests a full refund with the booking id as the
idempotency key, keeps the ticket Expired, and sends the passenger an
e-mail and a push message offering the three nearest free seats on
the same trip, held for ten minutes.

## Consequences

- No passenger is charged for a seat they did not get (driver 1).
- No passenger already holding a seat is moved (driver 2).
- About 35 refunds a week at normal traffic, 140 in the week before
  São João, each costing the gateway's refund fee.
- A passenger who paid late may lose a seat they wanted, and may find
  the trip full. We accept this; option B would cost every passenger
  a 30-minute hold on seats they abandon.
- Option A was rejected: it moves a passenger who did nothing wrong.
- The state machine gains a transition, Expired --payment approved /
  refund--> Expired, and a test covers it.
```

## Reading it as a reviewer

- **The title is the decision.** Somebody scanning the index learns what was decided without opening
  the file.
- **Every force can be checked**, and two link to earlier records, so the log reads as a chain.
- **The incident is in the context as a fact with a date**, not as a story. The reader learns that it
  happened and what it cost, in one line.
- **Option B is written fairly**: it would work most of the time. Its cost appears among the
  consequences, where it can be weighed.
- **The negative consequence is specific**: a refund fee, a number of refunds per week, a passenger
  who may find the trip full. Each could be checked against the gateway's statement next month.
- **The last consequence points back at the model.** A decision that changes behaviour should
  change the diagrams that describe it, and say so.

**Draw it yourself.** Write the record for one of the question marks you filled in for lesson 4's
state table, such as *Boarded × payment approved*. Keep it to one page: forces, drivers, at least
two options, the decision and its consequences, including at least one you would rather not write.
