---
title: Quanto log custa uma alteração
version: 1
---

O tamanho de uma alteração no log não é o tamanho da alteração na tabela. **Às vezes é minúsculo,
e às vezes um byte alterado custa uma página inteira**, e qual dos dois você recebe depende de quando
a página fez parte de um checkpoint pela última vez. O `pg_wal_lsn_diff` mede isso: pegue a posição
antes, faça a alteração e subtraia.

## Uma linha, duas vezes

Peça um checkpoint primeiro, para as duas atualizações partirem do mesmo lugar, depois mude o status
de um pedido e volte ao valor de antes:

```
shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders SET status = 'shipped' WHERE id = 1000000;
UPDATE 1

shop=# SELECT :'before' AS before, pg_current_wal_lsn() AS after,
shop-#        pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') AS bytes;
   before   |   after    | bytes 
------------+------------+-------
 0/1584F320 | 0/158516F8 |  9176
(1 row)

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders SET status = 'paid' WHERE id = 1000000;
UPDATE 1

shop=# SELECT :'before' AS before, pg_current_wal_lsn() AS after,
shop-#        pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') AS bytes;
   before   |   after    | bytes 
------------+------------+-------
 0/158516F8 | 0/15851770 |   120
(1 row)
```

`\gset` é um comando do `psql` que guarda as colunas do último resultado em variáveis com os nomes
delas, e `:'before'` lê a variável de volta como um valor entre aspas. A mesma alteração, feita
duas vezes seguidas, escreveu **9176 bytes na primeira vez e 120 na segunda**. O `pg_waldump` sobre
o intervalo todo diz para onde foi a diferença:

```
ana@db:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump -p /var/lib/postgresql/16/main/pg_wal -s 0/1584F320 -e 0/15851770
rmgr: Heap2       len (rec/tot):     60/  6228, tx:          0, lsn: 0/1584F320, prev 0/1584F2A8, desc: PRUNE snapshotConflictHorizon: 781, nredirected: 3, ndead: 1, blkref #0: rel 1663/16386/2619 blk 18 FPW
rmgr: Heap        len (rec/tot):     65/  2877, tx:        785, lsn: 0/15850B90, prev 0/1584F320, desc: HOT_UPDATE old_xmax: 785, old_off: 40, old_infobits: [], flags: 0x00, new_xmax: 0, new_off: 41, blkref #0: rel 1663/16386/16398 blk 8333 FPW
rmgr: Transaction len (rec/tot):     34/    34, tx:        785, lsn: 0/158516D0, prev 0/15850B90, desc: COMMIT 2026-10-10 04:26:34.355258 -03
rmgr: Heap        len (rec/tot):     78/    78, tx:        786, lsn: 0/158516F8, prev 0/158516D0, desc: HOT_UPDATE old_xmax: 786, old_off: 41, old_infobits: [], flags: 0x60, new_xmax: 0, new_off: 42, blkref #0: rel 1663/16386/16398 blk 8333
rmgr: Transaction len (rec/tot):     34/    34, tx:        786, lsn: 0/15851748, prev 0/158516F8, desc: COMMIT 2026-10-10 04:26:35.572982 -03
```

Olhe os dois registros `HOT_UPDATE` no bloco 8333 de `orders` (arquivo `16398`). O registro em si
tem quase o mesmo tamanho nas duas vezes, 65 e 78 bytes. **O total do primeiro é 2877, e ele termina
em `FPW`**: um full-page write, uma cópia da página inteira anexada ao registro. O segundo não tem.

A primeira linha nem é a sua atualização. Planejá-la leu as estatísticas do planejador, o catálogo
`pg_statistic` (arquivo `2619`), e o servidor aproveitou para limpar versões antigas de linhas de
uma das páginas dele. Essa também foi a primeira alteração daquela página desde o checkpoint, então
ela também foi inteira para o log, e foi o maior item dos 9176.

## Por que uma página inteira

Uma página tem 8 kB, e o disco por baixo escreve em pedaços menores, que são o assunto da lição 9.
**Se a energia cair no meio da gravação de uma página, a página no disco fica metade velha e metade
nova**, uma *página rasgada*. Um registro que diz "no bloco 8333, troque a linha da posição 40" não
pode ser refeito em cima disso, porque ele supõe que o resto da página está intacto.

Por isso, na primeira vez que qualquer página é alterada depois de um checkpoint, o registro leva
uma imagem da página inteira. A recuperação sempre começa de um checkpoint, como a lição 8 mostra,
então para cada página ela encontra a imagem primeiro: põe a página de volta exatamente como era e
depois aplica os registros pequenos que vieram em seguida. A segunda alteração da mesma página não
precisa de imagem, porque a primeira já garantiu uma cópia boa no log. Essa é a configuração
`full_page_writes`, ligada por padrão, e a lição 8 explica por que ela fica ligada.

A imagem deixa de fora o meio vazio da página, por isso o total foi 2877 e não 8192: o bloco 8333 é
a última página de `orders`, e só uma parte dela está ocupada. Uma página cheia custa quase os 8 kB
inteiros.

## Uma tabela inteira

Uma linha é curiosidade. A mesma conta sobre um milhão de linhas é o motivo de o `pg_wal` crescer.
Copie `orders` para uma tabela de rascunho, para deixar a verdadeira em paz, e atualize todas as
linhas duas vezes:

```
shop=# CREATE TABLE orders_copy AS SELECT * FROM orders;
SELECT 1000000

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy'));
 pg_size_pretty 
----------------
 66 MB
(1 row)

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders_copy SET total_cents = total_cents + 1;
UPDATE 1000000

shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));
 pg_size_pretty 
----------------
 234 MB
(1 row)

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders_copy SET total_cents = total_cents - 1;
UPDATE 1000000

shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));
 pg_size_pretty 
----------------
 171 MB
(1 row)

shop=# DROP TABLE orders_copy;
DROP TABLE
```

**Atualizar uma tabela de 66 MB uma vez escreveu 234 MB de log.** A atualização de cada linha é
registrada com a nova versão da linha e as páginas que ela tocou, então mesmo a segunda passada,
sem nenhuma imagem de página para tirar, escreveu 171 MB. A maior parte dos 63 MB de diferença
entre as duas são as imagens da primeira passada: logo depois de um checkpoint, quase todas as
páginas originais da tabela foram alteradas pela primeira vez.

Três coisas decorrem disso, e um administrador usa todas:

- Uma alteração em massa escreve várias vezes o próprio tamanho em WAL. Planeje o espaço em disco
  e o tráfego para as réplicas pelo log, não pela tabela.
- Os primeiros minutos depois de um checkpoint escrevem mais log que os minutos antes do próximo. Um
  checkpoint a cada trinta segundos manteria o servidor inteiro nessa fase cara; a lição 8 mede
  exatamente isso.
- O `wal_compression` existe para as imagens. Ele comprime cada imagem de página quando ela é
  escrita, a algum custo de processador. Fica desligado por padrão e não foi mudado nesta lição.
