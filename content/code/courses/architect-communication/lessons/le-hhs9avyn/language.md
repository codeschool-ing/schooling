---
title: The language of an incident
version: 1
---

**Under pressure, people write the way they feel, and incident messages written that way are vague,
alarming and full of blame.** A few habits, decided in advance and kept in a template, make the words
calm and accurate when the people writing them are not.

## Words that cause trouble

| written in the moment | what is read | write instead |
|---|---|---|
| "minor issue" | they don't know how big it is, or they're hiding it | "most customers cannot check out" |
| "should be fixed soon" | a promise | "next update by 19:45" |
| "caused by Paulo's job" | Paulo did something wrong | "a background job" |
| "the database died" | data was lost | "the database stopped accepting connections; no data was lost" |
| "we think it might be the network" | it is the network | nothing, until it is confirmed |
| "back to normal" | permanently fixed | "working normally since 19:41; we are monitoring" |

The pattern in the right-hand column: **say the effect, say what is known, say when the next word
comes, and name no one.**

## Times, with the zone

Marola is in Recife, its cloud provider's dashboard shows UTC, and one of its clients has stores in two
time zones. "Since 22:10" in an incident channel was read by one engineer as Recife time and by
another as UTC, and for ten minutes they were looking at different hours of logs. **Every time in an
incident message carries its zone, or the template says once, at the top, which zone all times are
in.** Marola's template now says "all times Recife (UTC−3)".

## Severity, in words people agree on

"Is this a big one?" is the question asked most often in an incident channel. A small table of severity
levels, agreed beforehand, turns it into a label:

| level | means | example |
|---|---|---|
| **SEV1** | a core function is down for most customers | 6 March: checkout down |
| **SEV2** | a core function is degraded, or down for some | Friday-evening timeouts for 2% |
| **SEV3** | a minor function is affected; a workaround exists | order history slow to load |

The exact levels matter less than having them before the incident. A label decided in calm is believed
in a crisis; a label invented during one is argued about.

## Write the template in calm

Everything in this lesson is easier with a template ready: the four-line update, the support sentence,
the leadership line, the summary's five blocks, the zone. Marola's lives in the incident runbook, and
**the communications lead's first action is to open it**, not to start writing from a blank page with
adrenaline in charge.
