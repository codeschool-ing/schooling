---
title: A tabela larga é mais rápida?
version: 1
---

A tabela larga remove todas as junções. Isso deixa as perguntas mais rápidas? A mesma pergunta feita à
estrela e à tabela larga, receita de 2025 por departamento e nível:

```sql
.timer on
SELECT b.department, c.tier, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_book b     USING (book_key)
JOIN dim_customer c USING (customer_key)
JOIN dim_date d     USING (date_key)
WHERE d.year = 2025 AND c.customer_key > 0
GROUP BY ALL ORDER BY ALL;
```

```sql
.timer on
SELECT department, tier, round(sum(net_cents) / 100, 2) AS revenue_brl
FROM sales_wide
WHERE year = 2025 AND tier <> 'none'
GROUP BY ALL ORDER BY ALL;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < q-star.sql
┌─────────────┬─────────┬─────────────┐
│ department  │  tier   │ revenue_brl │
│   varchar   │ varchar │   double    │
├─────────────┼─────────┼─────────────┤
│ Children    │ patron  │    64538.64 │
│ Children    │ reader  │  2673636.49 │
│ Children    │ regular │   270455.42 │
│ Comics      │ patron  │    49897.85 │
│ Comics      │ reader  │  1997493.71 │
│ Comics      │ regular │   208862.41 │
│ Fiction     │ patron  │   385006.81 │
│ Fiction     │ reader  │ 15176024.87 │
│ Fiction     │ regular │  1583683.24 │
│ Non-fiction │ patron  │   398083.85 │
│ Non-fiction │ reader  │ 15842487.94 │
│ Non-fiction │ regular │  1657785.15 │
└─────────────┴─────────┴─────────────┘
  12 rows                   3 columns
Run Time (s): real 0.021 user 0.052665 sys 0.010438
ana@lab:~/wh$ duckdb wh.duckdb < q-wide.sql
┌─────────────┬─────────┬─────────────┐
│ department  │  tier   │ revenue_brl │
│   varchar   │ varchar │   double    │
├─────────────┼─────────┼─────────────┤
│ Children    │ patron  │    64538.64 │
│ Children    │ reader  │  2673636.49 │
│ Children    │ regular │   270455.42 │
│ Comics      │ patron  │    49897.85 │
│ Comics      │ reader  │  1997493.71 │
│ Comics      │ regular │   208862.41 │
│ Fiction     │ patron  │   385006.81 │
│ Fiction     │ reader  │ 15176024.87 │
│ Fiction     │ regular │  1583683.24 │
│ Non-fiction │ patron  │   398083.85 │
│ Non-fiction │ reader  │ 15842487.94 │
│ Non-fiction │ regular │  1657785.15 │
└─────────────┴─────────┴─────────────┘
  12 rows                   3 columns
Run Time (s): real 0.017 user 0.036533 sys 0.007763
```

As mesmas doze linhas. **0,021 segundo com três junções, 0,017 sem nenhuma**: uma execução cada, numa
máquina compartilhada, e a diferença é do tamanho do ruído. As junções eram com tabelas dimensão
pequenas, e um motor colunar monta uma tabela de busca para cada uma numa fração de milissegundo e passa
a tabela fato por elas uma vez.

Então o argumento de velocidade a favor da tabela larga é fraco num warehouse colunar deste tamanho. O
que ela oferece é real, e é sobre pessoas e ferramentas, não milissegundos:

- **Nenhuma junção para escrever**, o que serve a ferramentas que trabalham com uma tabela de cada vez:
  alguns produtos de painel, uma exportação para planilha, um cientista de dados carregando um dataframe.
- **Um objeto só** para dar acesso, descrever e documentar.

E os custos dela:

- **Precisa ser reconstruída, não editada**, como a seção 04 mostrou.
- **É uma granularidade só.** Uma pergunta sobre estoque ou pagamentos não se responde com uma tabela de
  itens de venda.
- **Todo atributo novo é uma coluna nova na maior tabela**, reconstruída do zero.

**A resposta comum é ter as duas**: a estrela como modelo, mantida pela carga; e uma ou duas tabelas
largas construídas a partir dela, como views ou como tabelas refeitas depois de cada carga, para as
ferramentas que as querem. A tabela larga é uma saída do warehouse, não a fundação dele.
