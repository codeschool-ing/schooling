---
title: Severity, decided by impact
version: 1
---

A severity level answers one question for everybody at once: **how much else should stop for this?** It decides who is woken, who is told, how often updates go out and whether other work pauses. That is why it has to be decided quickly, by a simple rule, and revised freely.

## A scale for the Billing team

Most organisations use four or five levels, numbered from the worst. Here is a scale the Billing team might use; the exact words matter less than having them written down before the first incident.

| level | the users' experience | examples for Billing | response |
|---|---|---|---|
| **SEV1** | many users harmed, money or data at risk, no workaround | shops charged twice; invoices issued with wrong amounts | everybody needed, now; leadership told; updates every 30 minutes |
| **SEV2** | many users affected, a workaround exists, or few users seriously harmed | card payments failing for one card brand; statements delayed | on-call and the owning team; updates every hour |
| **SEV3** | a feature degraded, most users unaffected | the export of last year's statements is slow | handled in working hours; one update when resolved |
| **SEV4** | cosmetic or internal | a typo on the invoice footer | a normal ticket, not an incident |

## Impact, not cause

The scale says nothing about **why** something broke, and that is deliberate. Severity is decided in the first minutes, when the cause is unknown; tying it to cause would mean waiting. It is also a statement about the users, which keeps the response pointed at them: a one-line configuration mistake that double-charges shops is a SEV1; an elaborate failure in an internal batch job nobody depends on is a SEV3.

## Decide fast, revise freely

**When in doubt, pick the higher level.** Downgrading a SEV1 to SEV2 after ten minutes costs a few people an interrupted evening. Upgrading a SEV3 to SEV1 after an hour costs the users that hour without the right people on it.

Severity is revised as facts arrive, and each revision is recorded with its time. An incident that starts as "a shop says it was charged twice", SEV2, becomes SEV1 when the count reaches dozens. That is not a mistake in the first call; it is the process working.

## Severity in the numbers

Severity also connects this part of the course to the DORA metrics. Lesson 5 asked teams to decide **what counts as a failure** before looking at the change failure rate, and a common answer is "any deployment that causes an incident of SEV2 or worse". Lesson 7 showed what happens when that line is drawn afterwards. Write it down with the scale.
