---
title: Rodando de verdade
version: 1
---

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
```

`EXPLAIN ANALYZE` planeja a consulta, **roda a consulta**, e imprime o plano com o que de fato
aconteceu escrito ao lado do que foi previsto. É a ferramenta que o resto desta aula usa, e a
única palavra de cautela vem primeiro porque é a que custa às pessoas:

> **Ele roda a consulta.** `EXPLAIN ANALYZE DELETE FROM orders` apaga os pedidos. Para qualquer
> coisa que escreva, envolva: `BEGIN; EXPLAIN ANALYZE …; ROLLBACK;`.

Aqui está a varredura da seção anterior, rodada de verdade, num servidor que acabara de ser
reiniciado:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=8.803..54.976 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
 Planning Time: 0.594 ms
 Execution Time: 55.058 ms
(5 rows)
```

## Estimado contra real

Todo nó agora carrega dois grupos entre parênteses. O primeiro é a previsão de antes; o segundo é
a medição:

```
(actual time=8.803..54.976 rows=7 loops=1)
```

**`actual time` está em milissegundos**, dois números com o mesmo significado dos dois custos: o
tempo até a primeira linha sair, e o tempo em que a última saiu. A primeira linha levou quase nove
milissegundos para aparecer porque era essa a distância, tabela adentro, até o primeiro pedido do
cliente 42; a última saiu aos cinquenta e cinco.

**`rows` é o que o nó de fato devolveu** — sete, contra uma estimativa de onze. É uma boa
estimativa. O que conta como uma ruim é assunto de uma seção própria, e o hábito a construir agora
é pôr os dois `rows` lado a lado em todo nó que você lê.

**`loops` é quantas vezes o nó rodou.** Uma, aqui. Nem sempre é uma, e quando não é, todo outro
número da linha é **por volta** — a seção sobre junções tem um nó que rodou 2923 vezes e relata
três linhas, que são três linhas a cada vez. Multiplique antes de acreditar num número.

Abaixo do nó, `Rows Removed by Filter: 999993` é o custo de uma linha `Filter` tornado visível: o
nó leu um milhão de linhas para ficar com sete. Essa linha sozinha é o argumento inteiro a favor
do índice, e o argumento é feito por medição e não por discussão.

Embaixo, **planning time** e **execution time**. Meio milissegundo para planejar e cinquenta e cinco
para rodar é o formato usual. Uma consulta que gasta a maior parte do tempo planejando é rara e é
outro problema — em geral uma junção muito larga com muitas ordens possíveis.

## Acrescentando os buffers

```
shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=11.234..69.728 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
   Buffers: shared hit=32 read=7437
 Planning:
   Buffers: shared hit=103
 Planning Time: 0.455 ms
 Execution Time: 69.807 ms
(8 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=7.137..57.030 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
   Buffers: shared hit=64 read=7405
 Planning:
   Buffers: shared hit=103
 Planning Time: 0.456 ms
 Execution Time: 57.102 ms
(8 rows)
```

`BUFFERS` acrescenta uma linha por nó dizendo quantas páginas de 8 kB ele tocou, e onde.
**`hit` é uma página que já estava na memória do PostgreSQL; `read` é uma que ele teve de pedir ao
sistema operacional**, e essa é a diferença entre uma consulta lenta por trabalho e uma lenta por
disco. A tabela tem 7469 páginas. A primeira rodada acertou 32 e leu 7437, porque o servidor
acabara de subir e a memória dele estava vazia.

A segunda rodada, logo em seguida, ainda leu 7405, e isso é de propósito, não defeito. Uma
varredura sequencial de uma tabela maior que um quarto da memória do PostgreSQL passa por um anel
pequeno de buffers só dela, para que uma varredura grande não empurre para fora as páginas de todas
as outras consultas. As leituras foram rápidas mesmo assim — 70 ms, depois 57 — porque o sistema
operacional mantém um cache próprio do arquivo, e o `BUFFERS` não enxerga dentro dele.

Isso é um fato geral sobre `EXPLAIN ANALYZE` e vale dizer: **rode duas vezes.** A primeira rodada
mede o cache tanto quanto a consulta. Compare segundas rodadas, ou compare `BUFFERS`, e diga qual
das duas você fez.

## Depois do índice

```sql
CREATE INDEX ON orders (customer_id);
```

```
shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.51..47.38 rows=11 width=28) (actual time=0.056..0.109 rows=7 loops=1)
   Recheck Cond: (customer_id = 42)
   Heap Blocks: exact=7
   Buffers: shared hit=1 read=9
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.037..0.037 rows=7 loops=1)
         Index Cond: (customer_id = 42)
         Buffers: shared read=3
 Planning:
   Buffers: shared hit=115 read=4
 Planning Time: 0.463 ms
 Execution Time: 0.233 ms
(11 rows)
```

A mesma consulta, as mesmas sete linhas, e 0,233 ms contra 57,102. O plano tem outra forma — um
bitmap scan, que a próxima seção explica — e a linha de buffers foi de 7469 páginas para
dez. Esse par de números é o que "o índice ajudou" quer dizer quando é dito com precisão:
**não mais rápido, e sim menos páginas lidas**, e o tempo decorre das páginas.

Este é o ciclo que a seção `maintaining-them` da aula passada desenhou: meça, mude, meça de novo.
`EXPLAIN ANALYZE` antes e depois, com `BUFFERS`, é o ciclo inteiro, e uma mudança que não mexe nas
páginas lidas não fez o que você pensou.

## Duas coisas que ele custa

**Tempo.** Medir cada nó acrescenta sobrecarga, e num plano com milhões de execuções de nó o tempo
medido pode ficar visivelmente acima do real. `EXPLAIN (ANALYZE, TIMING OFF)` mantém as contagens
de linhas e dispensa o relógio, e as contagens costumam ser o que você queria.

**A rodada em si.** Um relatório que leva quatro minutos leva quatro minutos sob `EXPLAIN ANALYZE`
também, no servidor de produção, segurando o que a aula 8 disse que uma instrução longa segura.
`EXPLAIN` puro é instantâneo e mostra o plano; recorra ao `ANALYZE` quando o plano parece bom e a
consulta não, porque essa distância é exatamente o que só uma medição fecha.
