---
title: A finding is a question
version: 1
---

1,324 customers have a consent timestamp earlier than the moment their account was created. Read
literally, they agreed to marketing before they existed as customers. Before calling it a defect,
the data can be asked more precisely:

```sql
-- Consent recorded before the account existed: by how much, and on which day.
SET ROLE ipe_owner;
SELECT consent_at::date = created_at::date AS same_day,
       count(*)                            AS customers,
       max(created_at - consent_at)        AS largest_gap,
       count(*) FILTER (WHERE lower(email) IN (SELECT lower(email) FROM sales.customers
                                               GROUP BY 1 HAVING count(*) > 1)) AS duplicates
FROM sales.customers
WHERE consent_at < created_at
GROUP BY 1
ORDER BY 1 DESC;
```

```
ana@lab:~/gov$ psql -f consent-gap.sql
SET
 same_day | customers |    largest_gap    | duplicates 
----------+-----------+-------------------+------------
 t        |      1316 | 15:19:10          |          5
 f        |         8 | 373 days 10:09:52 |          8
(2 rows)
```

The 1,324 split into two groups that have nothing in common:

- **1,316 on the same day**, never more than about fifteen hours apart. The date agrees and the time
  does not. That is the signature of two clocks, or of a time recorded in one place and a date in
  another — something about how the sign-up form wrote its two columns. **The database cannot say
  which**; it can say where to ask: whoever built the form.
- **8 on a different day**, up to a year apart, and **all 8 are duplicate customers**. When those people
  signed up a second time, the new account was given the consent of the first. That one is
  explained, and it is wrong: a consent belongs to the act of giving it, and lesson 7 keeps it as
  an event for exactly that reason.

Five rows of the first group also belong to duplicated addresses, so they appear in both stories.

## Who decides what

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l9-loop\" aria-label=\"The life of a data quality finding. A query measures it. The finding is a question, taken to the owner of the table. The owner decides. The fix happens at the source that made the data. A rule that runs every day keeps it fixed, and its results feed the next measurement.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"82.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">measure</text><text x=\"82.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a query, a count</text><path d=\"M144.0 82.0 L158.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"160.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"222.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ask</text><text x=\"222.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rows, the evidence</text><path d=\"M284.0 82.0 L298.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"362.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">decide</text><text x=\"362.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the owner</text><path d=\"M424.0 82.0 L438.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fix at the source</text><text x=\"502.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the form, the import</text><path d=\"M564.0 82.0 L578.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"50.0\" width=\"124.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"642.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">keep a rule</text><text x=\"642.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every day, recorded</text><path d=\"M 642 114 L 642 160 L 82 160 L 82 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the history of every run is the next measurement</text></svg>", "caption": "Nobody changes data between measuring it and the owner deciding."}
```

Each finding of the last two sections goes to the owner of its table, with the evidence and a
proposed answer:

| finding | owner | decision |
|---|---|---|
| 23 malformed e-mails, 7 more ending in `.con` | head of sales | ask each customer at their next order; stop new ones at the door (section 8) |
| 12 duplicates | head of sales | link each pair, keep both rows until a merge is designed — orders, prescriptions and requests point at both |
| 3 orders in 2027 | head of sales | find the import that wrote them; correct the dates from the source, not by guessing |
| 14 guest orders | head of sales | not a defect; document it (section 9) and make the rule say so (section 7) |
| 1,316 same-day consents | DPO | ask the team that built the form; until then, the event log of lesson 7 is the proof, not this column |
| 8 inherited consents | DPO | the consent of the earlier account is not a consent of the later one; withdraw it from the duplicate |

Two things about that table. **Nobody deletes anything**: a duplicate customer is two rows that the
rest of the database points at, and deleting one breaks an erasure or an access request. And **the
fix happens where the data is made**: correcting three dates by hand fixes three rows, and the import
that wrote them will write the fourth next month.
