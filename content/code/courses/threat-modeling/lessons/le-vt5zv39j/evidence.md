---
title: What counts as evidence
version: 1
---

An auditor's opinion rests on evidence, and evidence has a quality that can be argued about. The
standards for audit evidence vary in their words and agree on the substance: evidence has to be
**relevant** to the claim, **reliable**, and **sufficient** in amount, and it has to cover the
period being audited.

### How it is obtained

There are four ways to obtain it, and they are not equal:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l14-evidence\" aria-label=\"Four ways to obtain evidence, from weakest to strongest. Inquiry: asking somebody, who says staff use a second factor. Observation: watching somebody sign in with one. Inspection: reading the console’s configuration, or a log of 40 sign-ins. Re-performance: the auditor tries to sign in without the second factor and is refused.\"><rect x=\"40.0\" y=\"150.0\" width=\"150.0\" height=\"60.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">inquiry</text><text x=\"115.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">“yes, everybody uses it”</text><rect x=\"210.0\" y=\"115.0\" width=\"150.0\" height=\"95.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">observation</text><text x=\"285.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">watching one sign-in</text><rect x=\"380.0\" y=\"80.0\" width=\"150.0\" height=\"130.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">inspection</text><text x=\"455.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the configuration, a log of 40</text><rect x=\"550.0\" y=\"45.0\" width=\"150.0\" height=\"165.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">re-performance</text><text x=\"625.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the auditor tries, and is refused</text></svg>", "caption": "Inquiry alone is never enough in an audit: what somebody says has to be backed by something the auditor reads or does."}
```

| method | what the auditor does | for C1, the second factor |
|---|---|---|
| **inquiry** | asks somebody | bruno says every staff account uses one |
| **observation** | watches it happen | a receptionist signs in while the auditor watches |
| **inspection** | reads a record or a configuration | the console's authentication settings, and a log of sign-ins |
| **re-performance** | does it again, independently | the auditor tries a staff sign-in without the second factor and is refused |

Inquiry is where every audit starts and where none may finish. What somebody says is the claim; the
other three are the evidence for it.

### Design and operation

A control can be checked two ways. **Design**: would it work, as built? One re-performance answers
that. **Operation**: did it work, every time, across the period? That needs a population and a
sample. If the console logged 1,240 staff sign-ins in October, the auditor picks a sample, say 25,
and checks that each one passed a second factor. One exception in 25 is a finding about operation
even when the design is perfect.

This is the same distinction as a SOC 2 Type I against a Type II in lesson 13, seen from the auditor's
chair.

### What makes evidence reliable

Three questions a careful auditor asks of every item:

- **Who produced it?** A log the system wrote is better than a spreadsheet a person typed. A record
  kept by somebody independent of the control is better than one kept by the person it checks.
- **When was it produced?** Evidence made at the time of the event is better than evidence assembled
  later. A screenshot taken the week before the audit says what was true that week.
- **Could it have been changed?** A record that can be edited without a trace is weaker than one
  where every change leaves a mark.

The threat model scores well on the last two, because it lives in git. The next section reads that
history as an auditor would, including the parts that score badly.
