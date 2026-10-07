# Where lesson 2 leaves the database: the job roles and their grants, the
# default privileges in `sales`, the column grant and the profile view for
# analysts, row security on customers and tickets, Lia offboarded, and
# ~/.pg_service.conf for the roles Ana tests as.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg <<'SQL'
SET ROLE ana;
CREATE ROLE analyst       NOLOGIN;
CREATE ROLE support_agent NOLOGIN;
CREATE ROLE app_web       NOLOGIN;
CREATE ROLE pipeline      NOLOGIN;
GRANT support_agent TO carla;
GRANT analyst       TO bruno;
GRANT app_web       TO site_app;
GRANT pipeline      TO etl_loader;
ALTER ROLE lia NOLOGIN;
RESET ROLE;
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
CREATE TABLE sales.returns (
  order_id    integer REFERENCES sales.orders,
  returned_on date    NOT NULL,
  reason      text    NOT NULL
);
ALTER DEFAULT PRIVILEGES IN SCHEMA sales GRANT SELECT ON TABLES TO analyst;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
GRANT SELECT ON sales.returns TO analyst;
CREATE TABLE sales.deliveries (
  order_id     integer REFERENCES sales.orders,
  delivered_at timestamptz
);
GRANT SELECT (customer_id, sex, city, state, created_at, marketing_opt_in)
  ON sales.customers TO analyst;
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
CREATE TABLE support.agent_regions (
  agent name    NOT NULL,
  state char(2) NOT NULL,
  PRIMARY KEY (agent, state)
);
INSERT INTO support.agent_regions VALUES ('carla', 'SP'), ('carla', 'RJ');
GRANT SELECT ON support.agent_regions TO support_agent;
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY agent_sees_own_states ON sales.customers
  FOR SELECT TO support_agent
  USING (state IN (SELECT r.state FROM support.agent_regions r
                   WHERE r.agent = current_user));
CREATE POLICY analysts_see_all ON sales.customers
  FOR SELECT TO analyst, pipeline
  USING (true);
ALTER TABLE support.tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY agent_sees_own_states ON support.tickets
  FOR ALL TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c))
  WITH CHECK (status IN ('open', 'closed'));
UPDATE support.tickets SET status = 'closed' WHERE ticket_id = 2;
SQL
cat > /home/ana/.pg_service.conf <<'CONF'
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
CONF
chown ana:ana /home/ana/.pg_service.conf
