---
title: Vulnerabilities are not only bugs
version: 1
---

Ask a programmer what a vulnerability is and the answer is a bug in software. That is one kind,
and it is the kind with the best catalogue. It is far from the only kind, and **the cheapest
vulnerabilities to exploit are rarely in the code.**

| kind | example at the shop |
|---|---|
| software | the web server runs a version with a known, published flaw |
| configuration | the portal still accepts the installer's default password |
| process | nobody removes an account when an employee leaves |
| people | staff were never told how a fake invoice email looks |
| physical | the server sits under a desk in an unlocked office |

The configuration row is worth dwelling on. The software may be perfect and up to date, and a
default password, a folder shared with "everyone" or a database listening on the internet makes it
exploitable without any bug at all. Lesson 16 is about checklists that catch exactly that kind.

### The catalogue of known software flaws

Software vulnerabilities that have been found and disclosed get an identifier in the **CVE**
list, Common Vulnerabilities and Exposures. An identifier looks like `CVE-2021-44228`: the year it
was assigned and a sequence number. It is a name and nothing more, and it exists so that a
vendor's advisory, a scanner's report and a news article can all say they mean the same flaw.

Most CVEs carry a **CVSS** score, the Common Vulnerability Scoring System: a number from 0.0 to
10.0 describing how severe the flaw is in general. The bands are:

| score | severity |
|---|---|
| 0.0 | none |
| 0.1 to 3.9 | low |
| 4.0 to 6.9 | medium |
| 7.0 to 8.9 | high |
| 9.0 to 10.0 | critical |

`CVE-2021-44228`, the flaw in the Log4j logging library known as Log4Shell, scored 10.0.

**A CVSS score is severity, not risk.** It describes the flaw in the abstract, without knowing
anything about your shop. It cannot tell whether the vulnerable program is reachable, whether
anything valuable sits behind it, or whether a control already blocks the path. A 9.8 on a
machine with no network access and no data can be less urgent than a 6.5 on the shop's public
checkout page. The previous section's rule applies: a vulnerability is a risk only when a threat
can reach it and an asset sits behind it.

A vulnerability nobody knows about yet, including the vendor, is called a **zero-day**: the
vendor has had zero days to fix it. There is no patch, so the defence is everything else in this
course: layers, least privilege and detection.
