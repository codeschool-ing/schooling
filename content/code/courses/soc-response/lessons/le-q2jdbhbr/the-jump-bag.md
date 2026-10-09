---
title: The jump bag
version: 1
---

The **jump bag** is everything a responder needs, ready before it is needed, so that the first hour of an
incident is spent responding rather than searching. The name comes from the physical bag; much of it is
now digital, and all of it is checked on a schedule.

| item | why it has to exist in advance |
|---|---|
| **the plan, the contact list and the playbooks, on paper or offline** | the systems that hold them may be the ones that are down |
| **an analysis workstation** that is not part of the affected network | evidence should not be examined on a machine the intruder may control |
| **clean, wiped storage** large enough for disk images, and a hardware **write blocker** | lesson 16 needs both, and buying them during an incident takes days |
| **forensic tools, installed and tested**: imaging, hashing, analysis, packet capture | learning a tool during a P1 is how evidence gets damaged |
| **out-of-band communication**: a messaging group or phone bridge that does not depend on company accounts | if email is compromised, the intruder reads the response |
| **break-glass accounts**: emergency administrator access, sealed, used only in a crisis and audited when opened | locking out every admin while containing is a classic self-inflicted outage |
| **custody forms and a log template** | lesson 3's chain of custody starts at the first collection |

The lab you built in lesson 1 is a small version of the second and fourth rows: a machine with the
course's tools installed and tested. In a company, the jump bag has an owner and a monthly check, because a
bag nobody opened since last year holds expired licences, flat batteries and phone numbers of people who
left.
