---
title: Timeliness: as of when?
version: 1
---

**Timeliness asks whether the data is recent enough for the question it is asked.** Every file is
a photograph taken at some moment, and the moment is rarely written on it. A customer file
exported in the morning is complete for everything that happened before breakfast and silent
about everything after.

The most useful question to ask of any file is therefore **as of when?** The customer file does
not say. The website writes its sign-up dates in a format that sorts properly, so its newest one
is a fair estimate:

```
ana@lab:~/clean$ psql -c "SELECT max(signed_up) FROM raw.customers WHERE signup_channel = 'site'"
    max     
------------
 2025-12-10
(1 row)
```

The last website sign-up the CRM knows about is 10 December. The orders run to 31 December. Any
customer who signed up in those three weeks and then bought something has orders in one file and
no account in the other. Counting the orders whose customer is missing:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS orders, count(DISTINCT customer_id) AS customers FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id)"
 orders | customers 
--------+-----------
    246 |        32
(1 row)
```

246 orders from 32 customers belong to nobody the customer file knows. By month:

```
ana@lab:~/clean$ psql -c "SELECT left(ordered_at, 7) AS month, count(*) AS orders FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id) GROUP BY 1 ORDER BY 1"
  month  | orders 
---------+--------
 2025-01 |     19
 2025-02 |     18
 2025-03 |     15
 2025-04 |     24
 2025-05 |     13
 2025-06 |     26
 2025-07 |     22
 2025-08 |     19
 2025-09 |     13
 2025-10 |     16
 2025-11 |     16
 2025-12 |     45
(12 rows)
```

Every month has some, between 13 and 26, and December has 45. The picture by day shows where the
extra ones start:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-export-gap\" aria-label=\"Orders per day in December 2025 whose customer is missing from customers.csv. Up to the tenth, the day the customer file was exported, half the days have none and no day has more than two. From the thirteenth on, every day has between one and four.\"><path d=\"M70.0 50.0 L70.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 240.0 L70.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 202.0 L690.0 202.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 202.0 L70.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M70.0 164.0 L690.0 164.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 164.0 L70.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"164.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M70.0 126.0 L690.0 126.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 126.0 L70.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"126.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M70.0 88.0 L690.0 88.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 88.0 L70.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M70.0 50.0 L690.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 50.0 L70.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders with no customer</text><path d=\"M70.0 240.0 L690.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 240.0 L80.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M160.0 240.0 L160.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"160.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M260.0 240.0 L260.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"260.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M360.0 240.0 L360.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M460.0 240.0 L460.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"460.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M560.0 240.0 L560.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M680.0 240.0 L680.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><text x=\"380.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">day of December 2025</text><rect x=\"72.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"112.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"132.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"152.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"232.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"312.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"332.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"352.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"372.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"392.4\" y=\"88.0\" width=\"15.2\" height=\"152.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"412.4\" y=\"88.0\" width=\"15.2\" height=\"152.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"432.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"452.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"472.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"492.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"512.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"532.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"552.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"572.4\" y=\"126.0\" width=\"15.2\" height=\"114.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"592.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"612.4\" y=\"88.0\" width=\"15.2\" height=\"152.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"632.4\" y=\"202.0\" width=\"15.2\" height=\"38.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"652.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"672.4\" y=\"164.0\" width=\"15.2\" height=\"76.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M270.0 240.0 L270.0 62.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"270.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">customers.csv exported</text></svg>", "caption": "The customer file stops on 10 December and the orders do not. After that line, a new customer's orders have no account to belong to."}
```

**On this point the file is not wrong; it is old.** Every account it lists is there, and the
missing ones simply arrived after the photograph. Asking the CRM team for an export taken after
31 December brings those customers back, and no amount of cleaning could have.

## And the orphans that are not about time

The months before December have orphans too, at a steady rate, and those customers were not
new. Asked, the CRM team explains that twelve accounts were deleted at their owners' request, as
the LGPD lets anybody ask. The orders stay, because a sale is a fiscal record; the person does
not. Lesson 11 decides what a report should do with orders like those, and `data-governance`
lesson 7 is about the law behind them.

Two causes, one symptom. That is common enough to make a habit of: **when a rule fails, split the
failures by something — a month, a channel, a source — before deciding what they mean.** A
uniform rate usually means one cause everywhere, and a spike means something happened on a day
that somebody can name.

## Latency and age

Two numbers describe timeliness and they are worth keeping apart:

- **latency** is how long after an event the data shows it. The orders file shows an order
  within the day; the CRM, for whoever reads this export, shows a new customer up to three weeks
  late;
- **age** is how old the newest record is at the moment you use it. On 5 January the CRM export is
  26 days old.

Which one matters depends on the question again. For a yearly report the age of a customer file
hardly matters, so long as it was taken after the year ended. For a list of customers to call
this afternoon it is everything.
