---
title: Esquema na leitura, e quanto custa
version: 1
---

Um warehouse é **esquema na escrita** (schema on write): os dados são conferidos contra o modelo na carga, e
recusados se não couberem. Um lake é **esquema na leitura** (schema on read): nada é conferido quando um
arquivo chega, e cada leitor interpreta os arquivos do seu jeito quando os lê.

Uma semana depois, a versão nova do site começa a gravar a exportação com duas diferenças pequenas: uma coluna
renomeada de `customer_id` para `client_id`, e o frete escrito como a palavra `free` onde antes vinha `0`. O
arquivo é feito aqui a partir da última semana de dezembro, para que a mudança apareça ao lado do antigo:

```sql
-- A week later, a file from the website's new version, made here from the
-- last week of December: one column renamed, and shipping written as text.
COPY (SELECT order_id + 1000000 AS order_id, shop_id, customer_id AS client_id,
             ordered_at + INTERVAL 7 DAY AS ordered_at, status,
             CASE WHEN shipping_cents = 0 THEN 'free' ELSE CAST(shipping_cents AS VARCHAR) END
                 AS shipping_cents,
             paid_at + INTERVAL 7 DAY AS paid_at, shipped_at + INTERVAL 7 DAY AS shipped_at,
             delivered_at + INTERVAL 7 DAY AS delivered_at
      FROM read_csv('lake/raw/orders/orders_2025-12-31.csv')
      WHERE ordered_at >= '2025-12-25')
TO 'lake/raw/orders/orders_2026-01-07.csv' (HEADER);
```

```
ana@lab:~/wh$ duckdb < new-export.sql
ana@lab:~/wh$ head -2 lake/raw/orders/orders_2026-01-07.csv
order_id,shop_id,client_id,ordered_at,status,shipping_cents,paid_at,shipped_at,delivered_at
1668353,7,22066,2026-01-01 00:19:38-03,delivered,free,2026-01-01 00:21:32-03,2026-01-05 15:20:07-03,2026-01-07 12:05:50-03
ana@lab:~/wh$ duckdb -c "SELECT count(*) AS orders, sum(shipping_cents) AS shipping FROM read_csv('lake/raw/orders/*.csv')"
Invalid Input Error: Schema mismatch between globbed files.
Main file schema: lake/raw/orders/orders_2025-12-31.csv
Current file: lake/raw/orders/orders_2026-01-07.csv
Column with name: "customer_id" is missing
Column with name: "shipping_cents" is expected to have type: BIGINT But has type: VARCHAR
Potential Fixes 
* Consider setting union_by_name=true.
* Consider setting files_to_sniff to a higher value (e.g., files_to_sniff = -1)

ana@lab:~/wh$ duckdb -c "SELECT count(*) AS orders, count(customer_id) AS with_customer FROM read_csv('lake/raw/orders/*.csv', union_by_name = true)"
┌────────┬───────────────┐
│ orders │ with_customer │
│ int64  │     int64     │
├────────┼───────────────┤
│ 586584 │        430221 │
└────────┴───────────────┘
```

O arquivo novo está ao lado do antigo, e nada reclamou quando ele chegou. O primeiro leitor a pedir a pasta
inteira recebe um erro que diz exatamente o que aconteceu: uma coluna faltando, outra com o tipo errado. Esse é
o desfecho bom. O leitor que segue a sugestão do próprio DuckDB, `union_by_name = true`, recebe uma resposta e
nenhum erro: 586.584 pedidos, dos quais 430.221 têm cliente. **Todos os pedidos da semana nova perderam o
cliente**, porque agora ele está numa coluna chamada `client_id` que essa consulta nunca menciona.

Isso é esquema na leitura num exemplo só:

- **O problema é achado por quem lê, não por quem escreve**, e achado tarde: o arquivo chegou há uma semana, e
  quem poderia corrigi-lo não é quem o encontrou.
- **Cada leitor o encontra por conta própria**, e decide por conta própria o que fazer. Um falha, outro segue
  com um número menor, um terceiro escreve um contorno que o próximo leitor desconhece.

Um warehouse teria recusado o arquivo na porta, com uma mensagem para quem o envia. É isso que o esquema na
escrita compra, e a seção 10 mostra uma tabela no lake recuperando isso.
