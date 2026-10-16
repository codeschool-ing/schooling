---
title: Uma tabela é alguns arquivos com números no nome
version: 1
---

Nada em `base/` se chama `shop` ou `orders`. Todo banco e toda tabela têm um **oid**, um
identificador de objeto que o servidor atribui, e os arquivos levam números derivados dele. O
catálogo diz qual número é qual:

```
shop=# SELECT oid, datname FROM pg_database ORDER BY oid;
  oid  |  datname  
-------+-----------
     1 | template1
     4 | template0
     5 | postgres
 16385 | ana
 16386 | shop
(5 rows)

shop=# SELECT pg_relation_filepath('orders');
 pg_relation_filepath 
----------------------
 base/16386/16398
(1 row)

shop=# SELECT pg_relation_filepath('orders_created_at');
 pg_relation_filepath 
----------------------
 base/16386/16411
(1 row)
```

O `shop` é o banco 16386, então mora em `base/16386`. A tabela `orders` é o arquivo `16398` ali
dentro, e o índice dela sobre `created_at` é outro arquivo, `16411`: **um índice é uma relação
própria**, com arquivo próprio, e nada no nome dele o amarra à tabela no disco. Os três oids pequenos
no topo são os bancos com que todo cluster nasce; o `template1` é copiado cada vez que alguém roda
`createdb`.

Seus números podem ser outros se você criou alguma coisa antes do `shop`. É para isso que existe o
`pg_relation_filepath`: nunca calcule um nome de arquivo de cabeça.

## Uma tabela, três forks

```
ana@db:~$ sudo find /var/lib/postgresql/16/main/base/16386 -name '16398*' -printf '%-10s %f\n'
68272128   16398
40960      16398_fsm
```

O `16398` guarda as linhas, em 68.272.128 bytes. O `16398_fsm` é o **mapa de espaço livre**: para cada
página da tabela, mais ou menos quanto espaço sobra nela, para que um `INSERT` ache uma página com
espaço sem ler a tabela. O PostgreSQL chama esses arquivos de **forks** de uma relação. Há um
terceiro, e ele aparece depois do primeiro `VACUUM`:

```
shop=# VACUUM orders;
VACUUM
ana@db:~$ sudo find /var/lib/postgresql/16/main/base/16386 -name '16398*' -printf '%-10s %f\n'
8192       16398_vm
68272128   16398
40960      16398_fsm
```

O `16398_vm` é o **mapa de visibilidade**: dois bits por página, dizendo se toda linha daquela página
é visível para toda transação e se toda linha dela está congelada. Ele tem 8192 bytes para uma
tabela de 65 MB. A lição 14 é sobre por que o `VACUUM` o mantém e quem o lê.

## Páginas, segmentos e os tamanhos que o psql informa

```
shop=# SELECT pg_size_pretty(pg_relation_size('orders')) AS main_fork,
shop-#        pg_size_pretty(pg_table_size('orders')) AS table_size,
shop-#        pg_size_pretty(pg_indexes_size('orders')) AS indexes,
shop-#        pg_size_pretty(pg_total_relation_size('orders')) AS total;
 main_fork | table_size | indexes | total  
-----------+------------+---------+--------
 65 MB     | 65 MB      | 42 MB   | 108 MB
(1 row)

shop=# SHOW block_size;
 block_size 
------------
 8192
(1 row)

shop=# SHOW segment_size;
 segment_size 
--------------
 1GB
(1 row)
```

Quatro funções, quatro respostas, e a diferença entre elas é a diferença entre os forks. O
`pg_relation_size` é só o fork principal, o `pg_table_size` soma os mapas de espaço livre e de
visibilidade (e o armazenamento TOAST de valores longos, se houver), o `pg_indexes_size` é a soma
dos índices, e o `pg_total_relation_size` é tudo — **108 MB para uma tabela que o `\dt+` chama de
65 MB**. Quando alguém pergunta o tamanho de uma tabela, a resposta honesta diz qual das quatro.

Todo arquivo é uma sequência de **páginas** de `block_size` bytes, 8192 aqui e em quase todo
PostgreSQL que existe; 68.272.128 bytes são exatamente 8.334 páginas. Um arquivo nunca passa de
`segment_size`, um gigabyte: uma tabela de 5 GB são cinco arquivos, de `16398` e `16398.1` até
`16398.4`. Os dois números são fixados quando o PostgreSQL é compilado, e a lição 9 é sobre como eles
encontram o disco embaixo.

## O número pode mudar

```
shop=# CREATE TABLE scratch AS SELECT * FROM orders WHERE id <= 1000;
SELECT 1000
```

O `TRUNCATE` não esvaziou o arquivo; ele deu à tabela um **arquivo novo, vazio**, e jogou o antigo
fora, e é por isso que é instantâneo numa tabela de qualquer tamanho. `VACUUM FULL`, `CLUSTER` e
alguns tipos de `ALTER TABLE` fazem o mesmo. O oid da tabela fica; o número no disco, o
**relfilenode**, não. Mais um motivo para um nome de arquivo ser algo que se consulta, e não que se
decora.
