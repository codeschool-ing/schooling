---
title: De onde esta lição parte
version: 1
---

Esta lição parte de onde a lição 12 terminou. Quatro papéis: **`shop_owner`**, dono do banco, das
duas tabelas, do esquema `reports` e da visão dele, e que nunca faz login; **`app`**, que lê e grava
linhas; **`reporting`**, um grupo que lê os pedidos e todas as colunas de clientes menos `email`; e
**`bruno`**, um analista nesse grupo. O `CONNECT` no `shop` está revogado do `PUBLIC` e concedido ao
`app` e ao `reporting`. Se você seguiu a lição 12 no seu servidor, está tudo lá, e a conferência no
fim desta seção deve bater com o que você tem.

Se você está começando aqui, conecte ao `shop` como `ana` com `psql shop` e rode isto, que são os
papéis da lição 11, o esquema e a visão que a lição 12 criou e o `layout.sql` da lição 12, nessa
ordem:

```sql
-- where lesson 13 starts: lessons 11 and 12 together, run in shop as ana
CREATE ROLE reporting;
CREATE ROLE bruno LOGIN IN ROLE reporting;
CREATE ROLE app LOGIN;

CREATE SCHEMA reports;
CREATE VIEW reports.sales_by_month AS
SELECT date_trunc('month', created_at)::date AS month, count(*) AS orders, sum(total_cents) AS total_cents
FROM orders GROUP BY 1 ORDER BY 1;

-- lesson 12's layout.sql
CREATE ROLE shop_owner NOLOGIN;
ALTER DATABASE shop OWNER TO shop_owner;
ALTER TABLE customers OWNER TO shop_owner;
ALTER TABLE orders OWNER TO shop_owner;
ALTER SCHEMA reports OWNER TO shop_owner;
ALTER VIEW reports.sales_by_month OWNER TO shop_owner;
REVOKE CONNECT ON DATABASE shop FROM PUBLIC;
GRANT CONNECT ON DATABASE shop TO app, reporting;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
GRANT SELECT ON orders TO reporting;
GRANT SELECT (id, name, country, created_at) ON customers TO reporting;
GRANT USAGE ON SCHEMA reports TO reporting;
GRANT SELECT ON reports.sales_by_month TO reporting;
```

Depois dê as senhas aos dois papéis de login com `\password bruno` e `\password app`, digitando
`bruno-lab-only` e `app-lab-only`, e escreva o `~/.pgpass` com um editor e aplique `chmod 600` nele:

```conf
# ~/.pgpass: hostname:port:database:username:password
localhost:5432:*:bruno:bruno-lab-only
localhost:5432:*:app:app-lab-only
```

A lição 11 explica as senhas e o arquivo; a lição 12 explica cada linha do SQL. O estado para
comparar:

```
shop=# \dt
            List of relations
 Schema |   Name    | Type  |   Owner    
--------+-----------+-------+------------
 public | customers | table | shop_owner
 public | orders    | table | shop_owner
(2 rows)

shop=# \dp
                                             Access privileges
 Schema |       Name       |   Type   |       Access privileges       |    Column privileges     | Policies 
--------+------------------+----------+-------------------------------+--------------------------+----------
 public | customers        | table    | shop_owner=arwdDxt/shop_owner+| id:                     +| 
        |                  |          | app=arwd/shop_owner           |   reporting=r/shop_owner+| 
        |                  |          |                               | name:                   +| 
        |                  |          |                               |   reporting=r/shop_owner+| 
        |                  |          |                               | country:                +| 
        |                  |          |                               |   reporting=r/shop_owner+| 
        |                  |          |                               | created_at:             +| 
        |                  |          |                               |   reporting=r/shop_owner | 
 public | customers_id_seq | sequence |                               |                          | 
 public | orders           | table    | shop_owner=arwdDxt/shop_owner+|                          | 
        |                  |          | app=arwd/shop_owner          +|                          | 
        |                  |          | reporting=r/shop_owner        |                          | 
 public | orders_id_seq    | sequence |                               |                          | 
(4 rows)
```

Como na lição 12, um teste de outro papel faz login como esse papel, com
`psql -h localhost -U bruno shop` ou `-U app`, e as migrações rodam como `shop_owner` por `SET ROLE`
a partir da sessão da `ana`.
