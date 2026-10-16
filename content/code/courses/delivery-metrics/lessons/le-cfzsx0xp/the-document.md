---
title: What the postmortem document holds
version: 1
---

A postmortem is a document first and a meeting second. The document is written before the meeting, from the scribe's timeline and the incident channel, by one person, usually the incident commander or a volunteer from the team, and the meeting reviews it. Most organisations use a template; this is a common shape, filled in for 30 September.

## The sections

| section | what it says | for 30 September |
|---|---|---|
| **summary** | three sentences a stranger understands | Release D047 added a retry to card charges. Under month-end load it charged 167 shops twice, 212 charges in all, for 54 minutes. A rollback stopped it; every charge was refunded by 21:10. |
| **impact** | who was affected, how much, for how long, in numbers | 167 shops, 212 duplicate charges, 54 minutes of harm, 229 minutes until fully refunded; support answered 31 calls |
| **timeline** | the scribe's lines, lightly edited | lesson 14's timeline |
| **contributing factors** | every thread, not one root cause | the six of the previous section |
| **what went well** | worth keeping, and worth saying | support asked within three minutes; roles named in one message; rollback took eleven minutes |
| **what was hard** | where the response struggled | sixteen minutes to decide on the rollback; nobody knew the month-end load pattern |
| **action items** | specific, owned, dated | the next section |
| **lessons** | what the team now believes that it did not before | payment retries need idempotency keys, always; month-end is a risky time to release |

## Writing it well

**Write it for somebody who was not there.** A new team member in a year, another team with a similar system. That means no unexplained jargon, times in one zone, and the impact in the users' terms before anything technical.

**Separate the timeline from the analysis.** The timeline says what happened; the factors say why it was possible. Mixed together, the analysis leaks into the timeline as hindsight: "17:20 the faulty release was deployed" was not known to be faulty at 17:20.

**Keep the names on actions and off failures.** "Rafa will add an idempotency key, by 9 October" belongs in the document. "Rafa's retry caused the incident" does not, for the reasons in this lesson's second section.

**Publish it.** Within the team at least, and ideally across the organisation. A postmortem nobody else reads teaches one team; the same document read by five teams with payment systems teaches five. Some organisations hold a regular session where teams read each other's postmortems, and it is one of the cheapest forms of learning there is.

## When to write one

Not for every incident. A common rule is **every SEV1 and SEV2, and any incident somebody asks for**, plus near misses that frightened people. Lesson 13's scale decides most cases; the request rule catches the rest, and it should be honoured even when the incident looked small, because the person asking usually saw something the scale did not.
