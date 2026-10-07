#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 9 leave
# (`lab.sh state 9`). The purge is run for the lab's today, 1 July 2026, and
# the audit query leaves out the time of each change, which is the machine's
# clock on the day the capture ran rather than the lab's.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenBao 2.5.5, 4 cores,
# TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 9 >/dev/null 2>&1 </dev/null

put retention.sql <<'EOF'
-- How long each kind of record is kept, from when, and why. One row per
-- rule; the purge reads nothing else.
SET ROLE ipe_owner;
CREATE TABLE gov.retention (
  table_schema name     NOT NULL,
  table_name   name     NOT NULL,
  keep_for     interval NOT NULL,
  counted_from text     NOT NULL,
  basis        text     NOT NULL,
  decided_by   text     NOT NULL,
  PRIMARY KEY (table_schema, table_name)
);
INSERT INTO gov.column_class
SELECT 'gov', 'retention', c, 'none', 'a rule about tables, not people'
FROM unnest(ARRAY['table_schema','table_name','keep_for','counted_from','basis','decided_by']) c;
INSERT INTO gov.retention VALUES
 ('sales',  'orders',        '5 years', 'the first day of the year after the order',
  'tax records: five years from the start of the following year', 'finance manager'),
 ('health', 'prescriptions', '2 years', 'the day the prescription was issued',
  'the chief pharmacist''s rule, after the health rules for controlled medicines',
  'chief pharmacist'),
 ('support','tickets',       '2 years', 'the day the ticket was opened, once closed',
  'no law asks for more; long enough to see a complaint come back', 'head of support');
EOF
put overdue.sql <<'EOF'
-- On the lab's today, how many rows are past what gov.retention allows.
SET ROLE ipe_owner;
SELECT 'sales.orders' AS "table", count(*) AS past_retention
  FROM sales.orders
  WHERE date_trunc('year', ordered_at) + interval '1 year'
        + (SELECT keep_for FROM gov.retention WHERE table_name = 'orders') <= DATE '2026-07-01'
UNION ALL
SELECT 'health.prescriptions', count(*)
  FROM health.prescriptions
  WHERE issued_on + (SELECT keep_for FROM gov.retention WHERE table_name = 'prescriptions')
        <= DATE '2026-07-01'
UNION ALL
SELECT 'support.tickets', count(*)
  FROM support.tickets
  WHERE status = 'closed'
    AND opened_at + (SELECT keep_for FROM gov.retention WHERE table_name = 'tickets')
        <= DATE '2026-07-01';
EOF
code retention-sql retention.sql
code overdue-sql overdue.sql
block overdue
on 'psql -f retention.sql'
on 'psql -f overdue.sql'

put hold.sql <<'EOF'
-- Customer 4407 is in court over a refund from 2020. Nothing of theirs is
-- deleted until the case ends, whatever the retention rule says.
SET ROLE ipe_owner;
CREATE TABLE gov.legal_holds (
  customer_id integer NOT NULL,
  reason      text    NOT NULL,
  since       date    NOT NULL,
  released_on date
);
INSERT INTO gov.column_class VALUES
 ('gov','legal_holds','customer_id','personal','whose data is held'),
 ('gov','legal_holds','reason','personal','a dispute about a person'),
 ('gov','legal_holds','since','personal','when it began'),
 ('gov','legal_holds','released_on','personal','when it ended');
INSERT INTO gov.legal_holds VALUES
 (4407, 'lawsuit over the refund of order 105213, filed 2026-03-02', '2026-03-09', NULL);
EOF
code hold-sql hold.sql

put purge.sql <<'EOF'
-- The purge: what gov.retention says has expired goes, except what a legal
-- hold keeps. Before orders go, what they say about sales is kept as monthly
-- totals that name nobody. Every run is logged.
SET ROLE ipe_owner;
CREATE TABLE gov.sales_monthly (
  month       date    NOT NULL,
  category    text    NOT NULL,
  orders      integer NOT NULL,
  units       integer NOT NULL,
  revenue_cts bigint  NOT NULL,
  PRIMARY KEY (month, category)
);
CREATE TABLE gov.purge_log (
  run_on  date        NOT NULL,
  rel     text        NOT NULL,
  deleted bigint      NOT NULL,
  PRIMARY KEY (run_on, rel)
);
INSERT INTO gov.column_class
SELECT 'gov', t, c, 'none', w
FROM (VALUES ('sales_monthly','month','totals that name nobody'),
             ('sales_monthly','category','totals that name nobody'),
             ('sales_monthly','orders','totals that name nobody'),
             ('sales_monthly','units','totals that name nobody'),
             ('sales_monthly','revenue_cts','totals that name nobody'),
             ('purge_log','run_on','a count of rows, not people'),
             ('purge_log','rel','a count of rows, not people'),
             ('purge_log','deleted','a count of rows, not people')) AS v(t, c, w);

CREATE FUNCTION gov.purge(today date) RETURNS TABLE (rel text, deleted bigint)
LANGUAGE plpgsql AS $$
DECLARE
  held    integer[] := ARRAY(SELECT customer_id FROM gov.legal_holds
                             WHERE released_on IS NULL);
  expired integer[];
  n       bigint;
BEGIN
  expired := ARRAY(
    SELECT o.order_id FROM sales.orders o
    WHERE date_trunc('year', o.ordered_at) + interval '1 year'
          + (SELECT keep_for FROM gov.retention WHERE table_name = 'orders') <= today
      AND (o.customer_id IS NULL OR o.customer_id <> ALL (held)));

  -- What the business still needs from them, anonymised (LGPD art. 16, IV).
  INSERT INTO gov.sales_monthly
  SELECT date_trunc('month', o.ordered_at)::date, p.category, count(DISTINCT o.order_id),
         sum(i.quantity), sum(i.quantity * i.unit_price_cents)
  FROM sales.orders o
  JOIN sales.order_items i USING (order_id)
  JOIN sales.products p USING (product_id)
  WHERE o.order_id = ANY (expired)
  GROUP BY 1, 2
  ON CONFLICT (month, category) DO UPDATE
    SET orders = gov.sales_monthly.orders + EXCLUDED.orders,
        units = gov.sales_monthly.units + EXCLUDED.units,
        revenue_cts = gov.sales_monthly.revenue_cts + EXCLUDED.revenue_cts;

  DELETE FROM health.prescriptions r
  WHERE (r.issued_on + (SELECT keep_for FROM gov.retention WHERE table_name = 'prescriptions')
         <= today OR r.order_id = ANY (expired))
    AND r.customer_id <> ALL (held);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'health.prescriptions'; deleted := n; RETURN NEXT;

  DELETE FROM support.tickets t
  WHERE t.status = 'closed'
    AND t.opened_at + (SELECT keep_for FROM gov.retention WHERE table_name = 'tickets') <= today
    AND t.customer_id <> ALL (held);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'support.tickets'; deleted := n; RETURN NEXT;

  DELETE FROM sales.order_items WHERE order_id = ANY (expired);
  DELETE FROM sales.payments    WHERE order_id = ANY (expired);
  DELETE FROM sales.deliveries  WHERE order_id = ANY (expired);
  DELETE FROM sales.returns     WHERE order_id = ANY (expired);
  DELETE FROM sales.orders      WHERE order_id = ANY (expired);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'sales.orders'; deleted := n; RETURN NEXT;
END $$;
EOF
code purge-sql purge.sql
put run-purge.sql <<'EOF'
-- One run, logged.
SET ROLE ipe_owner;
INSERT INTO gov.purge_log
SELECT DATE '2026-07-01', rel, deleted FROM gov.purge(DATE '2026-07-01')
RETURNING rel, deleted;
EOF
code run-purge-sql run-purge.sql
block purge
on 'psql -f hold.sql'
on 'psql -f purge.sql'
on 'psql -f run-purge.sql'
on 'psql -f overdue.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders_kept_by_the_hold FROM sales.orders WHERE customer_id = 4407 AND ordered_at < DATE '"'"'2021-01-01'"'"'" -c "SELECT * FROM gov.sales_monthly WHERE month = DATE '"'"'2020-03-01'"'"' ORDER BY category"'

put audit.sql <<'EOF'
-- Who changed which customer, and which columns. Not the values: the trail
-- would otherwise be a second copy of everything it watches.
SET ROLE ipe_owner;
CREATE TABLE gov.audit_log (
  audit_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  at          timestamptz NOT NULL DEFAULT now(),
  logged_in   name        NOT NULL,   -- the person who connected
  acting_as   name        NOT NULL,   -- the role they had set
  action      text        NOT NULL,
  rel         text        NOT NULL,
  row_key     text        NOT NULL,
  columns     text[]
);
INSERT INTO gov.column_class
SELECT 'gov', 'audit_log', c, 'personal', 'who did what to whose row'
FROM unnest(ARRAY['audit_id','at','logged_in','acting_as','action','rel','row_key','columns']) c;

CREATE FUNCTION gov.audit_customers() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
BEGIN
  INSERT INTO gov.audit_log (logged_in, acting_as, action, rel, row_key, columns)
  SELECT session_user, current_user, TG_OP, TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
         OLD.customer_id::text,
         CASE WHEN TG_OP = 'UPDATE' THEN
           ARRAY(SELECT n.key FROM jsonb_each(to_jsonb(NEW)) n
                 JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
                 WHERE n.value IS DISTINCT FROM o.value ORDER BY n.key)
         END;
  RETURN NULL;
END $$;
CREATE TRIGGER customers_audited AFTER UPDATE OR DELETE ON sales.customers
  FOR EACH ROW EXECUTE FUNCTION gov.audit_customers();

-- The trail itself: inserted into, never changed, never emptied.
CREATE FUNCTION gov.refuse() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION '% is append-only: % is refused', TG_TABLE_NAME, TG_OP;
END $$;
CREATE TRIGGER audit_log_is_append_only BEFORE UPDATE OR DELETE ON gov.audit_log
  FOR EACH ROW EXECUTE FUNCTION gov.refuse();
CREATE TRIGGER audit_log_is_not_emptied BEFORE TRUNCATE ON gov.audit_log
  FOR EACH STATEMENT EXECUTE FUNCTION gov.refuse();
EOF
code audit-sql audit.sql
block audit
on 'psql -f audit.sql'
on 'psql -c "SET ROLE ipe_owner" -c "UPDATE sales.customers SET city = '"'"'Contagem'"'"', cep = '"'"'32010-000'"'"' WHERE customer_id = 112"'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT logged_in, acting_as, action, rel, row_key, columns FROM gov.audit_log"'
on 'psql -c "SET ROLE ipe_owner" -c "DELETE FROM gov.audit_log"'
on 'psql -c "SET ROLE ipe_owner" -c "TRUNCATE gov.audit_log"'
