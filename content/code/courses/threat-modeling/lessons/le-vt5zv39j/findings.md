---
title: Findings, and what to do with them
version: 1
---

An audit ends in findings, and a finding has a shape. Learning the shape is useful on both sides of
the table: it is how an auditor writes, and it is how a readiness review should write too, so that
what it finds in October reads the way the auditor's report would read in November.

### The five parts

The readiness review of the last section found RA-002 overdue. Written as a finding:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l14-finding\" aria-label=\"The five parts of an audit finding, with RA-002 as the example. Condition: RA-002 was due for review on 2 October and was not reviewed. Criteria: accepted risks are reviewed by their date. Cause: nothing reminded the owner; the check is run by hand. Effect: T06 is accepted on an estimate nobody has checked for six months. Recommendation: run the check on a schedule, and tell the owner.\"><rect x=\"20.0\" y=\"15.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">condition</text><rect x=\"165.0\" y=\"15.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RA-002 was due for review on 2 October; it was not reviewed</text><rect x=\"20.0\" y=\"65.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">criteria</text><rect x=\"165.0\" y=\"65.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">accepted risks are reviewed by their date (questionnaire, question 22)</text><rect x=\"20.0\" y=\"115.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cause</text><rect x=\"165.0\" y=\"115.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing reminded the owner; acceptances.py is run by hand</text><rect x=\"20.0\" y=\"165.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">effect</text><rect x=\"165.0\" y=\"165.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">T06 is accepted on an estimate nobody has checked for six months</text><rect x=\"20.0\" y=\"215.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">recommendation</text><rect x=\"165.0\" y=\"215.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run the check on a schedule, and tell the owner</text></svg>", "caption": "A finding without a cause gets the symptom fixed: somebody reviews RA-002 this week, and RA-001 is overdue in April."}
```

- **Condition**: what is the case. Stated as a fact anybody could check, with dates.
- **Criteria**: what should be the case, and where that was promised. Without criteria there is no
  finding, only an opinion; here it is the questionnaire's answer that accepted risks are reviewed by
  their date.
- **Cause**: why the gap exists. This is the part most often skipped and the one that decides
  whether the fix works.
- **Effect**: what the gap costs, or could. For a security finding, the effect is usually a risk the
  model can already name: T06 is accepted on an estimate nobody has checked for six months.
- **Recommendation**: what would close it, aimed at the cause rather than the condition.

The cause here is that `acceptances.py` only runs when somebody remembers to run it. Fixing the
condition, reviewing RA-002 this week, is necessary and not enough: RA-001 is due in April 2027, and
nothing about April will be different. Fixing the cause means the check runs by itself and tells
the owner. That is lesson 15's subject.

### How serious

Audits grade their findings, with words that vary by kind of audit. A certification audit against
ISO 27001 distinguishes a **major nonconformity**, where a requirement is not met at all or the
system has failed, from a **minor nonconformity**, an isolated lapse in a requirement that is
otherwise met, and both from an **observation** or **opportunity for improvement**, which requires
nothing. A second-party audit like the insurer's uses whatever its contract says, often high,
medium and low.

The grade follows the evidence. RA-002's late review is an isolated lapse in a process that exists,
with two other records that are in order: a minor finding, or a medium. If none of the three
acceptances had a review date at all, the same condition would be about the absence of a process,
and graded higher.

### The response

Every finding gets a **management response**: agree or disagree, what will be done, by whom and by
when. It is written by the audited side and attached to the report. For RA-002:

| | |
|---|---|
| response | agreed |
| action | review RA-002 with daniel; run `acceptances.py` every Monday and send its output to each owner |
| owner | ana |
| date | 31 October 2026 |

Disagreeing is allowed, and sometimes right, when the criteria were misread or the evidence was
incomplete. It has to be argued with evidence, in the same shape.

### Back into the model

**A finding is information about the model**, and the last step is to put it there. Each one
lands somewhere the course has already built:

| what the finding says | where it goes |
|---|---|
| a threat nobody had listed | `threats.csv`, as a new id, and then through requirements and estimates |
| a control that does not work as designed | its requirement's verification, which was wrong, and its risk's estimate, which was too low |
| a decision that was not kept | `decisions/`, as a new record that supersedes the old one |
| a process that only runs when remembered | the model's own tooling, so the check runs by itself |

A finding filed in an audit folder and closed by an email is a finding that will be found again
next year. A finding that changed the model is one the model will remember.
