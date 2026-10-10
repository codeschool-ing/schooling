---
title: Health data is sensitive data
version: 1
---

Varanda's sales data says somebody bought a hose. Jacarandá's data says somebody has heart failure,
was admitted on a Tuesday, and came back three weeks later. **Brazil's data protection law, the
LGPD, puts data about health in its own category of sensitive personal data** (art. 5), with
stricter conditions on its use than an address or a purchase history, and the national authority,
the ANPD, enforces it. `data-governance` lessons 6 and 7 cover the law itself. This section is
about what it does to the everyday work of a health analyst, which is mostly three habits.

## Aggregate before anything leaves the system

A hospital's clinical system holds the patient's record, and the doctors and nurses treating a
patient read it there, under access rules the system enforces. **Analysis almost never needs a
patient's identity**, so the first habit is to bring counts out of the clinical system and leave the
names inside it.

The bed board in the section on patient flow is an example. Cláudia needs to know which patient goes to which
bed, and she finds that in the clinical system, where her role allows it. The board itself shows
counts per ward: 7 waiting, 1 bed short. A screen on the wall of the bed management office is seen
by everyone who walks past, and nothing on it names anybody.

## Small cells identify people

Aggregating is not enough when the groups are small. A health department publishes admissions by
town and cause, and one row reads: a town of 3,000 people, 2 admissions for HIV in 2025. **In a
town of 3,000, a count of 2 is not anonymous**: neighbours know who went to Campinas for treatment
twice that year, and the published table confirms what they suspected.

The usual answer is **small-cell suppression**: any count below a threshold is replaced by a
symbol, such as "<5". The threshold is the publisher's decision, written in its rules; five and ten
are common. A suppressed table looks like this:

| cause | admissions |
|---|---|
| heart failure | 12 |
| pneumonia | 17 |
| HIV | <5 |
| total | 31 |

And it gives the cell away. The total is there, and so are the other two causes, so anybody can
subtract:

```localised
=31-12-17      2
```

**Suppressing one cell is useless if the total and the other cells still let it be computed.** The
fix is to suppress a second cell too (complementary suppression), to round the total, or to merge
small towns into a region before publishing. A dashboard that lets its user filter down to one
town and one cause recreates the problem on every click, which is why health dashboards apply the
threshold to whatever the filter produces and not only to the default view.

## Access by role

The third habit is that access follows the job. Débora needs admission-level data to build the
readmission rate, because a readmission is the same patient twice, and she cannot count it from
totals. She works with a version of the data where the patient's name and document numbers are
replaced by a code, the same code each time the patient appears. That is **pseudonymised** data:
she can link the two admissions without knowing whose they are. It is still personal data under the
LGPD, because the hospital holds the key that turns the code back into a name; lesson 21 takes
up the difference between that and anonymised data.

The finance team sees costs per ward and per procedure and no diagnoses. The ward managers see
their own ward. The board sees the monthly indicators. None of that is unusual, and all of it has
to be decided and written down before the first dashboard is published, because a dashboard
shared by link reaches whoever the link reaches.

## What it does to the four questions

Health is the industry where the third of lesson 17's questions, the data and what is odd about it,
changes the other three. A good indicator that needs patient-level data on a screen is often a worse
choice than a slightly cruder one that does not. The analyst who arrives from retail, where the
worst leak is a sales figure, has to learn that here the worst leak is a person.
