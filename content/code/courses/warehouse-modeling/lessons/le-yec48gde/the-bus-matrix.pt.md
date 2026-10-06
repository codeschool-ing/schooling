---
title: A matriz de barramento
version: 1
---

A ferramenta de Kimball para manter os marts dependentes é uma tabela de uma página, a **matriz de barramento** (bus
matrix). Suas linhas são os processos de negócio que o warehouse mede, cada um uma tabela fato ou uma família delas.
Suas colunas são as dimensões conformadas. Um `x` no cruzamento diz que aquele processo é descrito por aquela
dimensão, com as mesmas chaves e as mesmas linhas de todo outro processo que a usa.

O warehouse de Ana consegue desenhar a própria matriz, porque cada `x` é uma coluna de chave numa tabela fato:

```sql
-- The bus matrix, read off the warehouse itself: one row per fact table,
-- an x wherever it carries a dimension's key.
SELECT table_name AS process,
       CASE WHEN bool_or(column_name LIKE '%date_key') THEN 'x' ELSE '' END AS "date",
       CASE WHEN bool_or(column_name = 'shop_key')      THEN 'x' ELSE '' END AS shop,
       CASE WHEN bool_or(column_name = 'book_key')      THEN 'x' ELSE '' END AS book,
       CASE WHEN bool_or(column_name = 'customer_key')  THEN 'x' ELSE '' END AS customer,
       CASE WHEN bool_or(column_name = 'promotion_key') THEN 'x' ELSE '' END AS promotion,
       CASE WHEN bool_or(column_name = 'author_key')    THEN 'x' ELSE '' END AS author
FROM duckdb_columns()
WHERE schema_name = 'main' AND table_name LIKE 'fact\_%' ESCAPE '\'
GROUP BY table_name
ORDER BY table_name;
```

```
ana@lab:~/wh$ duckdb -readonly wh.duckdb < bus.sql
┌───────────────────────┬─────────┬─────────┬─────────┬──────────┬───────────┬─────────┐
│        process        │  date   │  shop   │  book   │ customer │ promotion │ author  │
│        varchar        │ varchar │ varchar │ varchar │ varchar  │  varchar  │ varchar │
├───────────────────────┼─────────┼─────────┼─────────┼──────────┼───────────┼─────────┤
│ fact_event_attendance │ x       │ x       │         │ x        │           │ x       │
│ fact_fulfilment       │ x       │         │         │ x        │           │         │
│ fact_inventory        │ x       │ x       │ x       │          │           │         │
│ fact_payments         │ x       │ x       │         │ x        │           │         │
│ fact_sales            │ x       │ x       │ x       │ x        │ x         │         │
└───────────────────────┴─────────┴─────────┴─────────┴──────────┴───────────┴─────────┘
```

Leia uma coluna de cima a baixo e você vê o que pode ser comparado entre processos. **A data atravessa os cinco**,
então quaisquer dois processos podem ser postos numa mesma linha do tempo. O cliente atravessa quatro, então as
compras, os pagamentos, as entregas e as idas a eventos com autores de um cliente podem ser contados juntos. Vendas e
estoque compartilham data, loja e livro, e foi nisso que se apoiou o drill across da lição 3, os meses de estoque por
loja.

Leia uma linha e você vê por onde um processo pode ser recortado. A `fact_fulfilment` não tem loja: todo pedido que
ela acompanha foi enviado, e só a loja online envia, então uma chave de loja teria um valor só. Uma célula vazia é
uma decisão, e a matriz a deixa à vista.

A matriz também é um plano. Um warehouse construído pelo método de Kimball cresce uma linha por vez: cada processo
novo é uma tabela fato nova, e **suas dimensões são as colunas que já existem**, reaproveitadas em vez de refeitas.
Um time que propõe um mart novo é convidado a pô-lo na matriz primeiro. Se a linha dele precisa de uma dimensão que
já tem coluna, usa essa coluna; se precisa de uma nova, a coluna nova é construída uma vez, para todos. Dois marts
desenhados numa mesma matriz não conseguem discordar sobre o que é um cliente.

No papel, a matriz é desenhada antes de qualquer coisa ser construída. Gerada a partir do catálogo, como aqui, ela
mostra o que de fato foi construído, e comparar as duas é uma revisão que vale fazer uma vez por ano.
