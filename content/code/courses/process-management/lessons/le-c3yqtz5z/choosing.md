---
title: Choosing a bet for a piece of work
version: 1
---

No organisation picks a method once and applies it to everything. A bank runs its regulatory reporting one way and its mobile app another, and the same architect may work in both in the same week. The useful question is not *which method is best* but **which assumption the work in front of you supports**.

## Four questions that sort most work

| question | if yes, it leans towards | if no |
|---|---|---|
| Are the requirements fixed by something outside the team — a law, a machine, a signed contract? | a plan made up front | short loops |
| Is a late change very expensive — hardware, certification, a data migration with no way back? | a plan made up front | short loops |
| Can a user try a partial version and react to it? | short loops | a plan made up front |
| Is the technology new to the people building it? | short loops, with the risky part first | either |

The answers rarely agree. A new appointment-booking feature for a clinic network may have users who can try a partial version, a payment integration fixed by the provider's contract and a data migration that cannot be undone. **Mixing is normal.** The integration and the migration get a plan with dates; the screens get short loops with the receptionists who will use them.

## Complicated and complex

Dave Snowden's Cynefin framework names the distinction behind those questions. A **complicated** problem has a right answer that an expert can work out in advance: the plan can be made before the work. A **complex** problem has an answer that only emerges from trying things, because the system reacts to what you do: the plan has to be a series of experiments. Software usually has both kinds inside one project, and the mistake is to treat a complex part as if analysis alone could settle it.

## What the contract says

The method is often decided before the team arrives, by the contract. A **fixed-price** contract fixes scope, cost and date together, so it pushes towards a plan made up front and makes every change a negotiation. A **time-and-materials** contract pays for the effort spent, which makes changing direction cheap for the supplier and risky for the client, who carries the uncertainty. Contracts that fix the budget and the date while leaving the scope open — sometimes called fixed-price, variable-scope — are an attempt to write the agile bet into a legal document.

An architect reading a proposal should check which of these the contract is before deciding how much of the design has to be settled in the first month.
