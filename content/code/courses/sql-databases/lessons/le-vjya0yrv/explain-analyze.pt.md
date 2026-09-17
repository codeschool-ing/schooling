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

Aqui está a varredura da seção anterior, rodada de verdade:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=11 width=28) (actual time=1.779..80.362 rows=13 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999987
 Planning Time: 0.237 ms
 Execution Time: 80.451 ms
(5 rows)
```

## Estimado contra real

Todo nó agora carrega dois grupos entre parênteses. O primeiro é a previsão de antes; o segundo é
a medição:

```
(actual time=1.779..80.362 rows=13 loops=1)
```

**`actual time` está em milissegundos**, dois números com o mesmo significado dos dois custos: o
tempo até a primeira linha sair, e o tempo em que a última saiu. A primeira linha levou quase dois
milissegundos para aparecer porque era essa a distância, tabela adentro, até o primeiro pedido do
cliente 42; a última saiu aos oitenta.

**`rows` é o que o nó de fato devolveu** — treze, contra uma estimativa de onze. É uma boa
estimativa. O que conta como uma ruim é assunto de uma seção própria, e o hábito a construir agora
é pôr os dois `rows` lado a lado em todo nó que você lê.

**`loops` é quantas vezes o nó rodou.** Uma, aqui. Nem sempre é uma, e quando não é, todo outro
número da linha é **por volta** — a seção sobre junções tem um nó que rodou 2984 vezes e relata
três linhas, que são três linhas a cada vez. Multiplique antes de acreditar num número.

Abaixo do nó, `Rows Removed by Filter: 999987` é o custo de uma linha `Filter` tornado visível: o
nó leu um milhão de linhas para ficar com treze. Essa linha sozinha é o argumento inteiro a favor
do índice, e o argumento é feito por medição e não por discussão.

Embaixo, **planning time** e **execution time**. Um quarto de milissegundo para planejar e oitenta
para rodar é o formato usual. Uma consulta que gasta a maior parte do tempo planejando é rara e é
outro problema — em geral uma junção muito larga com muitas ordens possíveis.

## Acrescentando os buffers

```
shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=11 width=28) (actual time=0.925..46.684 rows=13 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999987
   Buffers: shared hit=7466
 Planning:
   Buffers: shared hit=69
 Planning Time: 0.248 ms
 Execution Time: 46.742 ms
(8 rows)
```

`BUFFERS` acrescenta uma linha por nó dizendo quantas páginas de 8 kB ele tocou, e onde.
`shared hit=7466` quer dizer que todas as 7466 páginas da tabela já estavam em memória. Se algumas
tivessem sido lidas do disco, apareceriam como `read=`, e essa é a diferença entre uma consulta
lenta por trabalho e uma lenta por disco. A mesma consulta marcou 80 ms acima e 47 ms aqui, e a
linha de buffers é o que explica: a primeira rodada estava aquecendo o cache que a segunda
acertou.

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
---------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.51..47.38 rows=11 width=28) (actual time=0.023..0.090 rows=13 loops=1)
   Recheck Cond: (customer_id = 42)
   Heap Blocks: exact=13
   Buffers: shared hit=16
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.009..0.009 rows=13 loops=1)
         Index Cond: (customer_id = 42)
         Buffers: shared hit=3
 Planning:
   Buffers: shared hit=119
 Planning Time: 0.383 ms
 Execution Time: 0.145 ms
(11 rows)
```

A mesma consulta, as mesmas treze linhas, e 0,145 ms contra 46,742. O plano tem outra forma — um
bitmap scan, que a próxima seção explica — e a linha de buffers foi de 7466 páginas para
dezesseis. Esse par de números é o que "o índice ajudou" quer dizer quando é dito com precisão:
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
