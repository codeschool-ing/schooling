---
title: Time, and the column that is wrong twice a year
version: 2
---

This section carries one rule that prevents a whole class of bug, and the rule is short:

> **Use `timestamptz`. Not `timestamp`.**

Everything else here is why.

## The four types

| type | holds |
|---|---|
| `date` | a day. No time, no zone |
| `time` | a time of day, with no day and no zone |
| `timestamp` | a date and a time, **with no zone** |
| `timestamptz` | a moment in time, unambiguously |

## What `timestamp` actually stores

`timestamp` stores digits: `2026-10-25 01:30:00`. It does not store where that was, which means it
does not identify a moment.

That is fine while everybody is in one place and never changes clocks. Then daylight saving ends,
and in most of Europe `01:30` happens **twice** on that Sunday morning — once at UTC+01:00 and
once an hour later at UTC+00:00. Two different moments, the same digits, no way to tell them
apart. Sort a list of them and the order is wrong. Subtract two and the interval is an hour out.

And when somebody deploys the same application to a second country, every `timestamp` already
stored becomes ambiguous retroactively, because nothing recorded which zone it meant.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"A timeline of absolute time in UTC, ticked from half past midnight to half past two. Two highlighted points sit on it an hour apart, at one and at half past one UTC, and each drops to a box reading the same local wall-clock time, half past one, one at plus one and one at plus zero. Below, two panels: timestamp, holding the digits 2026-10-25 01:30:00 and nowhere; and timestamptz, holding 2026-10-25 00:30:00 plus zero, a moment converted on the way out.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The Sunday clocks go back in most of Europe. One wall-clock reading, two different moments, an hour apart.</text><text x=\"14\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">absolute time, in UTC</text><path d=\"M14 76 L706 76\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M60 70 L60 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"60\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">00:30</text><path d=\"M200 70 L200 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"200\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">01:00</text><path d=\"M340 70 L340 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"340\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">01:30</text><path d=\"M480 70 L480 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"480\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">02:00</text><path d=\"M620 70 L620 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"620\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">02:30</text><circle cx=\"200\" cy=\"76\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"140\" y=\"112\" width=\"120\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">01:30 local</text><text x=\"200\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">UTC+01:00</text><path d=\"M200 82 L200 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><circle cx=\"340\" cy=\"76\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"280\" y=\"112\" width=\"120\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">01:30 local</text><text x=\"340\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">UTC+00:00</text><path d=\"M340 82 L340 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><rect x=\"14\" y=\"176\" width=\"330\" height=\"74\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">timestamp</text><text x=\"28\" y=\"214\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">'2026-10-25 01:30:00'</text><text x=\"28\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">digits, and nowhere</text><rect x=\"376\" y=\"176\" width=\"330\" height=\"74\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">timestamptz</text><text x=\"390\" y=\"214\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">'2026-10-25 00:30:00+00'</text><text x=\"390\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a moment, converted on the way out</text><text x=\"14\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Sort a column of the first kind and the order is wrong; subtract two and the interval is an hour out. Nothing reports either.</text></svg>", "caption": "The two points are different moments. The type on the left cannot tell them apart, and the day it matters is a day nobody is looking."}
```

## What `timestamptz` stores

Despite the name, **it does not store a timezone**. It stores an absolute moment — internally UTC
— and converts on the way in and out using the session's timezone:

```sql
SET TIME ZONE 'Europe/Lisbon';
INSERT INTO invoices (paid_at) VALUES ('2026-10-25 01:30:00');

SET TIME ZONE 'UTC';
SELECT paid_at FROM invoices;
```

```
        paid_at
------------------------
 2026-10-25 00:30:00+00
```

The same instant, written the way the reader asked for. That is the whole feature: **the moment is
stored once, and every reader sees it in their own terms.** Comparisons, sorting and arithmetic
are all correct because they happen on the absolute value.

The cost is that you have to know what the session's timezone is when a bare string comes in. Say
it explicitly and the ambiguity disappears:

```sql
INSERT INTO invoices (paid_at) VALUES ('2026-10-25 01:30:00+01');
```

## When `date` is right, and when it is a mistake

`date` is correct when the thing genuinely has no time and no zone: a date of birth, an invoice
date, a public holiday. A birthday is the same day everywhere, and storing it as a moment makes
somebody born a day earlier in another timezone.

It is a mistake when the thing is a moment that somebody rounded down to a day for convenience.
`delivered_on date` loses the information that a parcel arrived at 23:50 and not at 00:10 — and
the difference decides which day's report it lands in.

The test is the same as everywhere in this course: **did somebody record a day, or did something
happen at an instant and get truncated?**

## `now()` and its several meanings

```sql
SELECT now();                    -- timestamptz, of the TRANSACTION's start
SELECT clock_timestamp();        -- timestamptz, of right now, moving
SELECT current_date;             -- date, in the session's timezone
SELECT current_timestamp;        -- the standard spelling of now()
```

**`now()` is the transaction's start time and does not move during it.** That is a feature: every
row inserted by one transaction gets the same timestamp, so a batch is coherent. If you want the
actual wall clock inside a long transaction, `clock_timestamp()` is the one that moves.

`current_date` depends on the session's timezone, which means a job running at 23:30 in Lisbon and
a job running at the same moment configured as UTC write **different dates**. For anything that
must agree, store the moment and derive the day at the point somebody reads it.

## Intervals, and the arithmetic

```sql
SELECT paid_at - issued_on::timestamptz AS took FROM invoices;   -- an interval
SELECT now() + interval '30 days';
SELECT date_trunc('month', issued_on);
```

`interval` is a type: `'1 mon 3 days 04:00:00'`. And it is not a fixed quantity, which is the one
surprise:

```sql
SELECT '2026-01-31'::date + interval '1 month';   -- 2026-02-28
SELECT '2026-03-29 00:00'::timestamptz + interval '1 day';
SELECT '2026-03-29 00:00'::timestamptz + interval '24 hours';
```

The last two can differ by an hour across a daylight-saving boundary, because *a day* and
*24 hours* are different things. That is correct behaviour and it catches everybody once.

## The summary, as a rule you can apply without thinking

- **A moment that happened** → `timestamptz`.
- **A calendar day somebody chose** → `date`.
- **A duration** → `interval`, or an integer with the unit in the column name (`timeout_seconds`).
- **`timestamp` without a zone** → only when you are deliberately storing a local wall-clock
  reading that is not a moment, such as "the shop opens at 09:00" in whatever zone the shop is in.
  It is rare, and you should be able to say why.
