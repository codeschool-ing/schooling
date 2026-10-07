---
title: Refazer tudo, ou a parte que mudou
version: 1
---

A lição 11 tornou o `fact_sales` incremental e a lição 15 deu a ele uma janela de trinta dias, as duas
com o argumento de que refazer a tabela inteira toda noite é desperdício. Na tabela grande o argumento
pode ser medido. Cada abordagem roda numa transação que depois é desfeita, para que as duas comecem da
mesma tabela:

```
-- Two ways to bring the table up to date, each inside a transaction that is
-- rolled back, so that both start from the same table.
\timing on
BEGIN;
-- 1. rebuild it whole
CREATE TABLE big.fact_sales_new AS SELECT * FROM big.fact_sales;
ROLLBACK;
BEGIN;
-- 2. replace the last thirty days
DELETE FROM big.fact_sales WHERE order_date >= DATE '2026-03-21' - 30;
INSERT INTO big.fact_sales SELECT * FROM dbt_marts.fact_sales WHERE order_date >= DATE '2026-03-21' - 30;
ROLLBACK;
```

```
ana@vm:~/etl$ psql -q -d wh -f rebuild.sql
Time: 0.150 ms
Time: 2240.156 ms (00:02.240)
Time: 26.844 ms
Time: 0.089 ms
Time: 7.712 ms
Time: 21.896 ms
Time: 0.225 ms
```

Os tempos estão na ordem em que os comandos rodaram. Copiar a tabela inteira: **cerca de dois
segundos e um quarto**. Apagar os últimos trinta dias, achados pelo índice, e inseri-los de novo:
**cerca de trinta milissegundos** somando os dois comandos. Cerca de setenta e cinco vezes menos, e a distância
cresce a cada ano de histórico, porque refazer tudo cresce com a tabela e a janela não.

Esse é o argumento a favor das cargas incrementais, e ele vem com o preço que as lições 11 e 15
pagaram. Uma janela só acerta o que cai dentro dela, então precisa do teste de deriva para dizer
quando não bastou, e de uma reconstrução completa de vez em quando para acertar o que ela deixou
passar. Numa tabela deste tamanho, uma reconstrução completa por semana é viável; numa mil vezes maior,
é uma decisão sobre dinheiro tanto quanto sobre tempo.
