---
title: O que você pode somar
version: 1
---

Um warehouse existe para ser somado, então a primeira pergunta a fazer a qualquer medida é **por
quais dimensões ela pode ser somada e ainda significar algo.** Há três respostas, e cada medida tem
exatamente uma delas.

## Aditiva: em tudo

Quantidade, bruto, desconto e líquido somam em todas as dimensões. Some por loja, por mês, por livro
ou sobre a tabela inteira, e o resultado é um total verdadeiro:

```sql
SELECT s.shop_name,
       sum(f.quantity)                                   AS books,
       sum(f.net_cents)                                  AS net_cents,
       round(100.0 * sum(f.discount_cents) / sum(f.gross_cents), 2) AS discount_pct
FROM fact_sales f JOIN dim_shop s USING (shop_key)
GROUP BY ALL ORDER BY net_cents DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < additive.sql
┌───────────┬────────┬────────────┬──────────────┐
│ shop_name │ books  │ net_cents  │ discount_pct │
│  varchar  │ int128 │   int128   │    double    │
├───────────┼────────┼────────────┼──────────────┤
│ Online    │ 415722 │ 4066937959 │         1.32 │
│ Paulista  │ 162288 │ 1591634703 │         0.44 │
│ Pinheiros │ 128815 │ 1266135132 │         0.43 │
│ Savassi   │  94250 │  925370751 │         0.41 │
│ Cambuí    │  80577 │  792418486 │         0.41 │
│ Batel     │  66780 │  656724950 │         0.44 │
│ Moinhos   │  26895 │  275167871 │         0.49 │
└───────────┴────────┴────────────┴──────────────┘
```

Os sete `net_cents` somam os 9.574.389.852 da seção anterior, e a coluna `books` dá o número de
livros vendidos. **As medidas aditivas são as que se guardam**, porque todo outro número que um
relatório queira pode ser construído a partir delas.

## Não aditiva: nunca diretamente

A última coluna, `discount_pct`, é uma razão, e uma razão não se soma. Nem se tira a média, como se
vê:

```sql
-- The discount rate of the whole chain, worked out two ways.
WITH by_shop AS (
    SELECT shop_key, sum(discount_cents) AS discount, sum(gross_cents) AS gross
    FROM fact_sales GROUP BY shop_key
)
SELECT round(100.0 * sum(discount) / sum(gross), 2) AS chain_rate,
       round(avg(100.0 * discount / gross), 2)       AS average_of_shop_rates
FROM by_shop;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < ratio.sql
┌────────────┬───────────────────────┐
│ chain_rate │ average_of_shop_rates │
│   double   │        double         │
├────────────┼───────────────────────┤
│       0.81 │                  0.56 │
└────────────┴───────────────────────┘
```

A rede deu **0,81%** das vendas brutas em descontos. Tire a média das taxas das sete lojas e você
obtém **0,56%**, que é a taxa de loja nenhuma e de rede nenhuma. A média pesa a Moinhos, com seus
26.895 livros, igual ao site com seus 415.722, e o site dá três vezes mais desconto que as lojas.

**A regra: guarde as partes, calcule a razão por último.** `discount_cents` e `gross_cents` são
aditivas. Some cada uma pelo que o relatório agrupa, e divida no fim. Vale o mesmo para um preço médio
(soma do líquido sobre soma da quantidade), uma margem, uma taxa de conversão ou qualquer percentual.
Uma tabela que guarda `discount_pct` por linha guardou um número cuja média todo relatório vai ficar
tentado a tirar.

A terceira resposta, uma medida que soma por algumas dimensões e não por outras, é a próxima seção.
