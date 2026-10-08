---
title: Classifying: kind and severity
version: 1
---

A declared incident gets two labels: **what kind** it is, and **how serious**. Kind decides which playbook
applies; seriousness decides who is told and how fast. Both are provisional and both are revised as the
investigation learns more.

**Kind** comes from a fixed list the organisation chooses, so that incidents can be counted and compared.
A list modelled on the common sharing taxonomies has entries such as *unauthorised access*, *malicious
code*, *availability*, *information disclosure*, *fraud* and *policy misuse*. Thursday is **unauthorised
access** (somebody else's credentials, from outside) **with probable information disclosure** (the
transfer to `203.0.113.200`).

**Seriousness** is easiest to agree when it is split into separate questions, as NIST's guidance did with
three impact categories:

| category | the scale | Thursday |
|---|---|---|
| **functional impact**: what stopped working? | none, low, medium, high | **none**: every service kept running |
| **information impact**: what happened to data? | none, privacy breach, proprietary breach, integrity loss | **privacy breach**: `files` holds clients' tax files, which are personal data |
| **recoverability**: what does recovery take? | regular, supplemented, extended, not recoverable | **not recoverable** for what left: a copy outside cannot be called back |

A team that asked only "how bad is it?" might have answered *low*: nothing is down and nobody noticed. The
split shows why that is wrong. **An incident can be silent and severe at once**, and the information row
is the one that brings in the lawyer and the data protection officer, today.
