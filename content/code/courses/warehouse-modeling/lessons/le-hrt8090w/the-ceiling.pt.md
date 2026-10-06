---
title: O teto de uma máquina
version: 1
---

Núcleos são um limite. Memória é o outro, e ela morde de outro jeito: uma consulta com poucos
processadores roda mais devagar, enquanto uma consulta com pouca memória ou desacelera muito ou para.

O teste: um agrupamento com um grupo para cada linha das vinte cópias, 17,7 milhões de grupos, que
precisa guardar um total parcial para cada um deles em algum lugar. Feito com a memória da máquina,
depois com 200 MB, depois com 20 MB:

```sql
-- A grouping with 17.7 million groups, given less and less memory.
.timer on
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
SET memory_limit = '200MB';
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
SET memory_limit = '20MB';
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
```

```
ana@lab:~/wh$ duckdb -list wh.duckdb < memory.sql 2>&1 | grep -E 'Run Time|Error|^[0-9]'
17749540
Run Time (s): real 0.340 user 1.168995 sys 0.160492
Run Time (s): real 0.016 user 0.001318 sys 0.015076
17749540
Run Time (s): real 0.466 user 1.570202 sys 0.216842
Run Time (s): real 0.014 user 0.001582 sys 0.012248
Out of Memory Error: failed to allocate data of size 8.0 MiB (12.5 MiB/19.0 MiB used)
Run Time (s): real 0.310 user 0.952283 sys 0.115430
```

- **Com a memória da máquina**, 0,340 segundo.
- **Com 200 MB**, 0,466 segundo. Ainda terminou, mais devagar. O DuckDB é feito para levar partes de uma
  operação grande para arquivos temporários no disco quando a memória aperta, e trazê-las de volta
  conforme precisa.
- **Com 20 MB**, parou: `Out of Memory Error`. Não havia memória nem para os pedaços com que ele trabalha.

Essa é a forma do teto de qualquer máquina sozinha. Abaixo de certa quantidade de memória por consulta,
o trabalho vai para o disco e fica lento; abaixo de uma quantidade menor, falha. Mais memória move as
duas linhas, e dá para comprar uma máquina com muita memória, mas **a maior máquina que se pode comprar
é um número fixo**, e o mesmo vale para o disco em que ela grava e a placa de rede pela qual lê.

Os outros limites de uma máquina são menos sobre velocidade:

- **Ela é um ponto único de falha.** Quando está fora, o warehouse está fora.
- **Ela tem um tamanho só.** Uma máquina grande o bastante para a hora mais cheia do mês fica ociosa o
  resto do tempo, e você paga por ela o mês inteiro.

A escala horizontal responde aos três, e a seção 06 começa pelo que ela custa.
