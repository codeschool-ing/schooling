---
title: The blameless postmortem
version: 1
---

**A blameless postmortem asks how the system allowed a mistake, not who made it.** "Ana deployed a bad
configuration" is true and useless: the next person will deploy one too. "A configuration change reached
production without a plan anybody read, and nothing tested it" is a finding with a fix. Blame makes people hide
what they did, and a postmortem written from hidden facts finds nothing; that is the practical argument, before
any argument about kindness.

## The document

The shop writes one for every SEV1 and SEV2, within a week, with these headings:

| heading | what goes in it |
|---|---|
| summary | three sentences: what happened, how long, who was affected, with numbers |
| impact | the SLO's budget spent (lesson 13), orders affected, money if any |
| timeline | from the evidence, as the last section built it, in UTC |
| what went well | it always has entries, and they are worth keeping |
| what went badly | the findings, each a fact about the system |
| where we got lucky | the things that would have made it worse and did not happen |
| actions | each with an owner and a date, and each tied to a finding |

For the payment incident, the impact line reads: "Between 14:12 and 14:18 UTC, 85 of 240 checkouts (35%) needed
a payment retry; all completed." The two counts come straight from the last section's transcript. Because every
order completed, no request failed, and the availability SLO of lesson 13 spent none of its budget: this was a
latency incident, and lesson 13's latency indicator is where it would show.

## Findings that lead somewhere

A finding is useful when an action can follow it. Three from this incident:

- **The alert's duration was longer than the incident.** Action: compare ten minutes with the history of the
  last three months of retries, and decide whether five minutes would page on noise.
- **Nobody knew until a customer wrote.** Action: route lesson 13's slow-burn policy to the ticket channel, so a
  burst like this one is at least seen the same day.
- **The retry logic hid the failures from customers.** That went well, and is kept.

**An action without an owner and a date is a wish.** The shop reviews last month's actions at the start of every
postmortem; an action still open after two reviews is either done, or dropped on purpose and written down as
dropped, so that the list of actions stays a list of things somebody is actually doing.

## "Root cause"

Postmortems often have a heading for the root cause, and the shop's does not. Incidents in a system of this size
rarely have one cause: the payment service was slow, **and** the retry was set to five seconds, **and** the alert
waited ten minutes, **and** it was a Friday. Naming one of them as the root makes the others look like
background. Listing contributing factors keeps all of them in front of the people who can fix them.
