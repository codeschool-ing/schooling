---
title: O shared_buffers e o cache debaixo dele
version: 1
---

**O `shared_buffers` é o cache próprio do PostgreSQL para páginas de tabelas e índices**, e toda
leitura e escrita passa por ele: uma consulta que precisa de uma página procura ali primeiro, e só
numa falta pede ao sistema operacional os 8 kB do arquivo. A crença comum é que esse cache deve
ser tão grande quanto a máquina permite, como costuma ser com caches. Não deve, porque ele não é o
único: **o sistema operacional guarda a sua própria cópia dos blocos de arquivo lidos há pouco**
no cache de páginas, a coluna `buff/cache` do `free`. Uma página que o PostgreSQL pede muitas
vezes já está lá, e memória dada a um dos dois caches sai do outro.

Por isso o ponto de partida habitual é **um quarto da memória da máquina**. A documentação do
PostgreSQL sugere 25% num servidor dedicado e diz que mais de 40% dificilmente supera um valor
menor. O resto vai para a memória privada dos processos e para o cache de páginas, que passa a
guardar a maior parte do que o `shared_buffers` não guarda.

## O que o cache guarda

O `pg_buffercache` é uma extensão que vem com o servidor e mostra o cache por dentro. Reinicie
antes, para o cache começar vazio, e depois leia a `orders` inteira:

```
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql shop
shop=# CREATE EXTENSION pg_buffercache;
CREATE EXTENSION

shop=# SELECT buffers_used, buffers_unused FROM pg_buffercache_summary();
 buffers_used | buffers_unused 
--------------+----------------
          257 |          16127
(1 row)

shop=# SELECT pg_size_pretty(pg_relation_size('orders')) AS size,
shop-#        pg_relation_size('orders') / 8192 AS pages;
 size  | pages 
-------+-------
 65 MB |  8334
(1 row)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=102.672..106.803 rows=1 loops=1)
   Buffers: shared read=8334
   ->  Gather (actual time=102.657..106.791 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared read=8334
         ->  Partial Aggregate (actual time=89.550..89.552 rows=1 loops=3)
               Buffers: shared read=8334
               ->  Parallel Seq Scan on orders (actual time=0.019..55.617 rows=333333 loops=3)
                     Buffers: shared read=8334
 Planning:
   Buffers: shared hit=69 read=19 dirtied=2
 Planning Time: 0.619 ms
 Execution Time: 106.895 ms
(14 rows)

shop=# SELECT c.relname, count(*) AS buffers
shop-#   FROM pg_buffercache b
shop-#   JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
shop-#  WHERE b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())
shop-#  GROUP BY c.relname ORDER BY buffers DESC LIMIT 3;
   relname    | buffers 
--------------+---------
 orders       |      96
 pg_attribute |      31
 pg_proc      |      16
(3 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=112.746..114.307 rows=1 loops=1)
   Buffers: shared hit=96 read=8238
   ->  Gather (actual time=112.737..114.299 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=96 read=8238
         ->  Partial Aggregate (actual time=95.500..95.502 rows=1 loops=3)
               Buffers: shared hit=96 read=8238
               ->  Parallel Seq Scan on orders (actual time=0.031..62.150 rows=333333 loops=3)
                     Buffers: shared hit=96 read=8238
 Planning Time: 0.096 ms
 Execution Time: 114.343 ms
(12 rows)

shop=# \q
```

O cache tem 16384 buffers, um por página de 8 kB, e o restart deixou todos livres menos algumas
centenas. A `orders` tem 8334 páginas. O `BUFFERS` acrescenta uma linha a cada passo do plano:
**`hit` é uma página encontrada no `shared_buffers`, `read` é uma que precisou ser pedida**. Ler
EXPLAIN direito é a lição 3 de db-performance; aqui só essa linha importa. A primeira contagem
leu as 8334.

Aí vem a surpresa. A tabela tem 65 MB e o cache 128 MB, então a tabela inteira deveria estar nele
agora, e **só 96 das páginas dela estão**. A segunda contagem achou essas 96 e leu as outras 8238
de novo. Isso é de propósito: uma varredura sequencial de uma tabela maior que um quarto do
`shared_buffers` recebe um pequeno anel de 32 buffers em vez do cache inteiro, para que uma
varredura grande não expulse as páginas de todas as outras tabelas. Três processos varreram em
paralelo, os `Workers Launched: 2` mais o que os iniciou, e 3 anéis de 32 são as 96.

As páginas `read` também não foram lentas: as duas contagens levaram uma fração de segundo,
porque **toda página estava no cache de páginas do sistema operacional**, quente desde a última
vez que a tabela foi lida, então "ler" significou copiar de uma parte da memória para outra. Esse
é o cache duplo do primeiro parágrafo, visto de fora: o cache do servidor errou e o da máquina não.

## Um quarto da máquina virtual

Na máquina virtual que a lição 3 recomenda, um quarto de 4 GB é 1 GB. Ponha isso num arquivo do
`conf.d`, como a lição 5 fez, e reinicie, porque o `shared_buffers` é um parâmetro `postmaster`:

```
ana@db:~$ echo 'shared_buffers = 1GB' | sudo tee /etc/postgresql/16/main/conf.d/10-memory.conf
shared_buffers = 1GB
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql shop
shop=# SELECT name, setting, unit FROM pg_settings
shop-#  WHERE name IN ('shared_buffers', 'shared_memory_size');
        name        | setting | unit 
--------------------+---------+------
 shared_buffers     | 131072  | 8kB
 shared_memory_size | 1074    | MB
(2 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=114.404..117.692 rows=1 loops=1)
   Buffers: shared read=8334
   ->  Gather (actual time=109.975..117.674 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared read=8334
         ->  Partial Aggregate (actual time=104.727..104.729 rows=1 loops=3)
               Buffers: shared read=8334
               ->  Parallel Seq Scan on orders (actual time=0.017..79.448 rows=333333 loops=3)
                     Buffers: shared read=8334
 Planning:
   Buffers: shared hit=82 read=17
 Planning Time: 0.439 ms
 Execution Time: 117.749 ms
(14 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=107.340..114.517 rows=1 loops=1)
   Buffers: shared hit=8334
   ->  Gather (actual time=101.944..114.499 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=8334
         ->  Partial Aggregate (actual time=98.267..98.268 rows=1 loops=3)
               Buffers: shared hit=8334
               ->  Parallel Seq Scan on orders (actual time=0.012..65.756 rows=333333 loops=3)
                     Buffers: shared hit=8334
 Planning Time: 0.090 ms
 Execution Time: 114.562 ms
(12 rows)

shop=# SELECT buffers_used, buffers_unused FROM pg_buffercache_summary();
 buffers_used | buffers_unused 
--------------+----------------
         8569 |         122503
(1 row)

shop=# \q
```

`131072` páginas de 8 kB são o 1 GB, e o segmento compartilhado inteiro cresceu para 1074 MB junto.
A extensão sobreviveu ao restart, porque mora no banco; o cache que ela mostra, não. Agora a tabela
é menor que um quarto do cache, a varredura usou buffers comuns, e **a segunda contagem foi toda
de hits, `hit=8334`**, com todas as páginas da `orders` entre os 8569 buffers em uso.

O tempo quase não mudou, e esse é o resultado honesto nesta máquina: o cache de páginas já servia
as faltas a partir da memória. A diferença aparece numa máquina cujos dados de trabalho não cabem
duas vezes na memória, onde uma falta nos dois caches é uma leitura real do disco, e em consultas
que tocam as mesmas páginas muitas vezes, como um índice percorrido por milhares de buscas.

## Decidido na partida, perdido num restart

Três consequências de o cache ser um bloco único de memória compartilhada:

- **Mudá-lo custa um restart**, e o restart o esvazia. Os primeiros minutos depois disso rodam
  com o cache frio, mais um motivo para agendar restarts (lição 5).
- **Ele é alocado esteja sendo usado ou não.** Os 122503 buffers livres acima são memória que a
  máquina não pode dar a mais nada.
- **No Linux ele pode ficar em huge pages**, páginas de 2 MB em vez de 4 kB, o que poupa trabalho
  ao kernel num cache grande. O `huge_pages = try`, o padrão, só as usa se o kernel tiver algumas
  reservadas, e reservá-las é uma configuração do kernel (`vm.nr_hugepages`) que vale o trabalho
  num servidor com vários gigabytes de cache e não numa máquina virtual de 4 GB.

Deixe o `10-memory.conf` no lugar por enquanto. As duas próximas seções usam o `work_mem` e o
`maintenance_work_mem` padrão com este cache, e a última remove o arquivo.
