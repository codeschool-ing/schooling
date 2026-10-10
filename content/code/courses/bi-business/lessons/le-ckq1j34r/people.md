---
title: People: headcount, turnover and absence
version: 1
---

People are Varanda's largest cost after the goods themselves: R$ 18.75 million in 2025, 19.1% of
sales. **Human resources measures the staff the way operations measures stock — how many, how long
they stay, how much of their time is lost — and every one of those numbers is about named
individuals.** That second fact changes how an analyst handles them, and it comes at the end of this
section.

## Headcount, and the denominator problem

Headcount is the number of people employed, and the first question is: on which day? Retail hires for
Christmas and lets temporary staff go in January, so a count on 31 December and one on 31 January
differ. **For rates over a year, HR uses the average headcount**, the mean of the twelve month-end
counts. Varanda's average for 2025 was 410.

## Turnover

Turnover is the share of staff who left. In 2025, 103 people left Varanda, for any reason:

```localised
=ROUND(103/410*100,1)      25.1
=ROUND(103/410/12*100,1)    2.1
```

**25.1% a year, or 2.1% a month on average.** A quarter of the people who work at Varanda on a given
day will not be working there a year later. In retail that is not unusual, and the number matters
less than its direction and its breakdown: turnover concentrated in one store, or among people in
their first three months, points at a manager or at hiring, and the company total hides both.

Two warnings. First, **there is more than one formula.** Some companies count leavers only; others
average hirings and leavings before dividing; some leave out people who were dismissed, or who left
in their first weeks. Each gives a different rate from the same staff, and comparing Varanda's 25.1%
with a number from a report that used another formula compares nothing. Second, monthly turnover
times twelve is only roughly the annual rate, and in a month with many temporary contracts ending it
is far off.

## Absence and time to hire

**Absenteeism** is hours absent as a share of hours scheduled. Varanda scheduled 870,000 hours in
2025 and lost 23,500 to unplanned absence:

```localised
=ROUND(23500/870000*100,1)      2.7
```

2.7%. **Time to hire** is the days from opening a vacancy to the person's first day; Sônia's team
recorded a median of 34 days in 2025. A store that loses a salesperson in October and waits 34 days
for the next one starts December short-staffed, which is how an HR number becomes a sales number.

## HR data is personal data

Every row behind these rates is a person: their pay, their absences, why they left. A turnover rate
for the company is harmless. **A turnover table for a store with eight employees, broken down by
month, can identify who left and when**, and an absence report by name is medical and disciplinary
information. Under Brazil's LGPD, health data counts as sensitive personal data, with stricter rules
still.

So the BI analyst's rule from lesson 4 applies with extra force: show what the reader needs and no
more, aggregate before showing, and do not publish a breakdown small enough to point at somebody.
`data-governance` lesson 6 is about how personal and sensitive data are handled, and lesson 7 about
the LGPD itself.
