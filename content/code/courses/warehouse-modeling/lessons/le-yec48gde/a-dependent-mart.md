---
title: A dependent mart, in views
version: 1
---

The sales team at Ponto Final wants one thing: net sales by shop and month. Ana gives them a schema of their
own, with one view in it, built over the star:

```sql
-- The sales team's mart: views over the warehouse's star, nothing copied.
CREATE SCHEMA mart_sales;
CREATE VIEW mart_sales.monthly AS
SELECT d.year, d.month, s.shop_name,
       count(DISTINCT f.order_id) AS orders,
       sum(f.net_cents)           AS net_cents
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
GROUP BY ALL;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < mart_sales.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT shop_name, orders, net_cents FROM mart_sales.monthly WHERE year = 2025 AND month = 12 ORDER BY net_cents DESC"
┌───────────┬────────┬───────────┐
│ shop_name │ orders │ net_cents │
│  varchar  │ int64  │  int128   │
├───────────┼────────┼───────────┤
│ Online    │  20054 │ 347127604 │
│ Paulista  │   6347 │ 110429646 │
│ Pinheiros │   5162 │  90713293 │
│ Savassi   │   3688 │  65405886 │
│ Cambuí    │   3160 │  54340150 │
│ Batel     │   2693 │  46884660 │
│ Moinhos   │   2355 │  40913243 │
└───────────┴────────┴───────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT sum(net_cents) AS december FROM mart_sales.monthly WHERE year = 2025 AND month = 12"
┌───────────┐
│ december  │
│  int128   │
├───────────┤
│ 755814482 │
└───────────┘
```

**Nothing was copied.** A view stores its query, not its rows, so the mart costs no space and can never fall
behind the warehouse: every question it answers is asked of `fact_sales` at the moment it is asked. The sales
team sees one table with the shop's name in it, no keys and no joins, and the warehouse's December figure,
755,814,482 centavos.

What makes it dependent is visible in the query. The measure is the warehouse's `net_cents`, with the
warehouse's rule about cancelled orders already applied inside `fact_sales`. The month comes from `dim_date`
and the shop from `dim_shop`, the same rows every other mart will use. The sales team cannot get a different
answer from this mart than from the warehouse, because there is only one place the answer comes from.

A mart this thin is a matter of convenience: a schema the team can be given rights to, and names it can read.
When views over a large fact table become slow, the same mart can be made of summary tables instead, the
aggregates of lesson 6, rebuilt after each load. It is still dependent, because it is still built from the
star; it only has to be rebuilt, and lesson 6 showed what happens when somebody forgets.
