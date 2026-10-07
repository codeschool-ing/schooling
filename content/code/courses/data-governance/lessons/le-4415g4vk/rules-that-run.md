---
title: Rules that run on their own
version: 1
---

A query run once is an investigation. To become governance, the same questions have to be asked
**every day, by a machine, with the answers kept**. The rules go into a table, and every run of them
goes into another one that is only ever inserted into:

```sql
-- The questions, kept: each rule is a query returning how many rows break it,
-- and every run is written down and never edited.
SET ROLE ipe_owner;
CREATE TABLE gov.quality_rules (
  rule      text PRIMARY KEY,
  dimension text NOT NULL CHECK (dimension IN
              ('validity', 'uniqueness', 'completeness', 'consistency', 'timeliness')),
  check_sql text NOT NULL,              -- returns one number: the rows breaking it
  tolerance integer NOT NULL DEFAULT 0, -- how many may break it and still pass
  why       text NOT NULL
);
CREATE TABLE gov.quality_runs (
  run_at  timestamptz NOT NULL,
  rule    text        NOT NULL REFERENCES gov.quality_rules,
  failing bigint      NOT NULL,
  passed  boolean     NOT NULL,
  PRIMARY KEY (run_at, rule)
);
INSERT INTO gov.column_class
SELECT 'gov', t, c, 'none', 'about rules, not people'
FROM (VALUES ('quality_rules', 'rule'), ('quality_rules', 'dimension'),
             ('quality_rules', 'check_sql'), ('quality_rules', 'tolerance'),
             ('quality_rules', 'why'), ('quality_runs', 'run_at'),
             ('quality_runs', 'rule'), ('quality_runs', 'failing'),
             ('quality_runs', 'passed')) AS v(t, c);

INSERT INTO gov.quality_rules VALUES
 ('customers.email-shape', 'validity',
  $q$SELECT count(*) FROM sales.customers WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$'
     AND email NOT LIKE 'erased-%@invalid'$q$, 0,
  'an address that cannot receive mail is a customer we cannot reach'),
 ('customers.email-unique', 'uniqueness',
  $q$SELECT count(*) FROM (SELECT lower(email) FROM sales.customers
     GROUP BY 1 HAVING count(*) > 1) d$q$, 0,
  'one person, one customer: an export or an erasure must find all of them'),
 ('orders.not-in-future', 'validity',
  $q$SELECT count(*) FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01'$q$, 0,
  'an order cannot have happened after today'),
 ('orders.customer-after-2020', 'completeness',
  $q$SELECT count(*) FROM sales.orders WHERE customer_id IS NULL
     AND ordered_at >= timestamptz '2020-01-01'$q$, 0,
  'guest checkout ended with the old site in 2019; a null since then is a defect'),
 ('customers.consent-after-signup', 'consistency',
  $q$SELECT count(*) FROM sales.customers WHERE consent_at < created_at$q$, 0,
  'a consent before the account existed cannot be proven'),
 ('payments.match-order', 'consistency',
  $q$SELECT count(*) FROM sales.orders o JOIN sales.payments p USING (order_id)
     WHERE p.amount_cents <> o.total_cents$q$, 0,
  'what was paid is what was ordered');

CREATE FUNCTION gov.run_quality(at timestamptz)
RETURNS TABLE (rule text, dimension text, failing bigint, passed boolean)
LANGUAGE plpgsql AS $$
DECLARE r gov.quality_rules;
BEGIN
  FOR r IN SELECT * FROM gov.quality_rules q ORDER BY q.rule LOOP
    EXECUTE r.check_sql INTO failing;
    rule := r.rule; dimension := r.dimension; passed := failing <= r.tolerance;
    INSERT INTO gov.quality_runs VALUES (at, rule, failing, passed);
    RETURN NEXT;
  END LOOP;
END $$;
```

```
ana@lab:~/gov$ psql -f rules.sql
SET
CREATE TABLE
CREATE TABLE
INSERT 0 9
INSERT 0 6
CREATE FUNCTION
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT * FROM gov.run_quality('2026-07-01 06:00-03')"
SET
              rule              |  dimension   | failing | passed 
--------------------------------+--------------+---------+--------
 customers.consent-after-signup | consistency  |    1324 | f
 customers.email-shape          | validity     |      23 | f
 customers.email-unique         | uniqueness   |      12 | f
 orders.customer-after-2020     | completeness |       0 | t
 orders.not-in-future           | validity     |       3 | f
 payments.match-order           | consistency  |       0 | t
(6 rows)
```

Each rule carries four things worth copying:

- **the query** that counts the rows breaking it, so the rule is exactly as precise as SQL;
- **a tolerance**, zero here, because a rule that tolerates "a few" will tolerate a few more;
- **the dimension**, so a report can say "validity is getting worse" without anybody reading SQL;
- **the reason**, in words, because in two years somebody will want to delete a failing rule, and
  the reason is what tells them whether they may.

The rule for guest orders is worth reading closely. It does not ask "is `customer_id` ever null?" —
that would fail forever on fourteen correct rows, and a rule that always fails is a rule everybody
learns to ignore. It asks "is it null **since 2020**?", which encodes what the owner decided in the
last section, and it passes. **A rule should fail only on something somebody has to act on.**

## The history is the point

`gov.quality_runs` keeps every result. The first run says 23 malformed e-mails. If the run of 1
August says 25, the site is still letting them in; if it says 20, the next-order prompt is working.
A quality report that shows only today's numbers cannot tell those apart. And when an auditor asks
whether Ipê monitors the quality of its data — the LGPD's principle of accountability, again — the
answer is a table with a row per rule per day.

This is how the platform you are studying on treats its own content: every course is run through a
set of checks before it is published, the same checks on every change, and a failure stops it. The
rules here are the same idea, applied to rows.
