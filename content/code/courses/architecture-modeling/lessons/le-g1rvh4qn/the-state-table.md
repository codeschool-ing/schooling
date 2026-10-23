---
title: The state table, or how a state machine finds bugs
version: 1
---

**A state machine drawn as a picture shows the transitions somebody thought of; the same machine
written as a table shows the ones nobody did.** Put the states down one side and the events across
the top, and every cell has to be filled. A blank cell is a question the design has not answered.

## Carcará's ticket, as a table

| state ↓ · event → | payment approved | payment declined | 10 min pass | cancelled | scanned | departed |
| --- | --- | --- | --- | --- | --- | --- |
| **Held** | → Paid | stays Held | → Expired | → Expired, release seat | refuse | → Expired |
| **Paid** | ? | ? | ignore | ≥ 3 h: → Refunded; < 3 h: refuse | → Boarded | → No-show |
| **Expired** | **?** | ignore | ignore | ignore | refuse | ignore |
| **Boarded** | ? | ? | ignore | refuse | refuse: already used | ignore |
| **Refunded** | ? | ? | ignore | ignore | refuse | ignore |
| **No-show** | ? | ? | ignore | refuse | refuse | ignore |

Thirty-six cells, and the diagram in the last section had seven transitions. Most of the extra cells are
*ignore* or *refuse*, which is fine, but each one is now a decision written down rather than an
accident of whatever the code happens to do.

## The cell that mattered

**Expired × payment approved.** The passenger presses *pay* at minute nine; the card network takes
ninety seconds; the timer fires at minute ten and the ticket expires and releases the seat; at
minute ten and a half, the payment gateway's webhook arrives saying *approved*. Lesson 2's sequence
diagram showed that the webhook can arrive late. The state machine had no arrow for it, and the
table makes the absence impossible to miss.

Carcará's code at the time did what code does when nobody decided: it marked the expired booking as
paid, and the seat, already released, had been sold to somebody else. Two passengers, one seat,
on the Friday before São João. The decision Tainá wrote into the table afterwards:

> **Expired × payment approved**: refund the payment automatically, keep the ticket Expired, and
> tell the passenger the seat was released, with the nearest free seats on the same trip.

That decision became a transition on the diagram, a test in the code and, in lesson 5, a decision
record.

## Repeated events

The other question rows raise is **what if the same event arrives twice?** Gateways retry webhooks,
and phones resend scans when the signal drops. *Paid × payment approved* should be *ignore*, not an
error and not a second charge recorded. *Boarded × scanned* should be *refuse, already used* at the
door and *ignore* when the same phone resends its upload. Lesson 2 called this idempotency; the
state table is where you decide it per state.

**Draw it yourself.** Fill in the question marks in the table above. For each one, write the
decision and one sentence saying why. Then compare with the decision for *Expired × payment
approved*: the same reasoning settles most of the others.
