---
title: Quanto a repetição custa em bytes
version: 1
---

O outro argumento contra repetir valores é o espaço. Ele depende quase todo de como o banco guarda os
dados, então meça duas vezes: uma no PostgreSQL, que guarda linhas, e outra em Parquet, o formato de
arquivo colunar que a lição 8 desmonta.

```sql
SELECT 'star: fact and five dimensions' AS model,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS size
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'wh' AND c.relkind = 'r' AND c.relname <> 'sales_wide'
UNION ALL
SELECT 'one big table', pg_size_pretty(pg_total_relation_size('wh.sales_wide'));
```

```sql
COPY fact_sales    TO 'pq/fact_sales.parquet';
COPY dim_date      TO 'pq/dim_date.parquet';
COPY dim_shop      TO 'pq/dim_shop.parquet';
COPY dim_book      TO 'pq/dim_book.parquet';
COPY dim_customer  TO 'pq/dim_customer.parquet';
COPY dim_promotion TO 'pq/dim_promotion.parquet';
COPY sales_wide    TO 'pq/sales_wide.parquet';
SELECT CASE WHEN file LIKE '%sales_wide%' THEN 'one big table'
            ELSE 'star: fact and five dimensions' END AS model,
       sum(size) AS bytes
FROM (SELECT filename AS file, size FROM read_blob('pq/*.parquet'))
GROUP BY ALL ORDER BY bytes;
```

```
ana@lab:~/wh$ mkdir -p pg pq && duckdb wh.duckdb < export.sql
ana@lab:~/wh$ psql -q -f pg-load.sql
ana@lab:~/wh$ psql -f pg-sizes.sql
             model              |  size  
--------------------------------+--------
 star: fact and five dimensions | 85 MB
 one big table                  | 242 MB
(2 rows)

ana@lab:~/wh$ duckdb wh.duckdb < pq-sizes.sql
┌────────────────────────────────┬──────────┐
│             model              │  bytes   │
│            varchar             │  int128  │
├────────────────────────────────┼──────────┤
│ star: fact and five dimensions │ 10911040 │
│ one big table                  │ 14446367 │
└────────────────────────────────┴──────────┘
```

| | estrela | tabela larga | larga contra estrela |
|---|---|---|---|
| PostgreSQL, por linha | 85 MB | 242 MB | 2,8 vezes |
| Parquet, por coluna | 10.911.040 bytes | 14.446.367 bytes | 1,3 vez |

**Por linha, a tabela larga custa quase três vezes a estrela.** Cada linha carrega o título, os autores,
a editora, o nome e a cidade da loja, tudo escrito por extenso, 887.477 vezes.

**Por coluna, custa cerca de um terço a mais.** Uma coluna de nomes de departamento é a mesma dúzia de
palavras repetida em longas sequências, e um formato colunar guarda uma sequência de palavras repetidas
como a palavra e uma contagem, ou como um número pequeno apontando para uma lista das palavras. A lição 8
mostra exatamente como. A repetição que triplicou o tamanho num banco por linhas quase não mexe num banco
por colunas.

Esse é o principal motivo de modelos desnormalizados terem virado o normal em análise. **O argumento de
espaço a favor da normalização foi feito num mundo de bancos por linhas**, e num banco por colunas a
maior parte dele some. O argumento da atualização, da seção anterior, não some, e a próxima seção olha o
que o espaço comprou.
