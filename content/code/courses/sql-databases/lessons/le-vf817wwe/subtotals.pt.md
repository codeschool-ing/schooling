---
title: Subtotais e total geral numa passada só
version: 1
---

Um relatório quer receita por região por mês, uma linha por região, e um total geral no rodapé. São
três agrupamentos diferentes das mesmas linhas, e o jeito óbvio de obtê-los são três consultas
grampeadas:

```sql
SELECT region, month, sum(total) FROM sales GROUP BY region, month
UNION ALL
SELECT region, NULL,  sum(total) FROM sales GROUP BY region
UNION ALL
SELECT NULL,   NULL,  sum(total) FROM sales;
```

Funciona. Também lê a tabela três vezes, e todo filtro precisa ser escrito três vezes e continuar
igual pelo tempo que o relatório existir. Esqueça um e os subtotais deixam de fechar com o detalhe,
que é o tipo de defeito sobre o qual as pessoas discutem em reunião.

## `GROUPING SETS`

A mesma coisa, uma vez:

```sql
SELECT   region, month, sum(total)
FROM     sales
GROUP BY GROUPING SETS ((region, month), (region), ());
```

Cada lista entre parênteses é um agrupamento a calcular, e `()` — o conjunto vazio — é o total
geral, a tabela inteira como um grupo só. Uma varredura, uma cláusula `WHERE`, um lugar para mudar.

## `ROLLUP` e `CUBE`, que são atalhos

`ROLLUP` dá uma hierarquia: o agrupamento completo, depois progressivamente menos colunas a partir
da direita, depois o total.

```sql
GROUP BY ROLLUP (region, month)
-- o mesmo que GROUPING SETS ((region, month), (region), ())
```

É o formato que quase todo relatório financeiro quer, porque corresponde a como eles são lidos:
detalhe sob um título, títulos sobre uma linha de fechamento. A ordem das colunas importa —
`ROLLUP (month, region)` subtotaliza por mês.

`CUBE` dá **todas** as combinações:

```sql
GROUP BY CUBE (region, month)
-- (region, month), (region), (month), ()
```

Quatro agrupamentos a partir de duas colunas; três colunas dão oito. Responde "fatie isso de
qualquer jeito" numa consulta, e o número de linhas cresce rápido o bastante para valer saber que
você pediu.

MySQL e MariaDB têm só a hierarquia, com a grafia deles — `GROUP BY region, month WITH ROLLUP` — e
nada de `GROUPING SETS` ou `CUBE`. O SQLite não tem nenhum dos três, então lá o `UNION ALL` acima é
a resposta.

## A ambiguidade, que é a parte que morde

Uma linha de subtotal tem `NULL` nas colunas que ela agregou. Um grupo de verdade cuja região é
genuinamente desconhecida também tem. Na saída são o mesmo caractere:

```
region   month     sum
south    2026-03   1400
south    NULL      3900      <- subtotal do sul
NULL     2026-03    260      <- vendas de região desconhecida
NULL     NULL      9100      <- total geral
```

A linha dois e a linha quatro dizem `NULL` para região e querem dizer coisas completamente
diferentes. Uma pessoa lendo a tabela não tem como saber, e o programa que a desenha também não.

`GROUPING()` é a resposta: devolve `1` quando a coluna foi agregada naquela linha e `0` quando o
nulo é do próprio dado.

```sql
SELECT   CASE WHEN GROUPING(region) = 1 THEN 'todas as regiões' ELSE coalesce(region, 'desconhecida') END
           AS region,
         CASE WHEN GROUPING(month)  = 1 THEN 'todos os meses'   ELSE to_char(month, 'YYYY-MM') END
           AS month,
         sum(total)
FROM     sales
GROUP BY ROLLUP (region, month);
```

Agora toda linha diz o que é. **Use `GROUPING()` sempre que a coluna agregada for anulável** — e se
você tem certeza de que ela não é anulável hoje, lembre que `NOT NULL` é uma promessa que alguém
pode largar numa migração, e o relatório continuaria desenhando.

## Pôr as linhas nos lugares certos

A ordem da saída é indefinida, como sempre, e subtotais espalhados pelo meio do detalhe são piores
do que subtotal nenhum. Ordene primeiro pelos indicadores de agrupamento, para que cada subtotal
caia embaixo das linhas que ele resume:

```sql
ORDER BY GROUPING(region), region, GROUPING(month), month
```

`GROUPING(region)` é `0` para todo detalhe e toda linha de região e `1` só para o total geral, o que
põe o total por último. Dentro de uma região, `GROUPING(month)` é `0` para os meses e `1` para o
subtotal daquela região, o que o põe embaixo deles. Lê de um jeito estranho e é exatamente a ordem
que um leitor espera.
