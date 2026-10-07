---
title: Publishing counts
version: 1
---

Most releases of personal data are not rows at all: they are counts. Sales by city, prescriptions by
category, customers by age band. A count looks anonymous by construction — it is a number, not a
person — and a small count is the exception that makes it not so. "One customer in Belém had a
psychiatric prescription this month" is a statement about one person, and in a city where somebody
knows who shops at Ipê, it is a disclosure.

The rule that handles it is old and simple: **a count below a threshold is not published as the
number.** Ipê's regional report, with a threshold of ten:

```sql
-- Customers with a psychiatric prescription issued in June 2026, by city.
-- A count below 10 is published as "<10", never as the number.
SET ROLE ipe_owner;
SELECT c.city,
       CASE WHEN count(DISTINCT p.customer_id) < 10 THEN '<10'
            ELSE count(DISTINCT p.customer_id)::text END AS customers
FROM health.prescriptions p
JOIN sales.products pr USING (product_id)
JOIN sales.customers c USING (customer_id)
WHERE pr.category = 'psychiatric' AND p.issued_on >= DATE '2026-06-01'
GROUP BY c.city ORDER BY c.city;
```

```
ana@lab:~/gov$ psql -f report.sql
SET
      city      | customers 
----------------+-----------
 Belo Horizonte | 22
 Belém          | <10
 Brasília       | 16
 Campinas       | 20
 Curitiba       | 25
 Florianópolis  | <10
 Fortaleza      | <10
 Goiânia        | <10
 Manaus         | <10
 Natal          | <10
 Niterói        | 11
 Porto Alegre   | 19
 Recife         | 14
 Rio de Janeiro | 50
 Salvador       | 16
 Santos         | 13
 São Paulo      | 105
 Vitória        | 10
(18 rows)
```

Six cities show `<10`: the reader learns that there were some, and not how many, in Belém, Manaus,
Goiânia, Natal, Fortaleza and Florianópolis. Vitória, at exactly 10, is published.

## The details that undo it

Suppression is easy to write and easy to defeat, and three mistakes recur:

- **the total gives the cell back.** If the report also printed the national total, subtracting every
  published city from it recovers the sum of the suppressed ones, and with one suppressed cell, that
  cell exactly. Totals are computed over what is published, or suppression is applied to a second
  cell too.
- **two reports differ by one person.** A report for June and one for "June except the last day",
  both published, can show a single prescription in the difference. Thresholds apply to every cut a
  reader can make, including the cut between two releases.
- **the threshold is a number somebody chose.** Ten is common for health statistics and has no deeper
  justification than being common; a dataset about a rare condition may need more. Write down what
  the threshold is and why, beside the report, so the next person changes it on purpose.

**Counts are the safest form a release takes** when they are coarse enough and checked like this —
which is why, when a team is asked for "the data", the first question worth asking back is whether
the counts would do.
