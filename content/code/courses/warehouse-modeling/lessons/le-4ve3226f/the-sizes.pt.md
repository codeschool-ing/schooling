---
title: Uma tabela, quatro tamanhos
version: 2
---

A `fact_sales` exportada como arquivo CSV, carregada no PostgreSQL, copiada para um arquivo DuckDB
próprio, e gravada em Parquet. A cópia no PostgreSQL é feita pelo `to-postgres.sql`:

```sql
-- The same fact table, stored by row in PostgreSQL.
CREATE TABLE fact_sales (date_key int, shop_key int, book_key int, customer_key int,
    promotion_key int, order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint);
\copy fact_sales FROM 'fact_sales.csv' WITH (FORMAT csv, HEADER true)
VACUUM ANALYZE fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb -c "COPY fact_sales TO 'fact_sales.csv' (HEADER); COPY fact_sales TO 'fact_sales.parquet'"
ana@lab:~/wh$ psql -q -f to-postgres.sql
ana@lab:~/wh$ duckdb only_sales.duckdb -c "ATTACH 'wh.duckdb' AS wh (READ_ONLY); CREATE TABLE fact_sales AS FROM wh.fact_sales"
ana@lab:~/wh$ psql -c "SELECT pg_size_pretty(pg_table_size('fact_sales')) AS postgres_table"
 postgres_table 
----------------
 79 MB
(1 row)

ana@lab:~/wh$ ls -l fact_sales.csv only_sales.duckdb fact_sales.parquet
-rw-r--r-- 1 ana ana 41418346 Oct  6 14:14 fact_sales.csv
-rw-r--r-- 1 ana ana  9492481 Oct  6 14:14 fact_sales.parquet
-rw-r--r-- 1 ana ana  9449472 Oct  6 14:14 only_sales.duckdb
```

| | bytes | contra o PostgreSQL |
|---|---|---|
| tabela no PostgreSQL | 79 MB | 1 |
| texto CSV | 41.418.346 | cerca de metade |
| arquivo DuckDB | 9.449.472 | cerca de um oitavo |
| arquivo Parquet | 9.492.481 | cerca de um oitavo |

**As mesmas 887.477 linhas, os mesmos onze números em cada uma, ocupam um oitavo do espaço por coluna.**
Não porque os arquivos colunares jogaram algo fora: a lição 6 somou `net_cents` nos dois e obteve o mesmo
total até o centavo.

A tabela por linhas do PostgreSQL é maior até que o arquivo de texto, por motivos que são do trabalho
dela, e não desperdício. Cada linha carrega um cabeçalho de umas duas dúzias de bytes que o caixa precisa
para transações concorrentes. Cada número ocupa os seus quatro ou oito bytes inteiros, seja 3 ou 677.468.
E as páginas guardam algum espaço livre para uma atualização poder ficar no lugar.

Os arquivos colunares são menores até que o texto. Eles não comprimem
caracteres, como um arquivo zip. Usam o que sabem sobre cada coluna: que ela guarda um tipo, muitas vezes
numa faixa estreita, muitas vezes em longas sequências do mesmo valor. As próximas seções pegam esses
truques um a um, e os próprios metadados do Parquet mostram para onde foi cada byte.
