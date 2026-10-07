---
title: The risk register
version: 1
---

Lessons 3 to 11 produced a set of files: threats, requirements, risks, controls, a plan. A **risk
register** is what an organisation calls the place where all of that comes together, one line per
risk, with **who owns it, what was decided, and when it will be looked at again**. Most
organisations keep one, many of them in a spreadsheet nobody has opened since the audit.

### What a line in it holds

| field | why it is there | at Vereda |
|---|---|---|
| **id and description** | to point at it from everything else | T14, a crafted PDF attacking a clinic computer |
| **owner** | one person, by name, who answers for it | daniel |
| **estimate** | expected loss, and the bad year when it matters | R$ 9,000 a year; R$ 388,419 one year in a hundred |
| **decision** | mitigate, eliminate, transfer or accept | accept |
| **the record of the decision** | where the reasoning lives | RA-001 |
| **review date** | when somebody must look again | 2027-04-01 |
| **status** | open, decided, done, closed | decided |

The owner field is the one that does the work. **A risk owned by "IT" or "the team" is owned by
nobody**, and when its review date comes there is no one whose job it is to notice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-lifecycle\" aria-label=\"The life of a risk in the register. Identified, then estimated, then decided: mitigate, eliminate, transfer or accept. A mitigation is built and verified; a transfer is signed with a contract; an acceptance is signed by its owner with a review date. All of them arrive at review, and a review sends the risk back to be estimated again or closes it.\"><defs><marker id=\"l12-lifecycle-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-lifecycle-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identified</text><rect x=\"160.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estimated</text><rect x=\"300.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decided</text><rect x=\"450.0\" y=\"10.0\" width=\"250.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mitigate or eliminate: built, verified</text><rect x=\"450.0\" y=\"60.0\" width=\"250.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">transfer: a contract signed</text><rect x=\"450.0\" y=\"110.0\" width=\"250.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">accept: signed, with a review date</text><rect x=\"300.0\" y=\"190.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reviewed</text><rect x=\"160.0\" y=\"190.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">closed</text><path d=\"M130.0 50.0 L160.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M270.0 50.0 L300.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M410.0 45.0 L430.0 45.0 L430.0 30.0 L450.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M410.0 50.0 L450.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M410.0 58.0 L430.0 58.0 L430.0 130.0 L450.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M575.0 150.0 L575.0 210.0 L410.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M300.0 210.0 L270.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M355.0 190.0 L355.0 160.0 L215.0 160.0 L215.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-lifecycle-tm-ah-amber)\"></path><text x=\"285.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">estimate again</text></svg>", "caption": "Every path through the register ends at a review. A risk that reached \"decided\" and stopped there is a risk nobody is watching."}
```

### Vereda's register is its repository

Vereda does not keep a separate spreadsheet. Its register is the files of the earlier lessons:
`threats.csv` for the ids and descriptions, `risks.csv` for the estimates, and a folder of decision
records for the owner, the decision, the reasoning and the review date. Every change is a commit
with a date and an author. The advantage over a spreadsheet is not the format; it is that **the
register changes in the same place, and in the same review, as the system it describes**. Lesson 15
uses exactly that.

### Every risk has a decision, including "not yet"

A register with blank decision cells is a list of worries. The rule at Vereda is that every risk on
it has one of the four decisions, or the explicit entry *not decided, due by* a date, with an owner.
That last form is allowed and useful: it says somebody knows the decision is missing and when it
will be made.
