---
title: Forensics and AppSec
version: 1
---

The last two families sit at opposite ends of a system's life: one investigates after something has gone
wrong, the other works to stop it going wrong in the first place.

### Digital forensics

**Digital forensics** is reconstructing what happened from the evidence a system left behind: disk images,
memory captures, logs, network recordings. It is the investigation that follows an incident, and its
results may end up in a court, which shapes the whole discipline.

| principle | why |
|---|---|
| **preserve the evidence** before analysing it | analysing the original changes it; work on a verified copy |
| **verify every copy** with a hash | lesson 1's checksum and lesson 12's proof, used to show the copy is the original |
| **keep a chain of custody** | a record of who held the evidence, when, and what they did, so nobody can say it was altered |
| **report facts, not guesses** | the report states what the evidence shows and how confident that is |

The work is careful and slow by design. A forensic analyst's first job is often in a SOC or an incident
response team, specialising later; some come from law enforcement. `soc-response` lessons 16 to 18 cover
image acquisition, analysis and traffic analysis.

### Application security

**AppSec** is security built into software: helping developers write code that resists attack, reviewing
designs and code, and running security tests in the build pipeline so that problems are found before
release rather than after.

| task | what it means | lessons |
|---|---|---|
| **threat modelling** | before building, ask what could go wrong and design against it | 2, 3 |
| **secure code review** | read code looking for the mistakes attackers use, such as lesson 8's missing check | 8 |
| **security testing in the pipeline** | automated checks on every change, like lesson 16's checklist run nightly | 16 |
| **developer enablement** | libraries, guidance and training that make the secure way the easy way | 4 |

AppSec people are usually developers who became interested in security, or security people who learnt to
code well. It is close to the **DevSecOps** role the `devsecops` track leads to. `secure-code` teaches the
developer's side and `threat-modeling` the design side.
