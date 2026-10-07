---
title: Writing the agreement down
version: 1
---

**A negotiation ends with a short written agreement that both sides can point at in December, or it
does not really end.** Memory of a deal drifts toward what each side wanted, and by the deadline the
two memories have drifted apart. The note takes ten minutes and saves the argument about what was
agreed.

## The note

Lívia drafted it the same afternoon, and Renata and Henrique each corrected one line:

> **Scheduled deliveries: what we agreed, 5 October**
>
> **On 1 December:** customers order ahead up to 7 days, at a chosen hour; stores see scheduled orders
> on the pickers' screen. Includes the order state machine work (3 weeks), tests, load test on 23
> November, and a rollback switch.
>
> **In January (by 29 January):** orders up to 30 days ahead; recurring orders; editing after
> confirmation. Until then, a customer who needs to change an order cancels and reorders.
>
> **Not traded:** test coverage, the load test, the rollback switch.
>
> **What would change this:** if the load test on 23 November finds a problem we cannot fix by the
> 27th, we launch on 14 December and Renata tells Boa Praça on the 27th. Not later.
>
> **Owners:** Renata for the scope and the message to Boa Praça; Henrique for the plan and the
> quality.

## Why each part is there

- **What ships, and what does not, both dated.** The second half is what stops January turning into
  "never".
- **"Not traded"** is quality, written down. It is the one line that protects the team in week seven,
  when the pressure to skip the load test arrives.
- **"What would change this"** is the trigger from lesson 4's risk register, applied to a date: the
  condition, the fallback, and the day by which the bad news will be given. **Bad news given on the
  27th is a plan change; the same news given on 1 December is a broken promise.**
- **Owners**, because the agreement has two halves and each has a person.

## When the agreement is under pressure

It will be. In week five, a director asks whether recurring orders could "squeeze in" for December. The
answer is the note: recurring orders are in January, and moving them into December means moving
something else out, or moving the date. That is lesson 8's "yes, if", with the agreement as the
evidence. **A written agreement turns every new request into a visible trade instead of a quiet
addition.**
