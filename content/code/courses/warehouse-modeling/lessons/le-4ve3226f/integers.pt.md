---
title: Inteiros em tão poucos bits quanto precisam
version: 1
---

Toda coluna inteira da `fact_sales` está declarada como inteiro de 64 bits, oito bytes. Veja quanto
desses oito bytes cada uma precisa:

```sql
-- The range of values in some integer columns, and the bits that range needs.
SELECT 'quantity' AS column_name, min(quantity) AS lowest, max(quantity) AS highest,
       ceil(log2(max(quantity) - min(quantity) + 1)) AS bits_needed FROM fact_sales
UNION ALL
SELECT 'shop_key', min(shop_key), max(shop_key),
       ceil(log2(max(shop_key) - min(shop_key) + 1)) FROM fact_sales
UNION ALL
SELECT 'order_id', min(order_id), max(order_id),
       ceil(log2(max(order_id) - min(order_id) + 1)) FROM fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < ints.sql
┌─────────────┬────────┬─────────┬─────────────┐
│ column_name │ lowest │ highest │ bits_needed │
│   varchar   │ int64  │  int64  │   double    │
├─────────────┼────────┼─────────┼─────────────┤
│ quantity    │      1 │       3 │         2.0 │
│ shop_key    │      1 │       7 │         3.0 │
│ order_id    │ 100001 │  677468 │        20.0 │
└─────────────┴────────┴─────────┴─────────────┘
```

`quantity` é sempre 1, 2 ou 3: dois bits de informação, guardados em sessenta e quatro. `shop_key`
precisa de três. Até `order_id`, que passa de meio milhão, varia numa faixa que cabe em vinte bits depois
de descontado o menor valor.

Duas técnicas juntas aproveitam isso:

- **Quadro de referência** (frame of reference). Guarde o mínimo do bloco uma vez, e cada valor como a
  distância até ele. O `order_id` 677.468 vira 577.467 acima de uma base de 100.001, um número menor de
  guardar.
- **Empacotamento em bits** (bit-packing). Guarde cada valor em exatamente tantos bits quantos o maior do
  bloco precisa, juntos e sem preenchimento. Um bloco de quantidades vira uma sequência de números de 2
  bits, trinta e dois a cada oito bytes.

Esse é o `BitPacking` que o DuckDB informou para a maioria das colunas. Os metadados do Parquet da seção
anterior mostram a mesma ideia em ação: `quantity` ocupa 116.206 bytes para 887.477 valores, cerca de um
bit cada, onde o tipo teria ocupado sessenta e quatro.

**O tipo declarado não decide o armazenamento.** Escolher `BIGINT` para uma coluna de números pequenos
quase não custa nada num banco por colunas, porque a codificação olha os valores. Num banco por linhas
custa os oito bytes inteiros por linha, em toda linha, e esse é um dos motivos de as tabelas da lição 6
serem três vezes maiores no PostgreSQL.
