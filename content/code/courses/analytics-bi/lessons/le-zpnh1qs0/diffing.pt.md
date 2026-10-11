---
title: Mandar só o que mudou
version: 1
---

Rode a sincronização de novo, na mesma hora:

```
ana@vm:~/reverse$ bash sync.sh
run 2: sent 0, removed 0, failed 0, retried after 429: 0
```

Nada enviado. Esse é o comportamento mais importante do script, e ele vem de uma cláusula na primeira
consulta: `WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb`. O modelo é calculado de novo, cada
linha é comparada com o que `last_sent` diz que foi aceito por último, e só as linhas que diferem são
enviadas. **Uma sincronização que reenvia tudo toda vez** é mais lenta, gasta requisições que o CRM pode
limitar ou cobrar e sobrescreve, toda hora, o que alguém tenha digitado nesses campos desde então.

`IS DISTINCT FROM` e não `<>` porque um contato nunca enviado não tem linha em `last_sent`, então o
payload dele é `NULL`, e `NULL <> qualquer coisa` não é nem verdadeiro nem falso — o contato novo nunca
seria enviado. A aula de `SELECT` de `sql-databases` dedicou uma seção a exatamente isso.

## Um dia depois

Os dados da loja seguem em frente. Para ver uma mudança viajar, acrescente um pedido do cliente 1500 —
aqui é o curso fazendo o papel da loja, como faz o `lantern.sql`:

```sql
INSERT INTO shop.orders VALUES (7103, 1500, '2026-06-17 20:15:00-03', 'paid', 0);
INSERT INTO shop.order_lines VALUES (7103, 1, 4, 1, 4790);
```

```
lantern=# INSERT INTO shop.orders VALUES (7103, 1500, '2026-06-17 20:15:00-03', 'paid', 0);
INSERT 0 1

lantern=# INSERT INTO shop.order_lines VALUES (7103, 1, 4, 1, 4790);
INSERT 0 1
```

Sobre quais contatos o modelo agora discorda do CRM?

```
lantern=# SELECT m.external_id, s.payload ->> 'health' AS sent, m.health AS now
lantern-# FROM activation.crm_contacts m JOIN activation.last_sent s USING (external_id)
lantern-# WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb;
 external_id  |  sent  |  now   
--------------+--------+--------
 lantern-1500 | lapsed | active
(1 row)
```

Um: o CRM ouviu *lapsed*, e o modelo agora diz *active*. A sincronização manda exatamente isso:

```
ana@vm:~/reverse$ bash sync.sh
run 2: sent 1, removed 0, failed 0, retried after 429: 0
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-1500'
[{"external_id": "lantern-1500", "segment": "home", "region": "Southeast", "orders": 7, "net_revenue": 601.12, "last_order": "2026-06-17", "health": "active", "crm_id": 558}]
```

Uma requisição, e o registro do CRM acompanhou o cliente. Ela se chama de execução 2 de novo porque o
número vem do log, e uma execução que não mandou nada não registrou nada. **Esse é o laço inteiro do
reverse ETL**: calcular o modelo, comparar com o que foi enviado, mandar a diferença, lembrar dela.
