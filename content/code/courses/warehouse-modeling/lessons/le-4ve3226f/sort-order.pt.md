---
title: A ordem das linhas importa
version: 1
---

A codificação por sequência só funciona quando valores iguais estão lado a lado, e o dicionário e o
empacotamento em bits funcionam melhor quando valores próximos são parecidos. Então a ordem em que as
linhas são gravadas muda o quanto uma coluna encolhe. Grave as mesmas linhas em três ordens: embaralhadas,
como foram carregadas, e ordenadas por loja e data:

```sql
-- The same rows in three orders: shuffled, as loaded, and sorted by shop and date.
COPY (SELECT * FROM fact_sales ORDER BY hash(order_id, line_no)) TO 'shuffled.parquet';
COPY (SELECT * FROM fact_sales ORDER BY order_id, line_no)       TO 'by_order.parquet';
COPY (SELECT * FROM fact_sales ORDER BY shop_key, date_key)      TO 'by_shop_date.parquet';

SELECT file_name,
       sum(total_compressed_size) FILTER (WHERE path_in_schema = 'shop_key') AS shop_key_bytes,
       sum(total_compressed_size) FILTER (WHERE path_in_schema = 'date_key') AS date_key_bytes,
       sum(total_compressed_size)                                            AS all_columns
FROM parquet_metadata(['shuffled.parquet', 'by_order.parquet', 'by_shop_date.parquet'])
GROUP BY file_name ORDER BY all_columns DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < order.sql
┌──────────────────────┬────────────────┬────────────────┬─────────────┐
│      file_name       │ shop_key_bytes │ date_key_bytes │ all_columns │
│       varchar        │     int128     │     int128     │   int128    │
├──────────────────────┼────────────────┼────────────────┼─────────────┤
│ shuffled.parquet     │         337262 │        1136811 │    13403406 │
│ by_order.parquet     │         311035 │           5602 │     9331332 │
│ by_shop_date.parquet │            524 │          34696 │     9317594 │
└──────────────────────┴────────────────┴────────────────┴─────────────┘
```

As mesmas 887.477 linhas, três arquivos:

- **Embaralhadas**, 13.403.406 bytes. Toda coluna está o mais espalhada possível.
- **Em ordem de número de pedido**, como o warehouse as carregou, 9.331.332 bytes. `date_key` cai de
  1.136.811 bytes para 5.602, porque as datas sobem com os números de pedido e as vendas de um dia ficam
  juntas.
- **Ordenadas por loja e data**, mais ou menos o mesmo total, e `shop_key` ocupa **524 bytes**: sete
  sequências, uma por loja, para a coluna inteira.

**Ordenar mexeu no total em cerca de 30%, e numa única coluna por um fator de seiscentos.** Um warehouse
que carrega em ordem de data ganha a maior parte disso de graça, porque dados novos chegam em ordem de
data. O resto é uma escolha: ordenar pelas colunas que as consultas mais filtram as comprime melhor, e a
próxima seção mostra que também deixa um leitor pular quase todo o arquivo.

Os warehouses na nuvem expõem a mesma decisão com outros nomes: uma **sort key** no Redshift, uma
**chave de clustering** no Snowflake e no BigQuery. A lição 9 mostra cada uma.
