---
title: A scorecard: one rule, one number
version: 1
---

**A dimension is a heading; a rule is something a query can check.** "The data should be
complete" cannot be run. "Every customer has an e-mail address" can, and it returns a number.
The step from one to the other is the most useful thing this lesson teaches, because it turns an
opinion about the data into a measurement somebody can repeat next month.

The four dimensions in this lesson's title are the oldest core of the subject. Most frameworks
add the two the previous sections already used — validity and uniqueness — and the list of six
that DAMA UK published in 2013 is the one you are most likely to meet. The names matter less than
the habit of **writing one rule per question you care about**, and Ana writes one for each:

```schooling-example
{
  "language": "sql",
  "file": "scorecard.sql",
  "parts": [
    {
      "code": "-- One rule per dimension, and one number per rule.\nWITH rules AS (\n  SELECT 'completeness' AS dimension, 'the customer has an e-mail' AS rule,\n         count(*) AS tested, count(*) - count(email) AS failing\n  FROM raw.customers\n",
      "note": "**Completeness.** `count(email)` skips the NULLs and `count(*)` does not, so the difference is the number of blanks. Every customer is tested, because every customer should have an address for this purpose."
    },
    {
      "code": "  UNION ALL\n  SELECT 'validity', 'a birth year has four digits',\n         count(*), count(*) FILTER (WHERE birth_year !~ '^[0-9]{4}$')\n  FROM raw.customers WHERE birth_year IS NOT NULL\n",
      "note": "**Validity.** A regular expression says what a well-formed year looks like: four digits and nothing else. Only the rows that have a year are tested, so a blank is not counted twice."
    },
    {
      "code": "  UNION ALL\n  SELECT 'accuracy', 'a birth year is not the form''s 1900',\n         count(*), count(*) FILTER (WHERE birth_year = '1900')\n  FROM raw.customers WHERE birth_year IS NOT NULL\n",
      "note": "**Accuracy.** The rule names the placeholder outright. It cannot find an inaccurate year it does not know about, which is the limit of every accuracy rule written without a second source."
    },
    {
      "code": "  UNION ALL\n  SELECT 'consistency', 'the order''s customer is in the CRM',\n         count(*), count(*) FILTER (WHERE NOT EXISTS (\n           SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))\n  FROM raw.orders o\n",
      "note": "**Consistency between files.** An order whose customer is missing from the customer file fails. Every order is tested."
    },
    {
      "code": "  UNION ALL\n  SELECT 'uniqueness', 'an order id appears once',\n         count(*), count(*) - count(DISTINCT order_id)\n  FROM raw.orders\n",
      "note": "**Uniqueness.** Rows less distinct order numbers is the number of extra copies, not the number of orders affected."
    },
    {
      "code": "  UNION ALL\n  SELECT 'timeliness', 'the CRM knows the last week''s buyers',\n         count(DISTINCT customer_id), count(DISTINCT customer_id) FILTER (WHERE NOT EXISTS (\n           SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))\n  FROM raw.orders o WHERE ordered_at >= '2025-12-25'\n",
      "note": "**Timeliness.** Of the customers who ordered in the last week of the year, how many the CRM does not know yet. Text comparison is safe here because both date formats in `ordered_at` start with the year."
    },
    {
      "code": ")\nSELECT dimension, rule, tested, failing,\n       round(100.0 * failing / tested, 1) AS pct_failing\nFROM rules;\n",
      "note": "One row per rule, with the share failing. Nothing is averaged across rules: a single score would hide which rule moved."
    }
  ]
}
```

```
ana@lab:~/clean$ psql -f scorecard.sql
  dimension   |                 rule                 | tested | failing | pct_failing 
--------------+--------------------------------------+--------+---------+-------------
 completeness | the customer has an e-mail           |   2413 |     282 |        11.7
 validity     | a birth year has four digits         |   2075 |     106 |         5.1
 accuracy     | a birth year is not the form's 1900  |   2075 |     348 |        16.8
 consistency  | the order's customer is in the CRM   |  28551 |     246 |         0.9
 uniqueness   | an order id appears once             |  28551 |      25 |         0.1
 timeliness   | the CRM knows the last week's buyers |    577 |      11 |         1.9
(6 rows)
```

Each line says what was checked, against how many rows, and how many failed. Read them against
what the earlier sections found:

- **completeness**, 11.7%, is almost all the shops' customers, and only matters for a campaign;
- **validity**, 5.1%, is the app's two-digit years, which a conversion would turn into the year 87;
- **accuracy**, 16.8%, is the 1900 placeholder, the worst number here because it is invisible to
  every other rule;
- **consistency**, 0.9%, is the orphans: small as a share and large as a problem if the report is
  per customer;
- **uniqueness**, 0.1%, is 25 repeated orders, and every one of them is revenue counted twice;
- **timeliness**, 1.9%, is the eleven customers who bought in the last week and are not in the
  CRM yet.

## What the numbers are for

**Not for averaging.** Six percentages averaged into one "quality score" would put 25 duplicated
orders and 348 false birth years on the same scale, and the score would move when either did
without saying which. Keep the rules apart.

**For comparing exports.** Run the same file against next month's data and the numbers become a
trend. A completeness rule that jumps from 12% to 40% overnight is a form that changed, a system
that broke or an export that was cut short, and it is far cheaper to notice the day it happens.

**For deciding what to fix first.** Each rule points at its source: the shops' form, the app's
year field, the app's retries, the CRM's export schedule. Some of these are fixed by cleaning and
some only by asking another team to change something. Lesson 17 keeps this file beside the
cleaning code so it runs every time, and `pipelines-etl` lesson 16 turns rules like these into
tests that stop a load.

**Not as a verdict on the data in general.** "Fit for use" is the phrase the field uses, and it is
honest: the same file is clean enough to count customers by city once the spellings are fixed, and
nowhere near clean enough to e-mail them. Every number above is a fact about the data measured
against one purpose.
