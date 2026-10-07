---
title: Um feed para um operador
version: 1
---

A Ipê contrata a **Rota Certa**, uma transportadora, para planejar e fazer as suas rotas em São Paulo e
no Rio. Toda manhã a Rota Certa precisa dos pedidos do dia anterior: quantas encomendas, indo para onde.
Pela LGPD a Rota Certa é **operadora** — trata dado pessoal em nome da Ipê e segundo as instruções da
Ipê (artigo 39) —, e a Ipê, controladora, responde pelo que entrega. O GDPR faz a mesma relação exigir
um contrato escrito (artigo 28); a LGPD espera que as instruções sejam claras o bastante para serem
seguidas.

O feed é uma view que expõe exatamente o que o planejamento de rotas precisa:

```sql
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
```

Há três decisões nela, e cada uma é matéria de uma aula anterior:

- **nenhum nome, nenhum e-mail.** Planejar uma rota precisa do CEP, da cidade e do número de
  encomendas. O motorista precisa de um nome na encomenda, e ele é impresso na etiqueta, na loja.
  Mandar nomes num arquivo toda manhã seria mandá-los a mais uma empresa, todo dia, para nada — o
  princípio da necessidade da aula 7;
- **um papel que pode ler a view e nada mais** — o menor privilégio da aula 2, agora para uma empresa em
  vez de uma pessoa;
- **o número do pedido fica**, porque a Rota Certa precisa dizer à Ipê qual encomenda é qual. Nas mãos
  da Ipê ele é dado pessoal, já que a Ipê consegue ligá-lo a um cliente, e o contrato o classifica assim.

## O contrato

```json
{
  "contract": "delivery-feed",
  "version": "1.0.0",
  "owner": "head of sales",
  "consumer": "Rota Certa Logística, a processor (LGPD art. 39)",
  "purpose": "planning the next day's delivery routes",
  "basis": "LGPD art. 7, V: delivering what the customer bought",
  "kept_by_consumer": "30 days",
  "stays_in": "Brazil",
  "fresh_by": "06:00 every day, with the orders of the day before",
  "relation": "share.delivery_feed",
  "fields": [
    {"name": "order_id",   "type": "integer",   "class": "personal", "source": "sales.orders.order_id"},
    {"name": "ordered_on", "type": "date",      "class": "personal", "source": "sales.orders.ordered_at"},
    {"name": "cep",        "type": "text",      "class": "personal", "source": "sales.customers.cep"},
    {"name": "city",       "type": "text",      "class": "personal", "source": "sales.customers.city"},
    {"name": "state",      "type": "character", "class": "personal", "source": "sales.customers.state"},
    {"name": "items",      "type": "bigint",    "class": "none",     "source": "a count of sales.order_items"}
  ],
  "quality": [
    {"rule": "every cep has the shape 00000-000",
     "sql": "SELECT count(*) FROM share.delivery_feed WHERE cep !~ '^[0-9]{5}-[0-9]{3}$'"},
    {"rule": "every order has at least one item",
     "sql": "SELECT count(*) FROM share.delivery_feed WHERE items IS NULL OR items < 1"}
  ]
}
```

Ao lado do esquema, o contrato registra **quem** é o consumidor e em que papel, **por que** o dado é
mandado e com que base, **por quanto tempo** o consumidor o guarda, e **onde** ele fica — os mesmos
fatos de que o registro das operações da aula 7 precisa e que as regras de transferência da aula 8
pedem. Cada campo nomeia a sua coluna de **origem** e a sua **classe**, e a classe não é uma opinião
nova: ela tem de bater com o `gov.column_class`, o que o verificador confere.

```
ana@lab:~/gov$ sudo -u postgres psql -c "CREATE SCHEMA share AUTHORIZATION ipe_owner"
CREATE SCHEMA
ana@lab:~/gov$ psql -f feed.sql
CREATE ROLE
SET
CREATE VIEW
GRANT
GRANT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders, sum(items) AS items FROM share.delivery_feed"
SET
 orders | items 
--------+-------
    119 |   251
(1 row)

ana@lab:~/gov$ python3 check_contract.py delivery-feed.v1.json; echo "exit $?"
delivery-feed 1.0.0: 6 fields and 2 rules, as promised
exit 0
```

119 pedidos e 251 unidades em 30 de junho. O verificador concorda com o contrato.
