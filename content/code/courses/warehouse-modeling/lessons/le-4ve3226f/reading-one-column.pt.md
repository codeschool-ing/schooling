---
title: Lendo uma coluna
version: 1
---

A pergunta mais simples que se faz a um warehouse: a receita total. Uma coluna, somada. O PostgreSQL,
perguntado sobre o que leu:

```
ana@lab:~/wh$ psql -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT sum(net_cents) FROM fact_sales" | grep -E 'Seq Scan|Buffers' | head -2
   Buffers: shared hit=2080 read=8064
   ->  Seq Scan on fact_sales (actual rows=887477 loops=1)
ana@lab:~/wh$ psql -c "SELECT pg_relation_size('fact_sales') / 8192 AS pages"
 pages 
-------
 10144
(1 row)
```

**10.144 páginas, todas.** 2.080 já estavam na memória e 8.064 vieram do disco, e juntas são todas as
páginas da tabela. Um banco por linhas não consegue ler `net_cents` sozinha, porque `net_cents` não está
guardada sozinha: são os últimos oito bytes de cada linha, e as linhas enchem as páginas.

O Parquet, perguntado quantos bytes cada coluna ocupa:

```sql
-- How the Parquet file stores each column: bytes before and after encoding.
SELECT path_in_schema               AS column_name,
       sum(total_uncompressed_size) AS raw_bytes,
       sum(total_compressed_size)   AS stored_bytes
FROM parquet_metadata('fact_sales.parquet')
GROUP BY ALL
ORDER BY stored_bytes DESC;
```

```
ana@lab:~/wh$ duckdb < columns.sql
┌────────────────┬───────────┬──────────────┐
│  column_name   │ raw_bytes │ stored_bytes │
│    varchar     │  int128   │    int128    │
├────────────────┼───────────┼──────────────┤
│ order_id       │   7100064 │      2589196 │
│ customer_key   │   5364545 │      2381376 │
│ book_key       │   1502747 │      1419059 │
│ net_cents      │   1140419 │      1119464 │
│ gross_cents    │   1029019 │      1017354 │
│ shop_key       │    328753 │       311035 │
│ line_no        │    337363 │       249141 │
│ quantity       │    221360 │       116206 │
│ discount_cents │    240602 │        93321 │
│ promotion_key  │     54672 │        29578 │
│ date_key       │      5529 │         5602 │
└────────────────┴───────────┴──────────────┘
  11 rows                         3 columns
```

**Para somar `net_cents`, um leitor colunar lê 1.119.464 bytes**: os bytes guardados dessa coluna e nada
mais, de um arquivo de 9.492.481. Doze por cento do arquivo, contra a tabela inteira do PostgreSQL.

Essa é a primeira e mais simples vantagem de guardar por coluna, e ela cresce com a largura da tabela. A
`fact_sales` tem onze colunas estreitas. Uma tabela larga como a da lição 6, com 31 colunas incluindo
títulos e nomes de autores, daria a um banco por linhas trinta colunas de bytes para carregar a cada uma
que ele usa.

Os dois motores, cronometrados nessa soma:

```
ana@lab:~/wh$ psql -f pg-sum.sql
Timing is on.
    sum     
------------
 9574389852
(1 row)

Time: 84.845 ms
ana@lab:~/wh$ duckdb wh.duckdb < duck-sum.sql
┌────────────────┐
│ sum(net_cents) │
│     int128     │
├────────────────┤
│     9574389852 │
└────────────────┘
Run Time (s): real 0.002 user 0.005144 sys 0.000000
```

84,845 milissegundos no PostgreSQL contra 0,002 segundo no DuckDB: cerca de quarenta vezes, numa execução
cada. Ler menos é parte disso. A seção 11 é o resto.
