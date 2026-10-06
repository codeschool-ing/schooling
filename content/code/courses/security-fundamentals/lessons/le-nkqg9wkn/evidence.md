---
title: Evidence
version: 1
---

An auditor does not take anybody's word for anything. That is not rudeness; it is the job. An audit
exists so that a third party can rely on its conclusion, and a conclusion based on what people said
is only as good as their memory and their honesty. So the auditor's question is always the same:
**show me.**

**Evidence** is anything that shows a control exists and works. It comes in a few kinds, from weakest
to strongest:

| kind | example | why it is weaker or stronger |
|---|---|---|
| **inquiry** | asking ana how access reviews are done | the least reliable: a description, not proof |
| **documents** | the access control policy | shows intent, not practice |
| **records** | last September's signed access review | shows it happened, at least once |
| **observation** | watching the monthly restore test being done | shows it happens, at least while watched |
| **re-performance** | the auditor restores a backup themselves | the strongest: the auditor sees the result directly |

Good evidence is **dated, attributable and kept**: it says when, who did it, and it still exists when
somebody asks a year later. An email saying "done" is weak evidence; a log entry with the date, the
person, and the result is strong.

### Sampling

An auditor cannot check every login, every change, every account. They take a **sample**: twenty-five
accounts out of the list of all accounts, ten firewall changes out of the year's, and check those
thoroughly. If the sample is clean, they conclude the control works; if three of the twenty-five
accounts belonged to people who left months ago, the control has failed, however good the policy
reads. This is why the control must work **every time**, not only for the cases somebody expects to be
looked at.

### This course has been producing evidence all along

Look back at what the earlier lessons left behind:

| lesson | the record | what it proves |
|---|---|---|
| 3 | the risk register, with owners, signatures and review dates | risks are identified and accepted by the right people |
| 5 | the firewall rules file, and the test from every zone | the network is segmented as the policy says |
| 6 | the `sudo` rule naming two commands; the access review | access follows least privilege, and is reviewed |
| 8 | the portal's log with a name on each request | actions are attributable |
| 10 | the purple exercise's findings, filed in the register | detection is tested, and gaps are tracked |
| 12 | the restore test log with dates and times | backups can be restored, within the RTO |

None of it was produced for an auditor. Every item was produced because it made the shop safer or
let somebody decide something. That is the attitude section 02 described: evidence as a side effect
of doing the work properly. The shop's first audit will mostly consist of opening these files.
