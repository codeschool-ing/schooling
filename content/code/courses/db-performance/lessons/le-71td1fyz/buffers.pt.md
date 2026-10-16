---
title: O BUFFERS, e de onde vieram as páginas
version: 1
---

A aula 1 cronometrou uma contagem três vezes e obteve 435, 167 e 208 milissegundos: a primeira
execução foi **fria**, com as páginas no disco, e as outras foram **quentes**. Um tempo sozinho não
diz que tipo de execução você está olhando. O `BUFFERS` diz, nó a nó, porque conta as páginas de 8
kB em que cada nó tocou e diz onde cada uma foi encontrada.

## Duas palavras, e a leitura errada de uma delas

**`shared hit` é uma página que já estava na memória do próprio PostgreSQL**, os 128 MB de shared
buffers que a aula 1 olhou. **`shared read` é uma página que não estava, e teve de ser pedida ao
sistema operacional.** A leitura tentadora de `read` é "veio do disco", e ela erra com frequência
suficiente para importar: o sistema operacional mantém o próprio cache dos arquivos, bem maior que
os shared buffers na maioria das máquinas, e um `read` que ele atende dali custa microssegundos.
Para separar os dois você precisa de um tempo por leitura, e um ajuste dá isso.

## Fria, depois quente

Reinicie o servidor e descarte o cache do sistema operacional, como a aula 1 fez, para que nada
esteja na memória. Depois ligue o `track_io_timing` na sessão — ele faz cada leitura informar
quanto demorou — e rode o painel do vendedor duas vezes:

```
ana@vm:~$ sudo systemctl restart postgresql
ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
ana@vm:~$ psql market
market=# SET track_io_timing = on;
SET
Time: 2.617 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2287.58..2289.36 rows=79 width=24) (actual time=17.731..17.763 rows=25 loops=1)
   Group Key: (date_trunc('day'::text, placed_at))
   Buffers: shared hit=3 read=380
   I/O Timings: shared read=7.239
   ->  Sort  (cost=2287.58..2287.78 rows=79 width=12) (actual time=17.717..17.726 rows=81 loops=1)
         Sort Key: (date_trunc('day'::text, placed_at))
         Sort Method: quicksort  Memory: 28kB
         Buffers: shared hit=3 read=380
         I/O Timings: shared read=7.239
         ->  Bitmap Heap Scan on orders  (cost=1984.02..2285.09 rows=79 width=12) (actual time=11.561..17.598 rows=81 loops=1)
               Recheck Cond: ((seller_id = 42) AND (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone))
               Heap Blocks: exact=78
               Buffers: shared read=380
               I/O Timings: shared read=7.239
               ->  BitmapAnd  (cost=1984.02..1984.02 rows=79 width=0) (actual time=11.319..11.322 rows=0 loops=1)
                     Buffers: shared read=302
                     I/O Timings: shared read=4.228
                     ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0) (actual time=0.537..0.538 rows=1532 loops=1)
                           Index Cond: (seller_id = 42)
                           Buffers: shared read=4
                           I/O Timings: shared read=0.271
                     ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..1964.12 rows=106093 width=0) (actual time=10.599..10.599 rows=107780 loops=1)
                           Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
                           Buffers: shared read=298
                           I/O Timings: shared read=3.957
 Planning:
   Buffers: shared hit=113 read=29
   I/O Timings: shared read=2.098
 Planning Time: 4.239 ms
 Execution Time: 18.226 ms
(30 rows)

Time: 30.987 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;
                                                                         QUERY PLAN                                                                         
------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2287.58..2289.36 rows=79 width=24) (actual time=3.911..3.927 rows=25 loops=1)
   Group Key: (date_trunc('day'::text, placed_at))
   Buffers: shared hit=380
   ->  Sort  (cost=2287.58..2287.78 rows=79 width=12) (actual time=3.896..3.901 rows=81 loops=1)
         Sort Key: (date_trunc('day'::text, placed_at))
         Sort Method: quicksort  Memory: 28kB
         Buffers: shared hit=380
         ->  Bitmap Heap Scan on orders  (cost=1984.02..2285.09 rows=79 width=12) (actual time=3.773..3.879 rows=81 loops=1)
               Recheck Cond: ((seller_id = 42) AND (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone))
               Heap Blocks: exact=78
               Buffers: shared hit=380
               ->  BitmapAnd  (cost=1984.02..1984.02 rows=79 width=0) (actual time=3.745..3.747 rows=0 loops=1)
                     Buffers: shared hit=302
                     ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0) (actual time=0.237..0.238 rows=1532 loops=1)
                           Index Cond: (seller_id = 42)
                           Buffers: shared hit=4
                     ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..1964.12 rows=106093 width=0) (actual time=3.450..3.450 rows=107780 loops=1)
                           Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
                           Buffers: shared hit=298
 Planning Time: 0.193 ms
 Execution Time: 4.028 ms
(21 rows)

Time: 4.777 ms
```

**A execução fria leu 380 páginas e achou 3.** `I/O Timings: shared read=7.239` diz que essas
leituras levaram 7 dos 18 milissegundos que a consulta levou para rodar. **A quente achou todas as
380** — `shared hit=380`, nenhuma linha `read`, nenhum tempo de E/S — e terminou em 4
milissegundos. O mesmo plano, as mesmas linhas, as mesmas páginas; só mudou onde as páginas
estavam.

Olhe também as linhas de planejamento. A execução fria tem um bloco `Planning:` com buffers
próprios, 29 deles lidos, e `Planning Time: 4.239 ms` contra 0,193 na segunda vez. Escolher um plano
é ler o catálogo — que tabelas existem, que índices, o que as estatísticas dizem — e logo depois de
um reinício até isso vem do disco. **A primeira consulta num servidor recém-iniciado paga para
planejar, além de para executar.**

## Os buffers se somam árvore acima

Como os custos e os tempos, **os buffers de um nó incluem os dos filhos**. O `BitmapAnd` tem 302: 4
do índice em `seller_id` e 298 do índice em `placed_at`. O `Bitmap Heap Scan` acima dele tem 380:
esses 302 mais as 78 páginas da tabela que ele visitou, que é o `Heap Blocks: exact=78` da linha
dele. As 298 páginas de entradas de índice de dezembro, de novo, são a maior parte do trabalho — o
mesmo nó que a seção anterior achou subtraindo custos, achado agora contando páginas.

**Uma contagem de páginas não depende do cache.** As execuções fria e quente levaram 18 e 4
milissegundos e tocaram 380 páginas cada uma. Quando você compara duas versões de uma consulta, as
páginas são a medida que não se mexe com o que rodou antes, e o tempo é a que se mexe. A aula 24
volta a isso.

## Uma varredura grande não fica na memória

Agora a contagem dos pendentes, duas vezes, na mesma sessão:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE status = 'pending';
                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=347.324..351.596 rows=1 loops=1)
   Buffers: shared hit=78 read=16589
   I/O Timings: shared read=876.128
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=347.165..351.589 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=78 read=16589
         I/O Timings: shared read=876.128
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=343.237..343.238 rows=1 loops=3)
               Buffers: shared hit=78 read=16589
               I/O Timings: shared read=876.128
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=342.754..343.118 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
                     Buffers: shared hit=78 read=16589
                     I/O Timings: shared read=876.128
 Planning:
   Buffers: shared hit=11
 Planning Time: 0.142 ms
 Execution Time: 351.639 ms
(20 rows)

Time: 352.488 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE status = 'pending';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=56.371..60.058 rows=1 loops=1)
   Buffers: shared hit=174 read=16493
   I/O Timings: shared read=43.577
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=56.222..60.051 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=174 read=16493
         I/O Timings: shared read=43.577
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=53.744..53.746 rows=1 loops=3)
               Buffers: shared hit=174 read=16493
               I/O Timings: shared read=43.577
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=53.317..53.613 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
                     Buffers: shared hit=174 read=16493
                     I/O Timings: shared read=43.577
 Planning Time: 0.111 ms
 Execution Time: 60.139 ms
(18 rows)

Time: 60.883 ms
```

A primeira execução leu 16589 páginas, a `orders` inteira, e a E/S dela levou 876 milissegundos.
Isso é mais que os 352 que a consulta levou, porque três processos liam ao mesmo tempo e os tempos
de E/S deles são somados.

A segunda execução é a surpresa. **Ela leu de novo 16493 páginas** — só 174 foram hits —, enquanto a
segunda execução do painel achou todas as páginas dela. A tabela tem uns 130 MB, um pouco mais que
todos os shared buffers, mas não é por isso: o PostgreSQL nem tentou guardá-la. Uma varredura
sequencial de uma tabela maior que um quarto dos shared buffers passa por um pequeno anel de buffers
próprio, de 256 kB, e o reaproveita enquanto avança. Uma varredura grande não consegue empurrar para
fora da memória as páginas de todas as outras consultas, e o preço é que as páginas dela própria não
ficam.

E mesmo assim a segunda execução levou 60 milissegundos em vez de 352. A linha de E/S explica:
**as mesmas 16493 leituras levaram 44 milissegundos em vez de 876**, porque desta vez o sistema
operacional tinha o arquivo no cache. Um `read` com tempo de E/S pequeno é a memória do sistema
operacional; um `read` com tempo grande é o disco. Sem o `track_io_timing`, as duas execuções
mostrariam as mesmas contagens de buffers e tempos muito diferentes, sem nada na tela dizendo por
quê.

## Ligando para valer

`SET track_io_timing = on` dura até o `psql` fechar, e só um superusuário pode ajustá-lo, o que a
`ana` é. Ele consulta o relógio duas vezes a cada página lida, o que na maioria das máquinas custa
pouco demais para medir. Ajustado na configuração do servidor, ele também dá ao
`pg_stat_statements` o tempo que as leituras levaram, ao lado das contagens que a aula 2 leu. Para
ler planos, digitá-lo no começo da sessão basta.

O hábito para sair desta seção: **`EXPLAIN (ANALYZE, BUFFERS)`, nunca o `ANALYZE` sozinho.** O
tempo diz quanto demorou; os buffers dizem quanto trabalho e de onde, e só o segundo explica o
primeiro.
