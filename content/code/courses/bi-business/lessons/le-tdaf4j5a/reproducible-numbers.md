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

@@fig:l21-path@@

## The cost, and why it is paid

None of this is free. A snapshot per month per report is storage; a versioned query is discipline;
an approval is a person's time a few days before every deadline. For an internal dashboard it is
often more than the question deserves. For a compliance report it is the minimum, and the habit is
worth taking back into internal work wherever a number will be quoted later: **the year-end figures
Helena presents to Varanda's board in lesson 16 are exactly the kind of number somebody asks to see
again**, and a frozen snapshot of 31 December costs one evening in January.
