---
title: Technical work in the same backlog
version: 1
---

The hardest items to prioritise are the ones whose value is invisible to users: the database upgrade, the refactoring of the billing module, the load test, the migration away from a library that is no longer maintained. Their cost of delay is usually **intangible** in the sense of this lesson's fourth section: little is lost this week, much is lost later. Left to compete with features on a value-only basis, they lose every time, until they become urgent and cost far more.

## Give them a term in the formula

The techniques in this lesson can carry technical work if it is described in their terms:

- In **WSJF**, the third component of cost of delay, *risk reduction and opportunity enablement*, exists for exactly this. The Agenda team's database upgrade scored 13 there, and that is what put it second.
- In **RICE**, the effect can be expressed as reach and impact on the people who are affected when the risk materialises: every patient, if the unsupported database fails.
- In **MoSCoW**, a security patch can be a must-have, because without it the release would be irresponsible.
- In terms of lesson 11, a piece of technical work is often a **risk response**, and its value is the expected cost it removes.

The architect's contribution is to do that translation. "We need to upgrade the database" will lose to "patients want SMS reminders". "The database version we run leaves support in August; after that, a security flaw will have no fix, and the platform holds health data" competes on equal terms.

## Capacity allocation

Some organisations take a second, blunter approach: they **reserve a share of each Sprint's capacity** for technical work and let the team choose what goes into it, outside the feature prioritisation. SAFe calls this capacity allocation; a share around 20% is a common starting point, though no evidence makes that number special. It protects technical work from losing every comparison, and its cost is that the reserved share is not weighed against features at all, so it can be spent on the team's favourite improvements rather than the most valuable ones.

The two approaches combine well: a reserved share for the steady work of keeping the system healthy, and WSJF or RICE for the large technical items that deserve to be weighed against features openly. Lesson 14 is about recording, measuring and negotiating technical debt so that both are argued from evidence.
