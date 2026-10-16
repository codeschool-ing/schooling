---
title: Quando a sincronização falha, e como você descobre
version: 1
---

Uma sincronização falha de um jeito que um painel nunca falha: em parte. A maioria das linhas chega,
algumas não, e o CRM mostra o que a última requisição bem-sucedida deixou. **A falha é invisível do lado
do CRM**, então a própria sincronização precisa torná-la visível.

A causa mais comum não é a rede. É o modelo e o destino discordarem sobre o que um campo pode guardar. O
marketing pede um valor novo de saúde, *new*, para clientes cujo primeiro pedido tem menos de trinta
dias, e a view é alterada:

```sql
CREATE OR REPLACE VIEW activation.crm_contacts AS
WITH asof AS (SELECT max(order_date) AS day FROM semantic.orders)
SELECT 'lantern-' || c.customer_id AS external_id,
       c.segment, c.region,
       count(o.order_id) AS orders,
       coalesce(sum(o.net_revenue), 0) AS net_revenue,
       max(o.order_date) AS last_order,
       CASE WHEN min(o.order_date) >= asof.day - 30 THEN 'new'
            WHEN max(o.order_date) >= asof.day - 45 THEN 'active'
            WHEN max(o.order_date) >= asof.day - 120 THEN 'at risk'
            ELSE 'lapsed' END AS health
FROM semantic.customers c
CROSS JOIN asof
LEFT JOIN semantic.orders o USING (customer_id)
GROUP BY c.customer_id, c.segment, c.region, asof.day;
```

Ninguém mexeu no CRM, cuja lista de opções ainda tem três valores. A view, depois a próxima
sincronização, mostrando as últimas quatro linhas:

```
lantern=# CREATE OR REPLACE VIEW activation.crm_contacts AS
lantern-# WITH asof AS (SELECT max(order_date) AS day FROM semantic.orders)
lantern-# SELECT 'lantern-' || c.customer_id AS external_id,
lantern-#        c.segment, c.region,
lantern-#        count(o.order_id) AS orders,
lantern-#        coalesce(sum(o.net_revenue), 0) AS net_revenue,
lantern-#        max(o.order_date) AS last_order,
lantern-#        CASE WHEN min(o.order_date) >= asof.day - 30 THEN 'new'
lantern-#             WHEN max(o.order_date) >= asof.day - 45 THEN 'active'
lantern-#             WHEN max(o.order_date) >= asof.day - 120 THEN 'at risk'
lantern-#             ELSE 'lapsed' END AS health
lantern-# FROM semantic.customers c
lantern-# CROSS JOIN asof
lantern-# LEFT JOIN semantic.orders o USING (customer_id)
lantern-# GROUP BY c.customer_id, c.segment, c.region, asof.day;
CREATE VIEW
ana@vm:~/reverse$ bash sync.sh 2>&1 | tail -n 4
lantern-970: HTTP 400 {"error": "health must be one of active, at risk, lapsed"}
lantern-987: HTTP 400 {"error": "health must be one of active, at risk, lapsed"}
lantern-99: HTTP 400 {"error": "health must be one of active, at risk, lapsed"}
run 4: sent 0, removed 0, failed 284, retried after 429: 28
```

Todo contato que virou *new* foi recusado com `400`, e o erro diz por quê. Todo o resto passou. Três
propriedades do script tornaram isso suportável:

- **Uma linha recusada não é lembrada.** Ela fica fora de `last_sent`, então a próxima execução tenta de
  novo, e assim que alguém acrescentar *new* à lista do CRM essas linhas passam sem que ninguém reenvie
  nada à mão.
- **Uma linha recusada é impressa e registrada**, com a explicação do próprio CRM.
- **A execução diz quantas falharam.** Uma sincronização agendada cuja última linha diz `failed 0` toda
  noite, até a noite em que não diz, é o alarme; ler essa linha, ou alertar com base nela, é o trabalho.

O log responde o que aconteceu, execução a execução:

```
lantern=# SELECT run_id, action, http_status, count(*)
lantern-# FROM activation.sync_log GROUP BY 1, 2, 3 ORDER BY 1, 2, 3;
 run_id | action | http_status | count 
--------+--------+-------------+-------
      1 | upsert |         201 |  2649
      2 | upsert |         200 |     1
      3 | delete |         200 |     1
      4 | upsert |         400 |   284
(4 rows)
```

A execução 1 criou todos os contatos, a 2 atualizou um, a 3 apagou um, e as recusas da 4 estão ali com
o código. **Uma sincronização sem log é uma que ninguém consegue depurar**, porque quando alguém nota um
campo errado no CRM, a requisição que o escreveu já se foi.

Volte a view ao que era rodando `activation.sql` de novo — ele também recomeça do zero a memória da
sincronização, então a próxima execução manda todos os contatos outra vez.
