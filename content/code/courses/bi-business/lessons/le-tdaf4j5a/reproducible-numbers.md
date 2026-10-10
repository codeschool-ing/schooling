---
title: Numbers that come out the same a year later
version: 1
---

An internal report answers a question today. **A compliance report must also answer it again,
identically, whenever somebody asks**: an auditor next year, a regulator in three, the company's own
lawyers in a dispute. "We ran the query again and got a different number" is the answer nobody wants
to give, and on live data it is the answer the query will give.

## Why the same query gives a different answer

The tables a report reads keep changing after the date the report is about. Payments arrive late
and are entered with the date they were made. Loans are renegotiated and their history rewritten. A
customer's record is corrected. None of that is wrong; it is the system keeping the truth up to
date. But the truth on 31 December 2025, as Ipê knew it on 5 January 2026 when it filed, is a
different thing from the truth about 31 December as known today.

Take the twelve loans of the last section. In February 2026, a payment that loan 6's customer made on
20 December, and that a bank file had failed to deliver, was finally entered with its real date. On
the live tables, loan 6 was now 70 days overdue at 31 December instead of 95. Change B7 to 70 and
look at the default share again:

```localised
=ROUND(SUMPRODUCT(C2:C13,D2:D13)/C14*100,1)      3.9
```

**10.5% was filed; the same query on the same date now says 3.9%.** Both are correct. Only one of
them is what Ipê told the regulator, and only one of them can be defended as what Ipê knew when it
filed. If nobody kept the data as it stood on 5 January, the filed number can no longer be produced
by anybody.

## Four things that make a number reproducible

**A frozen snapshot.** On the day of the close, the data the report needs is copied into a table, or
a file, that is never updated again, with the date it represents in its name. The report reads the
snapshot, never the live tables. Corrections that arrive later go into the next period, or into a
formal resubmission if the rule requires one, and the old snapshot stays as it was.

**A versioned definition.** The query that turns the snapshot into the number is kept with a
version, and each submission records which version produced it. When the regulator changes the
rule, or Ipê finds an error in its own query, the new version is added; the old one is not
overwritten, because last year's submissions were made with it.

**Lineage.** For each number, a record of where it came from: which snapshot, which tables in it,
which version of the query. `data-governance` lesson 9 treats lineage in general; here it is the
answer to "where did this 10.5% come from?" in one line instead of a week of digging.

**Who approved it, and when.** A named person checks the report before it goes, and the approval is
recorded with the date and the exact file approved. That is the start of an **audit trail**, the
record of who did what to the data and when, which `data-governance` lesson 10 covers alongside how
long such records must be kept.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Five boxes left to right, joined by arrows: the source systems; the nightly copy; a frozen snapshot dated 31 December 2025; the report, computed with definition version 3; the submitted file, approved by a named person. Under the last three, what each keeps: the snapshot's date, the definition's version, the approver's name and date.\" data-fig=\"l21-path\"><rect x=\"18.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"78.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">source systems</text><text x=\"78.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lending, cards</text><path d=\"M140.0 95.0 L156.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M156.0 95.0 L147.9 98.9 L147.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"158.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"218.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nightly copy</text><text x=\"218.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">changes every day</text><path d=\"M280.0 95.0 L296.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M296.0 95.0 L287.9 98.9 L287.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"298.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"358.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">frozen snapshot</text><text x=\"358.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as at 31 Dec 2025</text><path d=\"M420.0 95.0 L436.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M436.0 95.0 L427.9 98.9 L427.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M358.0 134.0 L358.0 156.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"358.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">never edited</text><rect x=\"438.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the report</text><text x=\"498.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">default: 90+ days</text><path d=\"M560.0 95.0 L576.0 95.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M576.0 95.0 L567.9 98.9 L567.9 91.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M498.0 134.0 L498.0 156.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"498.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">definition v3</text><rect x=\"578.0\" y=\"60.0\" width=\"120.0\" height=\"70.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"638.0\" y=\"88.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">submitted file</text><text x=\"638.0\" y=\"110.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">approved: Fernanda</text><path d=\"M638.0 134.0 L638.0 156.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"638.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">who, when, which file</text><text x=\"18.0\" y=\"30.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">changes</text><text x=\"298.0\" y=\"30.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fixed from here on</text><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">re-run a year later from the snapshot, it gives the same answer</text></svg>", "caption": "The path from the systems to a submitted report. Everything to the right of the snapshot is fixed and recorded, which is what lets the same number be produced again when somebody asks for it."}
```

## The cost, and why it is paid

None of this is free. A snapshot per month per report is storage; a versioned query is discipline;
an approval is a person's time a few days before every deadline. For an internal dashboard it is
often more than the question deserves. For a compliance report it is the minimum, and the habit is
worth taking back into internal work wherever a number will be quoted later: **the year-end figures
Helena presents to Varanda's board in lesson 16 are exactly the kind of number somebody asks to see
again**, and a frozen snapshot of 31 December costs one evening in January.
