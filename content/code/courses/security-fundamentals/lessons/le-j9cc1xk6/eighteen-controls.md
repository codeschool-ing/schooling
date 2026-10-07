---
title: Eighteen controls, in order
version: 1
---

The **Center for Internet Security (CIS)** is a non-profit organisation that publishes, among other
things, the **CIS Controls**: a short, prioritised list of the defensive actions that stop the most
common attacks. They began in 2008 as a list compiled by practitioners who looked at what attackers
were actually doing and asked which defences would have stopped them. The current version, **v8.1**,
was published in 2024, and keeps the structure of v8 from 2021: **18 controls**, broken down into
**153 safeguards**.

| # | control | what it is about |
|---|---|---|
| 1 | inventory and control of enterprise assets | know every device you have |
| 2 | inventory and control of software assets | know every program, and allow only what is approved |
| 3 | data protection | know where sensitive data is, and protect it |
| 4 | secure configuration of enterprise assets and software | harden every system from its insecure defaults |
| 5 | account management | every account known, needed and disabled when it is not |
| 6 | access control management | least privilege and MFA (lessons 6, 9) |
| 7 | continuous vulnerability management | find and fix known flaws (lesson 2) |
| 8 | audit log management | collect logs and keep them usable (lessons 10, 11) |
| 9 | email and web browser protections | the two ways attackers most often get in |
| 10 | malware defences | stop and detect malicious software |
| 11 | data recovery | backups that can be restored (lesson 12) |
| 12 | network infrastructure management | keep network devices secure and up to date |
| 13 | network monitoring and defence | watch the network, segment it (lesson 5) |
| 14 | security awareness and skills training | people as a layer (lesson 4) |
| 15 | service provider management | suppliers who hold your data |
| 16 | application software security | software you build or buy |
| 17 | incident response management | a plan, roles, and practice (lesson 10) |
| 18 | penetration testing | test the defences as an attacker would |

### Why the order matters

The list is not alphabetical and not by topic. It runs **roughly in the order a defence should be
built**, and the first two are the clearest example: you cannot protect, patch, configure or monitor
a device you do not know exists. Many incidents start on the machine nobody remembered: an old server
under a desk, a test environment left running, a laptop that left with a former employee. Inventory
is unglamorous, and it comes first because every later control depends on it.

That order is the CIS Controls' particular strength beside the frameworks of lessons 14 and 15.
ISO 27001 and the NIST CSF tell an organisation what a complete programme covers. The CIS Controls tell
it **where to start**, and that is the question a small team actually has.
