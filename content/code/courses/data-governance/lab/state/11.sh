# Where lesson 11 leaves the lab: the schema share, the view
# share.delivery_feed as contract 1.0.0 describes it, and the role rota_certa
# that may read it and nothing else.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg -c "CREATE SCHEMA share AUTHORIZATION ipe_owner"
pg >/dev/null <<'SQL'
-- What Rota Certa, the delivery company, receives every morning: enough to
-- plan routes, and nothing that names anybody. The labels with names are
-- printed in the shop, not sent in the feed.
CREATE ROLE rota_certa NOLOGIN;
SET ROLE ipe_owner;
CREATE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT sum(i.quantity) FROM sales.order_items i WHERE i.order_id = o.order_id) AS items
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
GRANT USAGE ON SCHEMA share TO rota_certa;
GRANT SELECT ON share.delivery_feed TO rota_certa;
SQL
