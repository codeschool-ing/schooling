---
title: Agregados, a tabela mais desnormalizada de todas
version: 1
---

Um painel que mostra a receita por mês, loja e departamento não precisa de 887.477 itens de venda.
Precisa das somas deles. Guardar essas somas é a desnormalização levada até o fim: em vez de repetir um
atributo em cada linha, as próprias linhas são condensadas numa por grupo.

```sql
-- A pre-summed table: revenue by month, shop and department.
CREATE TABLE agg_sales_month AS
SELECT d.year, d.month, f.shop_key, b.department,
       sum(f.quantity) AS books, sum(f.net_cents) AS net_cents
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_book b USING (book_key)
GROUP BY ALL;

SELECT (SELECT count(*) FROM fact_sales)      AS fact_rows,
       (SELECT count(*) FROM agg_sales_month) AS aggregate_rows,
       (SELECT sum(net_cents) FROM fact_sales)      AS fact_total,
       (SELECT sum(net_cents) FROM agg_sales_month) AS aggregate_total;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < agg.sql
┌───────────┬────────────────┬────────────┬─────────────────┐
│ fact_rows │ aggregate_rows │ fact_total │ aggregate_total │
│   int64   │     int64      │   int128   │     int128      │
├───────────┼────────────────┼────────────┼─────────────────┤
│    887477 │            616 │ 9574389852 │      9574389852 │
└───────────┴────────────────┴────────────┴─────────────────┘
```

**616 linhas em vez de 887.477**, e o mesmo total até o centavo. Uma consulta de "receita por mês e
departamento" lê 616 linhas em vez de quase 900 mil, o que importa muito quando a tabela fato tem bilhões
de linhas, e um pouco menos neste tamanho.

Kimball chama isso de **tabelas fato agregadas**, e elas seguem três regras:

- **São derivadas, nunca carregadas da origem.** Construídas a partir da tabela fato atômica, para as
  duas não poderem discordar sobre os dados.
- **São uma otimização, não um modelo.** Ninguém deveria precisar saber que existem para obter uma
  resposta certa. Alguns bancos, diante de uma materialized view, reescrevem uma consulta à tabela fato
  para ler o agregado; uma ferramenta de relatório pode fazer o mesmo.
- **Mantêm as mesmas dimensões conformadas**, agregadas. A `agg_sales_month` aponta para `shop_key` como
  a `fact_sales`, e o mês e o departamento dela são os mesmos valores que a `dim_date` e a `dim_book`
  guardam.

A terceira regra é o motivo de o agregado não ser uma coisa nova: é uma tabela fato numa granularidade
mais grossa, e a frase de granularidade da lição 4 vale para ele. "Uma linha por mês, loja e
departamento." A próxima seção é sobre o que acontece quando a tabela de baixo muda.
