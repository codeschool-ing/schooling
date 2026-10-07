#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lesson 1 leaves, rebuilt by
# `lab.sh state 1` (the roles, their passwords, pg_hba.conf, CONNECT). The SQL
# files are written into ~/gov by `put` and shown in the lesson as they are.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, 4 cores, TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 1 >/dev/null

put ../.pg_service.conf <<'EOF'
# One entry per role Ana tests as. `psql service=bruno` reads the host,
# the port, the database and the user from here, and the password from
# ~/.pgpass as before.
[bruno]
host=db.ipe.example
port=5433
dbname=ipe
user=bruno

[carla]
host=db.ipe.example
port=5433
dbname=ipe
user=carla

[site_app]
host=db.ipe.example
port=5433
dbname=ipe
user=site_app
EOF
code service-conf ../.pg_service.conf

block dp-empty
on 'psql -c "\dp sales.*"'

put first-grant.sql <<'EOF'
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales TO bruno;
GRANT SELECT ON sales.orders TO bruno;
EOF
code first-grant-sql first-grant.sql
block first-grant
on 'psql -f first-grant.sql'
on 'psql service=bruno -c "SELECT count(*) FROM sales.orders"'
on 'psql service=bruno -c "SELECT count(*) FROM sales.order_items"'
on 'psql -c "\dp sales.orders"'

block not-owner
on 'psql -c "GRANT SELECT ON sales.order_items TO bruno"'
on 'psql -c "SELECT tableowner FROM pg_tables WHERE tablename = '"'"'order_items'"'"'"'

put groups.sql <<'EOF'
-- One role per job, none of which can log in. People are made members.
CREATE ROLE analyst       NOLOGIN;
CREATE ROLE support_agent NOLOGIN;
CREATE ROLE app_web       NOLOGIN;
CREATE ROLE pipeline      NOLOGIN;

GRANT analyst       TO bruno, lia;
GRANT support_agent TO carla;
GRANT app_web       TO site_app;
GRANT pipeline      TO etl_loader;

-- What each job may do, granted to the job and never to the person.
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales TO analyst, support_agent, app_web, pipeline;
GRANT USAGE ON SCHEMA support TO support_agent;

GRANT SELECT ON sales.orders, sales.order_items, sales.products TO analyst;
GRANT SELECT ON sales.orders, sales.order_items, sales.products,
                sales.customers, sales.payments TO pipeline;
GRANT SELECT ON sales.products TO app_web;
GRANT INSERT ON sales.orders, sales.order_items, sales.payments TO app_web;
GRANT SELECT ON sales.customers, sales.orders TO support_agent;
GRANT SELECT, UPDATE (status) ON support.tickets TO support_agent;

-- Bruno's own grants were the first draft. The group replaces them.
REVOKE SELECT ON sales.orders FROM bruno;
REVOKE USAGE ON SCHEMA sales FROM bruno;
EOF
code groups-sql groups.sql
block groups
on 'psql -f groups.sql'
on 'psql -c "\drg"'
on 'psql -c "\dp sales.orders"'
on 'psql service=bruno -c "SELECT count(*) FROM sales.order_items"'
on 'psql service=bruno -c "SELECT count(*) FROM health.prescriptions"'

put new-table.sql <<'EOF'
SET ROLE ipe_owner;
CREATE TABLE sales.returns (
  order_id    integer REFERENCES sales.orders,
  returned_on date    NOT NULL,
  reason      text    NOT NULL
);
EOF
code new-table-sql new-table.sql
block new-table
on 'psql -f new-table.sql'
on 'psql service=bruno -c "SELECT count(*) FROM sales.returns"'

put defaults.sql <<'EOF'
-- Whatever ipe_owner creates in `sales` from now on, analysts may read.
-- It changes nothing that exists already: that is what GRANT is for.
SET ROLE ipe_owner;
ALTER DEFAULT PRIVILEGES IN SCHEMA sales GRANT SELECT ON TABLES TO analyst;
GRANT SELECT ON sales.returns TO analyst;
CREATE TABLE sales.deliveries (
  order_id     integer REFERENCES sales.orders,
  delivered_at timestamptz
);
EOF
code defaults-sql defaults.sql
block defaults
on 'psql -f defaults.sql'
on 'psql -c "\ddp"'
on 'psql service=bruno -c "SELECT count(*) FROM sales.returns" -c "SELECT count(*) FROM sales.deliveries"'

block customers-denied
on 'psql service=bruno -c "SELECT * FROM sales.customers LIMIT 1"'

put columns.sql <<'EOF'
-- Analysts see who the customers are as a population, never as people.
SET ROLE ipe_owner;
GRANT SELECT (customer_id, sex, city, state, created_at, marketing_opt_in)
  ON sales.customers TO analyst;
EOF
code columns-sql columns.sql
block columns
on 'psql -f columns.sql'
on 'psql service=bruno -c "SELECT * FROM sales.customers LIMIT 1"'
on 'psql service=bruno -c "SELECT state, count(*) FROM sales.customers GROUP BY state ORDER BY 2 DESC LIMIT 5"'
on 'psql service=bruno -c "SELECT email FROM sales.customers LIMIT 1"'
on 'psql -c "\dp sales.customers"'

put view.sql <<'EOF'
-- What an analyst needs about a customer, computed where the data is.
-- The age band is derived here, so birth_date never leaves the table.
SET ROLE ipe_owner;
CREATE VIEW sales.customer_profile AS
SELECT customer_id,
       state,
       CASE WHEN age < 18 THEN 'under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 50 THEN '30-49'
            WHEN age < 70 THEN '50-69'
            ELSE '70+' END AS age_band,
       created_at::date AS customer_since
FROM (SELECT c.*, extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age
      FROM sales.customers c) c;
GRANT SELECT ON sales.customer_profile TO analyst;
EOF
code view-sql view.sql
block view
on 'psql -f view.sql'
on 'psql service=bruno -c "SELECT age_band, count(*) FROM sales.customer_profile GROUP BY 1 ORDER BY 1"'
on 'psql service=bruno -c "SELECT birth_date FROM sales.customers LIMIT 1"'

block carla-all
on 'psql service=carla -c "SELECT count(*) AS customers, count(DISTINCT state) AS states FROM sales.customers"'

put rls.sql <<'EOF'
-- Which states each support agent serves. Only the owner writes it.
SET ROLE ipe_owner;
CREATE TABLE support.agent_regions (
  agent name    NOT NULL,
  state char(2) NOT NULL,
  PRIMARY KEY (agent, state)
);
INSERT INTO support.agent_regions VALUES ('carla', 'SP'), ('carla', 'RJ');
GRANT SELECT ON support.agent_regions TO support_agent;

-- Support agents see the customers of their own states, and no others.
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY agent_sees_own_states ON sales.customers
  FOR SELECT TO support_agent
  USING (state IN (SELECT r.state FROM support.agent_regions r
                   WHERE r.agent = current_user));
EOF
code rls-sql rls.sql
block rls
on 'psql -f rls.sql'
on 'psql service=carla -c "SELECT count(*) AS customers, count(DISTINCT state) AS states FROM sales.customers"'
on 'psql service=carla -c "SELECT count(*) FROM sales.customers WHERE state = '"'"'MG'"'"'"'
on 'psql service=bruno -c "SELECT count(*) FROM sales.customers"'
on 'psql service=site_app -c "SELECT count(*) FROM sales.customers"'

put rls-analyst.sql <<'EOF'
-- Analysts and the pipeline see every customer: their limit is the columns.
SET ROLE ipe_owner;
CREATE POLICY analysts_see_all ON sales.customers
  FOR SELECT TO analyst, pipeline
  USING (true);
EOF
code rls-analyst-sql rls-analyst.sql
block rls-analyst
on 'psql -f rls-analyst.sql'
on 'psql service=bruno -c "SELECT count(*) FROM sales.customers"'

block view-rls
on 'psql -c "SET ROLE ipe_owner" -c "GRANT SELECT ON sales.customer_profile TO support_agent"'
on 'psql service=carla -c "SELECT count(*) FROM sales.customer_profile"'
on 'psql -c "SET ROLE ipe_owner" -c "ALTER VIEW sales.customer_profile SET (security_invoker = true)"'
on 'psql service=carla -c "SELECT count(*) FROM sales.customer_profile"'
on 'psql service=bruno -c "SELECT count(*) FROM sales.customer_profile"'
quiet 'psql -c "SET ROLE ipe_owner" -c "ALTER VIEW sales.customer_profile SET (security_invoker = false)" -c "REVOKE SELECT ON sales.customer_profile FROM support_agent"'

block owner-bypass
on 'psql -c "SET ROLE ipe_owner" -c "SELECT count(*) FROM sales.customers"'
on 'psql -c "SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = '"'"'customers'"'"'"'
on 'psql -c "\du postgres"'

put setting.sql <<'EOF'
-- A FIRST DRAFT, AND WRONG: the region comes from a setting of the session.
SET ROLE ipe_owner;
CREATE POLICY agent_sees_session_region ON support.tickets
  FOR SELECT TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c
                         WHERE c.state = current_setting('ipe.region', true)));
ALTER TABLE support.tickets ENABLE ROW LEVEL SECURITY;
EOF
code setting-sql setting.sql
block setting
on 'psql -f setting.sql'
on 'psql service=carla -c "SET ipe.region = '"'"'SP'"'"'" -c "SELECT count(*) FROM support.tickets"'
on 'psql service=carla -c "SET ipe.region = '"'"'MG'"'"'" -c "SELECT count(*) FROM support.tickets"'

put attribute.sql <<'EOF'
-- The attribute comes from a table Carla can read and cannot write.
SET ROLE ipe_owner;
DROP POLICY agent_sees_session_region ON support.tickets;
CREATE POLICY agent_sees_own_states ON support.tickets
  FOR ALL TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c))
  WITH CHECK (status IN ('open', 'closed'));
EOF
code attribute-sql attribute.sql
block attribute
on 'psql -f attribute.sql'
on 'psql service=carla -c "SET ipe.region = '"'"'MG'"'"'" -c "SELECT count(*) FROM support.tickets"'
on 'psql service=carla -c "INSERT INTO support.agent_regions VALUES ('"'"'carla'"'"', '"'"'MG'"'"')"'
on "psql service=carla -c \"UPDATE support.tickets SET status = 'escalated' WHERE ticket_id = 2\""
on "psql service=carla -c \"UPDATE support.tickets SET status = 'closed' WHERE ticket_id = 2\""

put matrix.sql <<'EOF'
-- Who may read what, asked of the server rather than of anybody's memory.
SET ROLE ipe_owner;
SELECT r.rolname AS role,
       has_table_privilege(r.rolname, 'sales.orders', 'SELECT')          AS orders,
       has_column_privilege(r.rolname, 'sales.customers', 'state', 'SELECT') AS cust_state,
       has_column_privilege(r.rolname, 'sales.customers', 'cpf', 'SELECT')   AS cust_cpf,
       has_table_privilege(r.rolname, 'sales.orders', 'INSERT')          AS ins_orders,
       has_table_privilege(r.rolname, 'health.prescriptions', 'SELECT')  AS rx,
       has_table_privilege(r.rolname, 'support.tickets', 'UPDATE')       AS tickets_upd
FROM pg_roles r
WHERE r.rolname IN ('bruno', 'carla', 'davi', 'site_app', 'etl_loader')
ORDER BY 1;
EOF
code matrix-sql matrix.sql
block matrix
on 'psql -f matrix.sql'

block offboard
on 'psql -c "\drg lia"'
on 'psql -c "ALTER ROLE lia NOLOGIN" -c "REVOKE analyst FROM lia"'
on 'sudo -u postgres psql -c "REASSIGN OWNED BY lia TO ipe_owner" -c "DROP OWNED BY lia"'
on 'psql -c "\drg lia"'
on 'psql -c "\du lia"'

put fn.sql <<'EOF'
SET ROLE ipe_owner;
CREATE FUNCTION sales.customer_email(id integer) RETURNS text
LANGUAGE sql SECURITY DEFINER SET search_path = sales, pg_temp
AS $$ SELECT email FROM sales.customers WHERE customer_id = id $$;
EOF
code fn-sql fn.sql
block fn
on 'psql -f fn.sql'
on 'psql service=bruno -c "SELECT sales.customer_email(1)"'
on 'psql -c "\df+ sales.customer_email"'
on 'psql -c "SET ROLE ipe_owner" -c "REVOKE EXECUTE ON FUNCTION sales.customer_email(integer) FROM PUBLIC"'
on 'psql service=bruno -c "SELECT sales.customer_email(1)"'

block fn-default
on 'psql -c "SET ROLE ipe_owner" -c "ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC"'
on 'psql -c "\ddp"'
