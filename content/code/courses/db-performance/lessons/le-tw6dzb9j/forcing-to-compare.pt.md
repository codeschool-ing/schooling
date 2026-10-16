---
title: Forçando o outro plano, só para comparar
version: 1
---

Quando um plano parece errado, a primeira pergunta é quanto teria custado a alternativa, e o
planejador não mostra um plano que rejeitou. Uma família de ajustes faz isso: `enable_seqscan`,
`enable_indexscan`, `enable_bitmapscan` e os parentes deles para junções e ordenações. Desligado
numa sessão, cada um tira um caminho de acesso do alcance do planejador, e o próximo `EXPLAIN
ANALYZE` mostra o plano que ele escolheria sem esse caminho, executado de verdade.

**Eles são um jeito de fazer uma pergunta, e nunca um jeito de consertar uma consulta.** Essa frase
é a seção, e o resto é o porquê.

## A varredura sequencial do ano estava certa?

Todo tempo abaixo é a **segunda** execução do comando: rode cada `EXPLAIN ANALYZE` uma vez, depois
de novo, e leia a segunda, para que os dois planos sejam comparados quentes, como a aula 1 pediu.
Primeiro o plano que o planejador escolheu, depois o que ele escolheria com as varreduras
sequenciais desligadas:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';
                                                                              QUERY PLAN                                                                              
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=31313.85..31313.86 rows=1 width=8) (actual time=104.753..112.030 rows=1 loops=1)
   Buffers: shared hit=16047 read=620
   ->  Gather  (cost=31313.64..31313.85 rows=2 width=8) (actual time=104.603..112.021 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=16047 read=620
         ->  Partial Aggregate  (cost=30313.64..30313.65 rows=1 width=8) (actual time=101.872..101.873 rows=1 loops=3)
               Buffers: shared hit=16047 read=620
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=458656 width=4) (actual time=26.884..75.046 rows=369911 loops=3)
                     Filter: ((placed_at >= '2025-01-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2026-01-01 00:00:00-03'::timestamp with time zone))
                     Rows Removed by Filter: 296756
                     Buffers: shared hit=16047 read=620
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.173 ms
 Execution Time: 112.076 ms
(16 rows)

Time: 113.576 ms

market=# SET enable_seqscan = off;
SET
Time: 0.382 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';
                                                                                QUERY PLAN                                                                                
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=38998.59..38998.60 rows=1 width=8) (actual time=137.685..145.103 rows=1 loops=1)
   Buffers: shared hit=14932
   ->  Gather  (cost=38998.38..38998.59 rows=2 width=8) (actual time=137.575..145.094 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=14932
         ->  Partial Aggregate  (cost=37998.38..37998.39 rows=1 width=8) (actual time=133.773..133.775 rows=1 loops=3)
               Buffers: shared hit=14932
               ->  Parallel Index Scan using orders_placed_at_idx on orders  (cost=0.43..36851.74 rows=458656 width=4) (actual time=0.040..91.669 rows=369911 loops=3)
                     Index Cond: ((placed_at >= '2025-01-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2026-01-01 00:00:00-03'::timestamp with time zone))
                     Buffers: shared hit=14932
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.124 ms
 Execution Time: 145.142 ms
(15 rows)

Time: 145.687 ms
```

**112 milissegundos para a varredura sequencial, 145 para a varredura de índice que o planejador
recusou.** Os custos dele diziam a mesma coisa na unidade dele, `31313.86` contra `38998.60`. A
varredura de índice tocou menos páginas, 14932 contra todas as 16667, e ainda assim foi mais lenta:
seguir mais de um milhão de entradas de índice uma por vez é mais trabalho do que ler páginas em
ordem, mesmo quando as páginas são menos. O planejador acertou, e agora você sabe por quanto.

## A varredura bitmap estava certa?

Vinte mil clientes, com os planos paralelos desligados: a varredura bitmap que o planejador
escolheu, depois a mesma consulta com as varreduras bitmap desligadas:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.524 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=23250.24..23250.25 rows=1 width=8) (actual time=103.550..103.551 rows=1 loops=1)
   Buffers: shared hit=6845 read=10051
   ->  Bitmap Heap Scan on orders  (cost=3017.14..22740.80 rows=203777 width=4) (actual time=11.918..89.257 rows=200378 loops=1)
         Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
         Heap Blocks: exact=16667
         Buffers: shared hit=6845 read=10051
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0) (actual time=9.392..9.393 rows=200378 loops=1)
               Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
               Buffers: shared hit=3 read=226
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.118 ms
 Execution Time: 103.826 ms
(13 rows)

Time: 104.341 ms

market=# SET enable_bitmapscan = off;
SET
Time: 0.156 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47176.44..47176.45 rows=1 width=8) (actual time=161.253..161.254 rows=1 loops=1)
   Buffers: shared hit=16232 read=435
   ->  Seq Scan on orders  (cost=0.00..46667.00 rows=203777 width=4) (actual time=0.011..145.831 rows=200378 loops=1)
         Filter: ((customer_id >= 1) AND (customer_id <= 20000))
         Rows Removed by Filter: 1799622
         Buffers: shared hit=16232 read=435
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.113 ms
 Execution Time: 161.282 ms
(10 rows)

Time: 161.877 ms
```

Sem bitmap disponível, o planejador não recuou para uma varredura de índice; foi para uma varredura
sequencial, a segunda mais barata para ele, e ela levou **161 milissegundos contra 104 do bitmap**.
Acertou de novo. Note o que a comparação rendeu: você soube não só que o bitmap era mais rápido, mas
qual era o segundo colocado, uma informação que nenhuma quantidade de olhar para o primeiro plano
dá.

## É uma penalidade, não uma proibição

Desligar um caminho não o remove. Soma um número enorme ao custo dele, para que qualquer outra coisa
ganhe. Quando nada mais é possível, o caminho penalizado é escolhido mesmo assim:

```
market=# SET enable_seqscan = off;
SET
Time: 0.369 ms

market=# EXPLAIN SELECT * FROM products WHERE title LIKE '%lamp%';
                                   QUERY PLAN                                   
--------------------------------------------------------------------------------
 Seq Scan on products  (cost=10000000000.00..10000001274.00 rows=5051 width=73)
   Filter: (title ~~ '%lamp%'::text)
 JIT:
   Functions: 2
   Options: Inlining true, Optimization true, Expressions true, Deforming true
(5 rows)

Time: 4416.122 ms (00:04.416)
```

Não há índice capaz de responder a `LIKE '%lamp%'`, então uma varredura sequencial é o único jeito
de rodá-la, e o planejador a escolheu com `10000000000.00` somado ao custo. Esse número é a
penalidade, impressa. As linhas `JIT` são um efeito colateral que vale ver: o planejador agora
acredita que esta é uma consulta enorme e planejou compilá-la para código de máquina, um passo
pensado para consultas que rodam por segundos, numa varredura de uma tabela de 5 MB. **Um plano com
custo na casa dos bilhões é um plano rodando sob um ajuste desligado**, e reconhecer um na sessão de
um colega é reconhecer um `SET` esquecido.

## Por que nunca é o conserto

A tentação chega no dia em que uma consulta está lenta e `SET enable_seqscan = off` a deixa rápida.
Pôr isso na aplicação, ou pior, na configuração do servidor, dá errado de três jeitos:

- **Vale para tudo.** O ajuste não sabe de que consulta você estava falando. Todo outro comando
  naquela conexão perde as varreduras sequenciais também, inclusive aqueles para os quais uma
  varredura sequencial era a certa — o ano acima, e toda consulta que lê a maior parte de uma tabela.
- **Esconde o motivo.** O planejador escolheu mal porque uma das entradas dele estava errada: uma
  estimativa, um preço, um índice que falta. O ajuste deixa a entrada errada no lugar, então a
  próxima consulta que depende dela dá errado de um jeito que ninguém liga a esta.
- **Não continua verdadeiro.** Os dados crescem, a distribuição muda, e o plano que o ajuste força
  vira o lento, sem nada no raciocínio do próprio plano capaz de corrigi-lo.

Então o ajuste responde a uma pergunta — "quanto custaria o outro plano?" — e a resposta aponta o
que consertar. Se o plano forçado for muito mais rápido, compare as estimativas dele com as do plano
escolhido: a aula 6 trata da estimativa de linhas que estava errada, e a aula 7 das estatísticas por
trás dela. Se o plano forçado for mais lento, como os dois foram aqui, o planejador acertou e a
consulta precisa de outro índice ou de outra pergunta, que são as aulas 8 a 10.

Feche o `psql` quando terminar, ou dê `RESET` em cada ajuste que mudou. Nada nesta aula mudou uma
linha ou a configuração do servidor, então não há mais nada a desfazer.
