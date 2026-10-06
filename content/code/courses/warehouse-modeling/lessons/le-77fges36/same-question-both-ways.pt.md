---
title: A mesma pergunta, dos dois jeitos
version: 1
---

A pergunta da seção 03, feita ao floco de neve:

```sql
-- The same question, against the snowflake.
SELECT s.region, dep.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d         USING (date_key)
JOIN dim_shop s         USING (shop_key)
JOIN sf_book b          USING (book_key)
JOIN sf_category c      USING (category_key)
JOIN sf_subcategory sub USING (subcategory_key)
JOIN sf_department dep  USING (department_key)
WHERE d.year = 2025 AND d.is_weekend AND s.channel = 'store'
GROUP BY ALL
ORDER BY s.region, revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < snow-query.sql
┌───────────┬─────────────┬─────────────┐
│  region   │ department  │ revenue_brl │
│  varchar  │   varchar   │   double    │
├───────────┼─────────────┼─────────────┤
│ South     │ Non-fiction │   933966.85 │
│ South     │ Fiction     │   898410.57 │
│ South     │ Children    │   156987.64 │
│ South     │ Comics      │   109634.74 │
│ Southeast │ Non-fiction │  3587030.82 │
│ Southeast │ Fiction     │  3456519.62 │
│ Southeast │ Children    │   614230.24 │
│ Southeast │ Comics      │   469070.82 │
└───────────┴─────────────┴─────────────┘
```

**As mesmas oito linhas, até o centavo.** O modelo mudou e o significado não, que é o que uma
normalização deve fazer.

O que mudou foi a consulta. Para chegar ao departamento ela agora percorre mais três tabelas, numa
ordem fixa, por chaves cujos nomes alguém precisa saber: livro para categoria, categoria para
subcategoria, subcategoria para departamento. Pergunte ao DuckDB quantas junções cada consulta custa:

```
ana@lab:~/wh$ { echo 'EXPLAIN (FORMAT json)'; cat star-query.sql; } | duckdb -list wh.duckdb | grep -o HASH_JOIN | wc -l
3
ana@lab:~/wh$ { echo 'EXPLAIN (FORMAT json)'; cat snow-query.sql; } | duckdb -list wh.duckdb | grep -o HASH_JOIN | wc -l
6
```

Três junções contra seis. As três a mais são baratas aqui, porque as tabelas que alcançam têm 4, 15 e
28 linhas. Não são de graça no outro sentido: **toda pessoa que escreve um relatório precisa conhecer a
cadeia**, e quem liga `sf_book` direto a `sf_subcategory`, pulando a categoria, recebe um erro na melhor
das hipóteses e uma resposta errada na pior.

Essa é a troca, dita sem rodeios. O floco de neve guarda cada nome uma vez. A estrela pede a cada
leitor uma junção por dimensão. A próxima seção põe um número no que a primeira vale.
