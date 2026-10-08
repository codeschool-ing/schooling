---
title: Four kinds, by who reads them
version: 1
---

A common belief is that threat intelligence is a feed of bad addresses. That is one of its four kinds,
and the least durable. **Threat intelligence is knowledge about threats, organised so that somebody can
make a decision with it**, and the four kinds differ in who makes the decision:

| kind | what it says | who reads it | how long it stays true |
|---|---|---|---|
| **strategic** | which threats matter to a sector and why: ransomware against accounting firms grew last year | the board, the security manager | years |
| **operational** | a specific campaign: who, against whom, when, with what aim | the SOC lead, incident responders | weeks to months |
| **tactical** | how the adversary works: their techniques, in a shared vocabulary (lesson 9) | analysts, rule writers | months to years |
| **technical** | the indicators themselves: addresses, domains, file hashes | the SIEM, the firewall | hours to weeks |

The bottom row is the one machines consume and the one that ages fastest: an address used for guessing
this week is somebody's home connection next month. The top rows age slowly and need a person to apply
them. A SOC that only ingests the bottom row has automated the part of intelligence that matters least.

Intelligence is also something you **produce**. Thursday's incident, written up with its addresses, times
and techniques, is operational and technical intelligence about an event nobody else saw from the inside.
