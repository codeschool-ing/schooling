---
title: How an audit runs
version: 1
---

An **audit** is a systematic, independent examination of whether something meets its criteria. In
security, the criteria are usually a standard (ISO 27001), a law, a contract or the organisation's own
policies, and the "something" is a set of controls.

### Internal and external

An **internal audit** is done by people from the organisation itself, but independent of the area being
audited: the person who runs the firewall does not audit the firewall. Its purpose is to find problems
before somebody else does, and to tell management honestly how things stand.

An **external audit** is done by an outside body. A certification audit for ISO 27001 (lesson 14) is
external, by an accredited certification body. So is an audit a large customer demands of its
suppliers, and an inspection by a regulator. Its conclusion is meant for third parties, which is why
its independence matters even more.

### The stages

| stage | what happens |
|---|---|
| **planning** | the scope is agreed: which systems, which sites, which period, against which criteria |
| **fieldwork** | the auditor gathers evidence: interviews, documents, samples, observation |
| **findings** | each gap is written up, with the requirement, what was found and the evidence |
| **report** | the findings, their severity and the overall conclusion go to management |
| **response** | management accepts each finding and commits to a corrective action and a date |
| **follow-up** | at the next audit, the corrective actions are checked |

### What a finding looks like

Findings are graded. The words vary between standards; in ISO 27001 audits they are usually:

- **major nonconformity**: a requirement is not met at all, or a control has failed in a way that
  undermines the system, for example no access reviews have ever been done. It must be fixed before a
  certificate is issued or kept;
- **minor nonconformity**: a requirement is partly met or met inconsistently, for example two of
  twenty-five sampled accounts belonged to people who had left. It needs a corrective plan;
- **observation** or **opportunity for improvement**: nothing is wrong yet, but the auditor sees a risk.

A finding is not a judgement on the person who runs the control. It is information, and the right
response to a finding is the same as the right response to a purple exercise in lesson 10: understand
why, fix the cause, check that the fix worked. Arguing with the evidence, or fixing the one sampled
account and not the process that let it happen, is how the same finding comes back next year.

### Working with auditors

Answer what is asked, accurately, and show the evidence. Do not guess, and do not volunteer
speculation: "I don't know, I will find out and send you the record" is a better answer than an
invented one. And do not hide a problem you know about. An auditor who finds a concealed problem stops
trusting everything else; one who is told about it, with a plan, usually records it as the organisation
managing its own risks, which is exactly what a management system is supposed to do.
