---
title: Fazendo uma pergunta a uma estrela
version: 1
---

O gerente quer a receita de fins de semana em 2025, só das lojas físicas, por região e departamento.
Sobre a estrela, a consulta se lê como a frase:

```sql
-- Revenue in 2025 by region and department, weekends only, physical shops.
SELECT s.region, b.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
JOIN dim_book b USING (book_key)
WHERE d.year = 2025 AND d.is_weekend AND s.channel = 'store'
GROUP BY ALL
ORDER BY s.region, revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < star-query.sql
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

Cada parte da pergunta foi parar num lugar previsível:

| a pergunta diz | a consulta faz |
|---|---|
| em 2025, nos fins de semana | filtra a `dim_date` |
| lojas físicas | filtra a `dim_shop` |
| por região | agrupa por uma coluna da `dim_shop` |
| por departamento | agrupa por uma coluna da `dim_book` |
| receita | soma uma medida da `fact_sales` |

**Filtros e agrupamentos vêm das dimensões; somas vêm dos fatos.** Essa é a gramática inteira, e é por
isso que se pode confiar a um usuário de negócio com uma ferramenta de relatório a montagem de
perguntas sobre uma estrela: a ferramenta oferece as colunas das dimensões como coisas para arrastar
para linhas e colunas, e as medidas como coisas para totalizar. Os caminhos de junção nunca mudam,
então a ferramenta consegue escrevê-los.

O Sudeste vende cerca de quatro vezes o que o Sul vende nos fins de semana, e a ordem dos departamentos
é a mesma nas duas regiões: Non-fiction, Fiction, Children, Comics. A consulta não exigiu mais
raciocínio que a frase, e esse é o ponto do projeto.
