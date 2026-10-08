# Where lesson 9 leaves the lab: gov.table_owners with ten tables owned;
# gov.quality_rules with six rules and one run in gov.quality_runs; the
# constraint email_shape on sales.customers, NOT VALID; and comments on
# sales.orders.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg >/dev/null <<'SQL'
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
-- New rows must have the shape; the old ones are checked separately.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD CONSTRAINT email_shape
  CHECK (email ~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' OR email LIKE 'erased-%@invalid')
  NOT VALID;
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
SET ROLE ipe_owner;
SELECT count(*) FROM gov.run_quality('2026-07-01 06:00-03');
SQL
