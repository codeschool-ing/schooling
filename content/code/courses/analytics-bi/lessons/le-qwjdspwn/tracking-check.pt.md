---
title: Checar os eventos contra o plano, em SQL
version: 1
---

O plano da Lantern tem cinco eventos, um por etapa do caminho até uma compra, e o `web_events` sempre o
seguiu. Em 17 de junho de 2026 sai uma versão nova do app de celular, e os eventos dela chegam numa
tabela de espera antes que alguém os carregue no `web_events`. Este arquivo escreve o plano como uma
tabela e faz o papel do primeiro dia do app — o curso fazendo o papel do app, como faz o da loja. Salve
como `~/tracking.sql`:

```sql
-- tracking.sql: the tracking plan, and a day of events from the new mobile app.
DROP SCHEMA IF EXISTS tracking CASCADE;
CREATE SCHEMA tracking;

CREATE TABLE tracking.plan (
  event   text PRIMARY KEY,
  step    int UNIQUE NOT NULL,
  meaning text NOT NULL
);
INSERT INTO tracking.plan VALUES
  ('visit',        1, 'a session starts on any page'),
  ('product_view', 2, 'a product page is shown'),
  ('add_to_cart',  3, 'a product goes into the cart'),
  ('checkout',     4, 'the checkout page is shown'),
  ('purchase',     5, 'a payment is confirmed');

-- What arrived on 17 June 2026, the new app's first day. The app names one
-- event its own way, and sends some purchases twice when a slow network makes it retry.
CREATE TABLE tracking.incoming AS
SELECT e.session_id, s.device, e.happened_at,
       CASE WHEN s.device = 'mobile' AND e.event = 'add_to_cart' THEN 'addToCart'
            ELSE e.event END AS event
FROM shop.web_events e JOIN shop.web_sessions s USING (session_id)
WHERE e.happened_at >= '2026-06-17' AND e.happened_at < '2026-06-18';
INSERT INTO tracking.incoming
SELECT session_id, device, happened_at, event FROM tracking.incoming
WHERE device = 'mobile' AND event = 'purchase' AND session_id % 2 = 0;
```

```
ana@vm:~$ psql -q lantern -f tracking.sql
psql:tracking.sql:2: NOTICE:  schema "tracking" does not exist, skipping
```

Três checagens, cada uma uma consulta que um job agendado poderia rodar toda manhã antes de carregar os
eventos do dia.

**Eventos que o plano não tem.** Cada nome que chegou, ligado ao plano; os que não casam:

```
lantern=# SELECT i.event, count(*) AS events
lantern-# FROM tracking.incoming i LEFT JOIN tracking.plan p USING (event)
lantern-# WHERE p.event IS NULL
lantern-# GROUP BY i.event;
   event   | events 
-----------+--------
 addToCart |     19
(1 row)
```

**Duplicatas.** O mesmo evento, na mesma sessão, no mesmo instante, mais de uma vez:

```
lantern=# SELECT event, count(*) AS events,
lantern-#        count(DISTINCT (session_id, happened_at)) AS distinct_events
lantern-# FROM tracking.incoming
lantern-# GROUP BY event
lantern-# HAVING count(*) > count(DISTINCT (session_id, happened_at));
  event   | events | distinct_events 
----------+--------+-----------------
 purchase |     19 |              14
(1 row)
```

**Etapas fora de ordem.** Uma etapa que chegou numa sessão sem a etapa anterior. A coluna `step` do
plano faz disso uma consulta só, e não quatro:

```
lantern=# SELECT p.step, p.event, count(DISTINCT i.session_id) AS sessions_without_the_step_before
lantern-# FROM tracking.incoming i JOIN tracking.plan p USING (event)
lantern-# WHERE p.step > 1
lantern-#   AND NOT EXISTS (SELECT 1 FROM tracking.incoming j JOIN tracking.plan q USING (event)
lantern(#                   WHERE j.session_id = i.session_id AND q.step = p.step - 1)
lantern-# GROUP BY p.step, p.event ORDER BY p.step;
 step |  event   | sessions_without_the_step_before 
------+----------+----------------------------------
    4 | checkout |                               12
(1 row)
```

Cada checagem achou algo, e juntas contam uma história só.

- **`addToCart` não está no plano**: 19 eventos, todas as adições ao carrinho que o app novo mandou
  naquele dia, com um nome que ninguém combinou. Nada está errado no código do app nos termos dele; ele
  discorda do plano.
- **Algumas compras foram mandadas duas vezes**: 19 eventos de compra, 14 diferentes. Cinco compras
  seriam contadas duas vezes em todo relatório feito sobre a tabela crua, o que num dia de 14 é um terço
  a mais de compras do que houve.
- **O checkout chegou sem a etapa anterior** em 12 sessões. É a renomeação vista pelo lado do funil: a
  etapa antes do checkout é `add_to_cart`, e no celular ela não existe mais com esse nome.

Nenhuma dessas três consultas sabe nada do app. Elas sabem o plano, e esse é o motivo de escrevê-lo.
