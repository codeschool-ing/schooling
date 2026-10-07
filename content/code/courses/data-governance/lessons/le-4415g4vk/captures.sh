#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 8 leave
# (`lab.sh state 8`). The quality run is stamped with the lab's today, 1 July
# 2026, so the history it writes does not move with the day the capture is run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenBao 2.5.5, 4 cores,
# TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 8 >/dev/null 2>&1 </dev/null

put owners.sql <<'EOF'
-- Who answers for each table: the owner decides what it is for and who may
-- read it; the steward looks after its quality day to day.
SET ROLE ipe_owner;
CREATE TABLE gov.table_owners (
  table_schema name NOT NULL,
  table_name   name NOT NULL,
  owner        text NOT NULL,
  steward      text NOT NULL,
  PRIMARY KEY (table_schema, table_name)
);
INSERT INTO gov.column_class VALUES
 ('gov','table_owners','table_schema','none','a schema'),
 ('gov','table_owners','table_name','none','a table'),
 ('gov','table_owners','owner','personal','an employee''s name'),
 ('gov','table_owners','steward','personal','an employee''s name');
INSERT INTO gov.table_owners VALUES
 ('sales',  'customers',      'head of sales',      'bruno'),
 ('sales',  'orders',         'head of sales',      'bruno'),
 ('sales',  'order_items',    'head of sales',      'bruno'),
 ('sales',  'payments',       'finance manager',    'bruno'),
 ('sales',  'products',       'head of purchasing', 'bruno'),
 ('sales',  'consent_events', 'DPO',                'davi'),
 ('health', 'prescriptions',  'chief pharmacist',   'davi'),
 ('support','tickets',        'head of support',    'carla'),
 ('gov',    'column_class',   'DPO',                'davi'),
 ('gov',    'subject_requests','DPO',               'davi');
EOF
put unowned.sql <<'EOF'
-- Every table nobody has said they answer for.
SELECT t.table_schema, t.table_name
FROM information_schema.tables t
LEFT JOIN gov.table_owners o USING (table_schema, table_name)
WHERE t.table_schema IN ('sales', 'health', 'support', 'gov')
  AND t.table_type = 'BASE TABLE'
  AND o.owner IS NULL
ORDER BY 1, 2;
EOF
code owners-sql owners.sql
code unowned-sql unowned.sql
block owners
on 'psql -f owners.sql'
on 'psql -c "SET ROLE ipe_owner" -f unowned.sql'

put measure.sql <<'EOF'
-- Six questions about the data, each answered with a count.
SET ROLE ipe_owner;
SELECT 'e-mail with no valid shape' AS question, count(*) AS answer
  FROM sales.customers
  WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' AND email NOT LIKE 'erased-%@invalid'
UNION ALL
SELECT 'e-mail held by two customers', count(*)
  FROM (SELECT lower(email) FROM sales.customers GROUP BY 1 HAVING count(*) > 1) d
UNION ALL
SELECT 'order dated after today', count(*)
  FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01'
UNION ALL
SELECT 'order with no customer', count(*)
  FROM sales.orders WHERE customer_id IS NULL
UNION ALL
SELECT 'consent before sign-up', count(*)
  FROM sales.customers WHERE consent_at < created_at
UNION ALL
SELECT 'payment different from its order', count(*)
  FROM sales.orders o JOIN sales.payments p USING (order_id)
  WHERE p.amount_cents <> o.total_cents;
EOF
code measure-sql measure.sql
block measure
on 'psql -f measure.sql'

block look
on 'psql -c "SET ROLE ipe_owner" -c "SELECT email FROM sales.customers WHERE email !~* '"'"'^[^@ ]+@[^@ ]+\.[a-z]{2,}\$'"'"' AND email NOT LIKE '"'"'erased-%@invalid'"'"' ORDER BY customer_id LIMIT 4" -c "SELECT ordered_at FROM sales.orders WHERE ordered_at > timestamptz '"'"'2026-07-01'"'"' ORDER BY 1" -c "SELECT min(ordered_at)::date AS first, max(ordered_at)::date AS last FROM sales.orders WHERE customer_id IS NULL" -c "SELECT count(*) AS ends_in_dot_con FROM sales.customers WHERE email LIKE '"'"'%.con'"'"'"'

put consent-gap.sql <<'EOF'
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
EOF
code consent-gap-sql consent-gap.sql
block consent-gap
on 'psql -f consent-gap.sql'

put rules.sql <<'EOF'
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
EOF
code rules-sql rules.sql
block rules
on 'psql -f rules.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT * FROM gov.run_quality('"'"'2026-07-01 06:00-03'"'"')"'

put email-check.sql <<'EOF'
-- New rows must have the shape; the old ones are checked separately.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD CONSTRAINT email_shape
  CHECK (email ~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' OR email LIKE 'erased-%@invalid')
  NOT VALID;
EOF
code email-check-sql email-check.sql
block email-check
on 'psql -f email-check.sql'
on 'psql -c "SET ROLE ipe_owner" -c "INSERT INTO sales.customers (customer_id, full_name, email, birth_date, sex, cep, city, state, created_at, marketing_opt_in) VALUES (9001, '"'"'Teste Novo'"'"', '"'"'teste.novoexample.com'"'"', '"'"'1990-01-01'"'"', '"'"'F'"'"', '"'"'01001-000'"'"', '"'"'São Paulo'"'"', '"'"'SP'"'"', '"'"'2026-07-01 09:00-03'"'"', false)"'
on 'psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.customers VALIDATE CONSTRAINT email_shape"'

put describe.sql <<'EOF'
-- What a column means, kept beside the column, where every tool can read it.
SET ROLE ipe_owner;
COMMENT ON TABLE sales.orders IS
  'One order placed on the site or in a shop. Owner: head of sales.';
COMMENT ON COLUMN sales.orders.customer_id IS
  'NULL for guest checkouts, which the old site allowed until December 2019.';
COMMENT ON COLUMN sales.orders.ordered_at IS
  'When the customer confirmed the order, in the shop''s time zone.';
COMMENT ON COLUMN sales.orders.total_cents IS
  'Total in centavos, after discounts, before delivery. Equals the payment.';
EOF
put dictionary.sql <<'EOF'
-- A data dictionary, generated: the catalogue, the classification, the owner
-- and the comment, for one table.
SELECT a.attname                              AS "column",
       format_type(a.atttypid, a.atttypmod)   AS type,
       cc.class,
       o.owner,
       col_description(a.attrelid, a.attnum)  AS meaning
FROM pg_attribute a
JOIN pg_class c      ON c.oid = a.attrelid
JOIN pg_namespace n  ON n.oid = c.relnamespace
LEFT JOIN gov.column_class cc
       ON (cc.table_schema, cc.table_name, cc.column_name) = (n.nspname, c.relname, a.attname)
LEFT JOIN gov.table_owners o
       ON (o.table_schema, o.table_name) = (n.nspname, c.relname)
WHERE n.nspname = 'sales' AND c.relname = 'orders' AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;
EOF
code describe-sql describe.sql
code dictionary-sql dictionary.sql
block dictionary
on 'psql -f describe.sql'
on 'psql -c "SET ROLE ipe_owner" -f dictionary.sql'

put lineage.sql <<'EOF'
-- Which views read which tables, from PostgreSQL's own record of it.
SELECT DISTINCT v.relnamespace::regnamespace || '.' || v.relname AS view,
       t.relnamespace::regnamespace || '.' || t.relname          AS reads
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class v   ON v.oid = r.ev_class
JOIN pg_class t   ON t.oid = d.refobjid
WHERE d.classid = 'pg_rewrite'::regclass
  AND d.refclassid = 'pg_class'::regclass
  AND t.oid <> v.oid
  AND v.relnamespace::regnamespace::text IN ('sales', 'health', 'support', 'gov')
ORDER BY 1, 2;
EOF
code lineage-sql lineage.sql
block lineage
on 'psql -c "SET ROLE ipe_owner" -f lineage.sql'
