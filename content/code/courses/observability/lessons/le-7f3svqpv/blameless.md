---
title: Why the postmortem is blameless
version: 1
---

A **postmortem** is the written review of an incident: what happened, why, what it cost, and what will
change. **Blameless** means it looks for the conditions that made the failure possible, and never for a
person to hold responsible.

That is not kindness, it is method. An incident review depends on people saying exactly what they did,
including the command they ran without checking and the warning they dismissed. **If saying so can
cost them, they will not say it**, and the review will explain the incident with the facts that are
safe to admit, which are rarely the useful ones. A team that blames gets shorter postmortems, fewer
reported near-misses, and the same incidents again.

The second argument is that blame is usually wrong on the facts. **A person made a mistake because the
system let them**: the release had no canary, the rollback was not documented, the alert fired twenty
minutes late, the dangerous command looked like the safe one. Replacing the person changes none of
that, and the next person makes the same mistake. Asking *how did the system make this easy?* finds
something to change; asking *who did this?* finds somebody to blame and stops.

What blameless does not mean:

- **It does not mean nobody did anything.** The postmortem names actions and decisions plainly, with
  times; it describes them as the reasonable choices they looked like with what was known then.
- **It does not mean no accountability.** People are accountable for taking part honestly and for
  the actions they take on afterwards.
- **It does not excuse negligence or bad faith**, which are rare, and are a matter for managers, not
  for the incident review.

The test of a blameless culture is what happens to the person who causes the next incident. If they
write the postmortem themselves, in detail, and are thanked for it, it is working.
