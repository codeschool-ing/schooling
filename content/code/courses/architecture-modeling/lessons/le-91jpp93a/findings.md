---
title: Writing findings somebody will act on
version: 1
---

**A review is judged by what changes afterwards, and what changes depends on how the findings are
written.** A finding that names a feeling, *the boarding sync seems fragile*, is discussed and
forgotten. A finding that names a scenario, a cause, evidence and a next step gets an owner.

## The shape of a finding

| part | what it says | the boarding sync finding |
| --- | --- | --- |
| **title** | the risk in one line | *Two phones uploading scans for one ticket can both board it* |
| **scenario** | which quality scenario is at risk | QS-02, offline boarding, and the rule that a ticket boards once |
| **cause** | the decision or gap behind it | the sync service accepts each upload as it comes; nothing reconciles two scans of one ticket |
| **evidence** | what makes it more than a guess | four reviewers raised it independently; a test with two phones and one ticket boarded twice |
| **severity** | likelihood and impact | medium likelihood (a passenger with a screenshot), high impact (fraud, and a seat counted twice) |
| **recommendation** | what to do, not how to code it | decide which scan wins and alert on the second; add the case to the state table of lesson 4 |
| **owner and date** | who and by when | Boarding team, before the São João release |

## Ranking

A review report leads with the **risk themes**, then the findings ranked by severity, then the
non-risks with their evidence. Fourteen findings of equal weight is not a report; it is a list that
leaves the ranking to the reader, who is the person with the least context.

## What the author hears

Findings are about the design, and the people who made it are in the room. Three habits keep that
productive, all familiar from `architecture-role` lesson 11 and from the blameless postmortems of
`architect-communication`:

- **State the scenario first, then the risk.** *QS-02 can fail when…* is about the system; *you forgot…*
  is about a person.
- **Separate findings from preferences.** A preference, *I would have used a different broker*, is
  labelled as one or left out.
- **Say what is good.** The non-risks with their evidence are part of the report, and they are what
  the team will cite when somebody proposes to change something that works.

## Follow-up

A review's findings go into the same tracker as the team's other work, with their owners and dates,
and the next review starts by reading them. At Carcará, the six station-link findings were closed
before São João; the boarding sync finding became ADR-0022 and a fitness function. **A review whose
findings are not followed up is a meeting**, and the next one will find the same risks.
