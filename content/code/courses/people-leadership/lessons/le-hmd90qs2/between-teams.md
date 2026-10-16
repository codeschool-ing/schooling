---
title: Conflict between teams, and how to escalate together
version: 1
---

Conflict between teams looks different from conflict between people and is often more damaging,
because each side is defending its own team's goals, which are legitimate. **The usual failure is not
the disagreement itself but how it travels**: complaints in each team's channel, escalation behind the
other team's back, and a manager above both who hears two incompatible stories at different times.

## Agenda and Payments

Lesson 7's tally showed that dependencies on Payments came up in five of seven people's notes. The
specific problem was the new confirmations work: Agenda needed Payments to expose an endpoint saying
whether a clinic's subscription allowed automatic confirmations, and Payments kept moving the date.
Agenda's engineers complained among themselves that Payments did not care about anybody else's plans.

Renata met Bia, the engineering manager of Payments, and heard the other side. Payments was in the
middle of a migration that the finance team had made a legal priority: new invoicing rules from the
tax authority, with a fixed date. **From inside Payments, Agenda's request was one of six requests
from other teams, and the only fixed thing on their roadmap was the law.**

## The wrong ways to escalate

Two things Renata could have done, and did not:

- **Escalate alone.** Go to Otávio, her own manager, and ask him to push Payments. Payments reported to
  a different director, Cláudia, so Otávio would have taken it to Cláudia, who would have heard Agenda's
  version first and Bia's second, from her own report, defensively. A dispute escalated by one side
  arrives as an accusation.
- **Work around it.** Have an Agenda engineer build the check directly against the Payments database.
  It would have worked for a month and then broken when the migration changed the schema, and it would
  have made the relationship between the teams worse for a year.

## Escalating together

What Renata and Bia did instead was write one page together, describing the disagreement as a shared
problem, with both teams' constraints in it:

| section | content |
|---|---|
| the decision needed | when Payments can deliver the subscription endpoint Agenda's confirmations need |
| Agenda's constraint | confirmations are promised to the clinics' association for March |
| Payments' constraint | invoicing changes have a legal date in February; the team is fully on them until then |
| the options | (a) the endpoint after February; (b) a simpler, temporary endpoint in January, at the cost of a week of Payments' time; (c) Agenda ships confirmations without the subscription check, for all clinics, and adds it later |
| what each of us recommends | Renata: (b). Bia: (a), with (c) as a fallback |

They took it together to the person whose job it was to decide between the two teams' priorities:
Otávio and Cláudia, in one meeting. **The page let the two directors decide on the facts rather than on
whose manager spoke first.** They chose (c) for March and (a) after February, and both teams heard the
decision at the same time, from the same people.

## Escalation is not failure

Many managers treat escalating as admitting they could not solve a problem. Between teams, it is often
the correct move, because neither manager has the authority to trade one team's priorities against
another's. **What makes escalation healthy is that both sides do it together, with the disagreement
written down fairly**, so that the people above decide rather than referee.

The day after the decision, Renata told the Agenda team what had been decided and why, including the
legal date Payments had been working against. The complaints in the channel stopped, because the
reason had stopped being invisible.
