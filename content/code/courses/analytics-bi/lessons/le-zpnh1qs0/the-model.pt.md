---
title: "O modelo: o que o CRM deve saber"
version: 1
---

Uma sincronização manda linhas, então a primeira coisa a escrever é a consulta cujas linhas são o que o
CRM deve conter. As ferramentas de reverse ETL a chamam de **modelo**. Na Lantern é uma linha por
cliente, com um punhado de campos sobre os quais um vendedor pode agir, calculados a partir da camada
semântica da aula 3, para que receita líquida aqui signifique o mesmo que em todo o resto.

O modelo mora num schema próprio, `activation`, ao lado de duas tabelas que são a memória da
sincronização. Crie um diretório para esta aula, `mkdir ~/reverse && cd ~/reverse`, e salve isto nele
como `activation.sql`:

```sql
-- activation.sql: what the CRM should know about each customer, and the sync's memory.
DROP SCHEMA IF EXISTS activation CASCADE;
CREATE SCHEMA activation;

CREATE VIEW activation.crm_contacts AS
WITH asof AS (SELECT max(order_date) AS day FROM semantic.orders)
SELECT 'lantern-' || c.customer_id AS external_id,
       c.segment, c.region,
       count(o.order_id) AS orders,
       coalesce(sum(o.net_revenue), 0) AS net_revenue,
       max(o.order_date) AS last_order,
       CASE WHEN max(o.order_date) >= asof.day - 45 THEN 'active'
            WHEN max(o.order_date) >= asof.day - 120 THEN 'at risk'
            ELSE 'lapsed' END AS health
FROM semantic.customers c
CROSS JOIN asof
LEFT JOIN semantic.orders o USING (customer_id)
GROUP BY c.customer_id, c.segment, c.region, asof.day;

CREATE TABLE activation.last_sent (
  external_id text PRIMARY KEY,
  payload     jsonb NOT NULL,
  sent_at     timestamptz NOT NULL
);

CREATE TABLE activation.sync_log (
  run_id      int NOT NULL,
  external_id text NOT NULL,
  action      text NOT NULL,
  http_status int NOT NULL,
  at          timestamptz NOT NULL DEFAULT now()
);
```

Três decisões estão escritas na view:

- **A chave é `external_id`**, o próprio id de cliente da loja com um prefixo. É a identidade que o CRM
  vai usar para reconhecer o mesmo cliente da próxima vez, e as próximas seções mostram por que ela
  precisa ser o id da loja e não o do CRM.
- **`health` é uma definição**, como tudo na aula 2. Um cliente é *active* se comprou nos últimos 45
  dias, *at risk* até 120, *lapsed* além disso. Quarenta e cinco dias é onde terminam três de cada quatro
  intervalos entre os pedidos de um cliente, pela medição da aula 2; o dia a partir do qual se mede é o
  último dia dos dados, como a aula 6 insistiu, e não a data de hoje.
- **Os campos são poucos**: segmento, região, número de pedidos, receita líquida ao longo da vida,
  último pedido, saúde.

`last_sent` vai guardar, por contato, exatamente o que foi enviado e aceito por último; `sync_log` vai
guardar cada tentativa. Carregue:

```
ana@vm:~/reverse$ psql -q lantern -f activation.sql
psql:activation.sql:2: NOTICE:  schema "activation" does not exist, skipping
```

Três clientes, e como os 2.649 se dividem por saúde:

```
lantern=# SELECT * FROM activation.crm_contacts
lantern-# WHERE external_id IN ('lantern-2', 'lantern-10', 'lantern-1500');
 external_id  | segment |  region   | orders | net_revenue | last_order | health  
--------------+---------+-----------+--------+-------------+------------+---------
 lantern-2    | home    | Southeast |      2 |      329.60 | 2026-03-05 | at risk
 lantern-10   | home    | South     |      1 |       41.31 | 2025-06-11 | lapsed
 lantern-1500 | home    | Southeast |      6 |      553.22 | 2026-01-18 | lapsed
(3 rows)

lantern=# SELECT health, count(*) FROM activation.crm_contacts GROUP BY health ORDER BY 2 DESC;
 health  | count 
---------+-------
 lapsed  |  1073
 active  |   967
 at risk |   609
(3 rows)
```

O cliente 1500 merece um segundo olhar: seis pedidos, R$ 553,22 em toda a vida da loja, e *lapsed* —
nenhum pedido desde janeiro. É o cliente para quem alguém gostaria de ligar, e o motivo de o campo valer
a pena ser enviado.
