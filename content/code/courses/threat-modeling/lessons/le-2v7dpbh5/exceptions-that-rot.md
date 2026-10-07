---
title: Exceptions that rot
version: 1
---

An accepted risk is a security exception, and **exceptions rot**: they outlive the reason they were
granted, the person who granted them, and sometimes the system they were about. Every organisation
that audits its exceptions finds some that nobody can explain. The habits below exist because the
failures they prevent are the common ones.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l12-timeline\" aria-label=\"A timeline from April 2026 to October 2027. RA-002, accepting T06, decided on 2 April 2026, review due 2 October 2026, overdue on 7 October. RA-001, accepting T14, decided 1 October 2026, review due 1 April 2027. DR-001, the second factor, decided 30 September 2026, review due 30 September 2027.\"><path d=\"M60.0 170.0 L690.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 170.0 L60.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Apr 2026</text><path d=\"M165.0 170.0 L165.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"165.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jul 2026</text><path d=\"M270.0 170.0 L270.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Oct 2026</text><path d=\"M375.0 170.0 L375.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"375.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jan 2027</text><path d=\"M480.0 170.0 L480.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"480.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Apr 2027</text><path d=\"M585.0 170.0 L585.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"585.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jul 2027</text><path d=\"M690.0 170.0 L690.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"690.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Oct 2027</text><rect x=\"61.2\" y=\"32.0\" width=\"210.0\" height=\"16.0\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"53.2\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">RA-002</text><circle cx=\"271.2\" cy=\"40.0\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"268.8\" y=\"72.0\" width=\"420.0\" height=\"16.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"260.8\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">DR-001</text><circle cx=\"688.8\" cy=\"80.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><rect x=\"270.0\" y=\"112.0\" width=\"210.0\" height=\"16.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">RA-001</text><circle cx=\"480.0\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M277.0 24.0 L277.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M277.0 90.0 L277.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M277.0 130.0 L277.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"283.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">7 Oct 2026: RA-002 overdue</text></svg>", "caption": "Each bar is a decision from the day it was made to the day it must be looked at again. The dashed line is the day acceptances.py was run."}
```

### Four ways an acceptance goes bad

| failure | what it looks like | the habit that prevents it |
|---|---|---|
| **no expiry** | "accepted" with no date, renewed by nobody, true forever | every acceptance has a review date, and a program lists the overdue ones |
| **the owner left** | the person who signed it is gone; nobody owns the review | when somebody leaves, their decisions are reassigned on the same day as their accounts are closed |
| **the risk grew** | accepted at R$ 9,000 a year; the system changed and it is now ten times that | triggers in the record, and a review whenever the model changes the element it is about |
| **the compensations lapsed** | "staff only open exams in the console" was true in October and nobody checked in March | the compensating controls are checked at the review, not just the risk |

The second row is the one that surprises people. A decision's owner is a person, and people change
jobs. Vereda's leaving checklist, the one R06 depends on for staff accounts, has a line for it:
*reassign this person's open decisions*. Without that line, RA-001 would be owned, from the day
daniel left, by nobody.

### Renewing is a decision too

When a review comes, renewing an acceptance is allowed, and it is a new decision with a new record:
the estimate looked at again, the compensating controls checked, a new date. What is not allowed
is moving the date in the old file. A renewal that is a one-line edit becomes a habit nobody
thinks about, and a risk accepted for six months in 2026 is still accepted in 2030 because the
date kept moving.

### Counting them

The number of open acceptances, and how many are overdue, is one of the simplest measures of how
a security programme is doing. A count that only grows means risks are being accepted instead of
fixed. A count with overdue entries means the reviews are not happening. Lesson 15 puts that count
on the same page as the other measures of the model.
