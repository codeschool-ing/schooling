---
title: Quebrando, duas vezes
version: 1
---

## Um campo que ninguém combinou

Um chamado diz que os motoristas gostariam de ver o nome do cliente na tela. Alguém o acrescenta à view:

```
ana@lab:~/gov$ cat labels.sql
-- "The driver needs the name for the label", says a ticket. Nobody asks the
-- owner, nobody changes the contract.
SET ROLE ipe_owner;
CREATE OR REPLACE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT sum(i.quantity) FROM sales.order_items i WHERE i.order_id = o.order_id) AS items,
       c.full_name
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
ana@lab:~/gov$ psql -f labels.sql
SET
CREATE VIEW
ana@lab:~/gov$ python3 check_contract.py delivery-feed.v1.json; echo "exit $?"
delivery-feed 1.0.0: 1 problem(s)
  full_name: served, and not in the contract
exit 1
```

A view mudou sem reclamar — `CREATE OR REPLACE VIEW` aceita uma coluna nova no fim. O verificador não:
`full_name` é servido e não está no contrato, e ele sai com 1. Num pipeline, a mudança para ali.

O que deveria acontecer em seguida não é "acrescentar `full_name` ao contrato". É a pergunta que o
contrato existe para forçar: a Rota Certa é operadora, o nome é dado identificador, e a finalidade era
planejar rotas. Se os motoristas precisam mesmo de nomes na tela, isso é uma **finalidade nova**,
decidida pelo dono, escrita na finalidade e na base do contrato, e provavelmente um motivo para o
encarregado da aula 7 olhar. A verificação não decide isso. Ela garante que alguém decida.

## Uma mudança que parecia inofensiva

Um segundo desenvolvedor arruma a view e, no caminho, muda como `items` é calculado — linhas do pedido
em vez das unidades pedidas —, com um cast para `integer` por capricho:

```sql
-- Back to the contract's columns, and one "harmless" change: items counted
-- as lines rather than summed as units, and cast to integer on the way.
SET ROLE ipe_owner;
DROP VIEW share.delivery_feed;
CREATE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT count(*) FROM sales.order_items i WHERE i.order_id = o.order_id)::integer AS items
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
GRANT SELECT ON share.delivery_feed TO rota_certa;
```

```
ana@lab:~/gov$ psql -f typechange.sql
SET
DROP VIEW
CREATE VIEW
GRANT
ana@lab:~/gov$ python3 check_contract.py delivery-feed.v1.json; echo "exit $?"
delivery-feed 1.0.0: 1 problem(s)
  items: contract says bigint, served as integer
exit 1
```

O verificador pegou, **por sorte**. O tipo mudou de `bigint` para `integer` só por causa do cast. Sem
ele, `count(*)` devolve `bigint`, o mesmo que `sum()`, e a verificação teria passado enquanto todo
número do feed mudava de sentido: o CSV da seção 8 mostra 3, 6 e 1 unidades onde esta versão mandaria
2, 3 e 1 linhas. A Rota Certa planejaria as vans para metade das encomendas.

É por isso que um contrato é mais do que um esquema. Duas coisas teriam pegado isso sem sorte:

- **a semântica escrita** — `items` descrito como *unidades pedidas*, para um revisor que lê o diff ver
  `count(*)` e saber que está errado;
- **uma regra de qualidade que testa o sentido**, e não o formato: o total do feed num dia é igual à
  soma de `sales.order_items.quantity` dos pedidos daquele dia. Regras assim são baratas, e são as
  únicas que notam uma coluna que manteve o nome e mudou de ideia.
