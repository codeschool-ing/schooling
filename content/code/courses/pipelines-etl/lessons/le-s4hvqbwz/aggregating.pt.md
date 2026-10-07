---
title: Agregar num grão, e montar tudo
version: 1
---

Um mart responde a uma pergunta num **grão**: o nível de detalhe que uma linha descreve. O primeiro
mart da Ana é uma linha por dia, loja e categoria, com livros e receita:

```
-- Books and revenue by day, shop and category: one row per combination that
-- sold anything. Built from the line grain and nothing coarser, so that no
-- join can repeat a line.
DROP TABLE IF EXISTS marts.daily_sales;
CREATE TABLE marts.daily_sales AS
SELECT o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer    AS books,
       sum(l.line_cents)::bigint   AS revenue_cents
  FROM staging.order_lines l
  JOIN staging.orders o USING (order_id)
  JOIN staging.books  b USING (book_id)
 WHERE o.is_sale
 GROUP BY 1, 2, 3;
```

Duas coisas nele são de propósito. Ele lê só o `staging`, nunca o `raw`. E soma colunas que moram no
grão da tabela de onde parte — `quantity` e `line_cents` estão na linha, e os joins vão da linha *para
cima*, até o seu pedido e o seu livro, cada um dos quais casa com exatamente uma linha. **Um join que
sobe uma hierarquia não faz fan-out**; um que desce, de um pedido para as suas linhas, pode fazer.

## Montando cada tabela, em ordem

Cada arquivo SQL monta uma tabela, e os arquivos precisam rodar numa ordem: staging antes de marts,
e dentro de cada camada, o schema antes das tabelas. O executor da Ana faz a coisa mais simples que
funciona:

```
#!/bin/sh
# Build staging, then marts, one file at a time, in the order of their names.
# Stops at the first file that fails, and says which.
set -e
export PGOPTIONS="-c client_min_messages=warning"   # no NOTICE for each DROP IF EXISTS

for f in sql/staging/*.sql sql/marts/*.sql; do
  psql -q -v ON_ERROR_STOP=1 -d wh -f "$f"
  echo "built $f"
done
```

```
ana@vm:~/etl$ sh run_sql.sh
built sql/staging/00_schema.sql
built sql/staging/books.sql
built sql/staging/events.sql
built sql/staging/order_lines.sql
built sql/staging/orders.sql
built sql/staging/prices.sql
built sql/marts/00_schema.sql
built sql/marts/daily_sales.sql
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM marts.daily_sales WHERE order_date >= '2026-03-01' GROUP BY 1 ORDER BY 1"
 order_date | books | revenue_cents 
------------+-------+---------------
 2026-03-01 |   299 |       1979210
 2026-03-02 |   442 |       3033980
 2026-03-03 |   507 |       3355580
 2026-03-04 |   478 |       3081620
 2026-03-05 |   501 |       3363790
 2026-03-06 |   469 |       3148810
 2026-03-07 |   582 |       3978230
(7 rows)
```

**A ordem vem dos nomes dos arquivos**, e é por isso que os arquivos de schema se chamam
`00_schema.sql`: os zeros os põem primeiro. Funciona, e é frágil exatamente do jeito que o curso
proíbe no seu próprio conteúdo. A ordem de execução é deduzida do sistema de arquivos, então
renomear um arquivo pode quebrar a montagem, e nada registra que `daily_sales` precisa que `orders`
exista antes. A lição 11 troca este script pelo dbt, que deduz a ordem a partir do próprio SQL.

Os totais por dia do mart da primeira semana são o segundo comando acima.

O domingo, dia 1º, é o dia mais calmo da semana, como todo domingo nos dados, e o sábado, dia 7, é o
mais movimentado.
