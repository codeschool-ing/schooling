---
title: Pagando por byte
version: 1
---

A página de preços sob demanda do BigQuery, lida em 6 de outubro de 2026, diz três coisas que importam a quem
modela:

- as consultas custam **US$ 6,25 por tebibyte** de dados processados, depois do primeiro tebibyte de cada mês,
  que é de graça;
- os dados processados são **o total de dados nas colunas que a consulta seleciona**, contado a partir do tipo
  de cada coluna: 8 bytes para um `INT64` ou um `DATE`, 2 bytes mais o comprimento do texto para uma `STRING`;
- toda tabela que uma consulta cita é cobrada **no mínimo 10 MB**, e toda consulta também.

Isso é uma conta calculada a partir do modelo, e a Ana pode fazê-la antes de o BigQuery entrar na história. A
consulta é a receita de 2025 por departamento, que lê três colunas da tabela fato e duas de cada dimensão:

```sql
-- The bytes BigQuery's on-demand model would bill for one query:
-- revenue of 2025 by department. Every column the query names, over every
-- row of its table, at BigQuery's logical size for the column's type.
WITH read AS (
    SELECT 'fact_sales' AS tbl, 3 * 8 * count(*) AS bytes   -- date_key, book_key, net_cents
    FROM fact_sales
    UNION ALL
    SELECT 'dim_date', 2 * 8 * count(*)                       -- date_key, year
    FROM dim_date
    UNION ALL
    SELECT 'dim_book', 8 * count(*) + sum(2 + strlen(department))
    FROM dim_book                                             -- book_key, department
)
SELECT tbl, bytes,
       greatest(bytes, 10 * 1024 * 1024) AS billed_bytes      -- 10 MB minimum per table
FROM read;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < logical-bytes.sql
┌────────────┬──────────┬──────────────┐
│    tbl     │  bytes   │ billed_bytes │
│  varchar   │  int128  │    int128    │
├────────────┼──────────┼──────────────┤
│ fact_sales │ 21299448 │     21299448 │
│ dim_date   │    11712 │     10485760 │
│ dim_book   │    55854 │     10485760 │
└────────────┴──────────┴──────────────┘
```

**21.299.448 bytes da tabela fato**, todas as linhas de três colunas, diga o `WHERE` o que disser sobre 2025:
nesta tabela não há coluna de partição nem de clustering que um filtro possa usar, então nada reduz os bytes
cobrados. As duas dimensões são minúsculas, e cada uma é cobrada os 10 MB mínimos mesmo assim.

A mesma aritmética para quatro consultas:

```sql
-- The same arithmetic for four queries, priced at US$ 6.25 per TiB.
WITH q (query, bytes) AS (VALUES
    ('revenue by department, all of fact_sales, 3 columns', 3 * 8 * 887477),
    ('SELECT * from fact_sales, all 11 columns',          11 * 8 * 887477),
    ('the first query, on 1,000 times the rows', 1000 * 3 * 8 * CAST(887477 AS BIGINT)),
    ('the same, partitioned by month, asking for one month', 1000 * 3 * 8 * CAST(887477 AS BIGINT) / 24)
)
SELECT query,
       round(bytes / 1024 / 1024 / 1024, 3)                AS gib,
       round(greatest(bytes, 10485760) / 1024 ^ 4 * 6.25, 4) AS usd
FROM q;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < scenarios.sql
┌──────────────────────────────────────────────────────┬────────┬────────┐
│                        query                         │  gib   │  usd   │
│                       varchar                        │ double │ double │
├──────────────────────────────────────────────────────┼────────┼────────┤
│ revenue by department, all of fact_sales, 3 columns  │   0.02 │ 0.0001 │
│ SELECT * from fact_sales, all 11 columns             │  0.073 │ 0.0004 │
│ the first query, on 1,000 times the rows             │ 19.837 │ 0.1211 │
│ the same, partitioned by month, asking for one month │  0.827 │  0.005 │
└──────────────────────────────────────────────────────┴────────┴────────┘
```

No tamanho da Ana toda consulta custa uma fração de centavo, e o tebibyte grátis do mês cobriria milhares
delas. A aritmética importa na terceira linha: **mil vezes os dados, cerca de 20 GiB por consulta, doze
centavos de dólar cada**, rodada por todo painel a cada atualização. E na quarta: a mesma consulta, particionada
por mês e pedindo um mês, custa um vinte e quatro avos.

Três regras de projeto saem direto do preço:

- **`SELECT *` é o hábito caro.** Toda coluna citada é cobrada inteira. A tabela larga da lição 6 é uma
  conveniência paga em toda consulta que a lê sem cuidado.
- **Particione e faça clustering pelo que as consultas filtram**, porque essas são as colunas cujos filtros
  reduzem os bytes cobrados.
- **Um `LIMIT` não deixa a consulta mais barata.** A página de preços conta as colunas lidas, e uma varredura
  que para de mostrar linhas no décimo resultado já leu as colunas.
