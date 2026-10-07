---
title: Acrescentar, e por que não basta
version: 1
---

A carga mais simples acrescenta linhas e não toca em mais nada: `INSERT INTO destino SELECT ...`. É
o formato certo para dados que **só crescem** — eventos, linhas de log, vendas — e é a carga mais
rápida que existe, porque o banco escreve páginas novas e nunca precisa achar uma linha antiga.

A fraqueza dela é tudo o que essas últimas palavras deixam de fora. Para mostrar, a Ana faz uma cópia
só de inserção da tabela fato e carrega o dia 2 de março nela — e depois, como faria um agendador
repetindo uma execução que achou ter falhado, carrega de novo:

```
ana@vm:~/etl$ psql -d wh -c "CREATE TABLE marts.sales_log AS SELECT * FROM marts.fact_sales WHERE false"
SELECT 0
ana@vm:~/etl$ psql -d wh -c "INSERT INTO marts.sales_log SELECT * FROM marts.fact_sales WHERE order_date = '2026-03-02'"
INSERT 0 415
ana@vm:~/etl$ psql -d wh -c "INSERT INTO marts.sales_log SELECT * FROM marts.fact_sales WHERE order_date = '2026-03-02'"
INSERT 0 415
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*), count(DISTINCT (order_id, line_no)) AS distinct_lines FROM marts.sales_log GROUP BY 1"
 order_date | count | distinct_lines 
------------+-------+----------------
 2026-03-02 |   830 |            415
(1 row)
```

**830 linhas descrevendo 415 linhas de pedido.** Cada linha do dia 2 de março agora está na tabela
duas vezes, e todo total montado sobre ela está dobrado, como o primeiro batch da lição 1.

Uma carga por acréscimo só é segura quando uma de duas coisas é verdade:

- a entrada nunca se repete — cada execução lê linhas que nenhuma anterior leu, e nenhuma execução
  é repetida. A marca d'água da lição 4 é como um pipeline tenta prometer a primeira metade; nada pode
  prometer a segunda, porque uma execução que falhou vai ser rodada de novo;
- o destino sabe distinguir uma repetição de uma linha nova — uma chave, e uma carga que recusa ou
  ignora uma linha que já tem.

A segunda é a que se sustenta, e é o que são as outras três cargas desta lição: cada uma sabe quais
linhas está substituindo.
