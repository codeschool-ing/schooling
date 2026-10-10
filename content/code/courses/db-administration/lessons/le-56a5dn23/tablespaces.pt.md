---
title: Tablespaces, e por que você raramente vai criar um
version: 1
---

Um **tablespace** é um segundo lugar para guardar arquivos: um diretório fora do diretório de dados
em que o servidor pode pôr tabelas e índices. Todo cluster já tem dois, o `pg_default` (que é
`base/`) e o `pg_global` (que é `global/`), e dá para acrescentar mais. A ideia é antiga e correta —
pôr a tabela mais movimentada no disco mais rápido — e na maioria dos servidores modernos ela já
não paga o que custa. Criar um mostra as duas metades.

O diretório precisa existir, estar vazio e pertencer ao `postgres`, sem mais ninguém com acesso. No
seu servidor ele é só outro diretório no mesmo disco, o que basta para ver como funciona:

```
ana@db:~$ sudo mkdir -p /srv/pg/fast
ana@db:~$ sudo chown postgres:postgres /srv/pg/fast
ana@db:~$ sudo chmod 700 /srv/pg/fast
shop=# CREATE TABLESPACE fast LOCATION '/srv/pg/fast';
CREATE TABLESPACE

shop=# \db
         List of tablespaces
    Name    |  Owner   |   Location   
------------+----------+--------------
 fast       | ana      | /srv/pg/fast
 pg_default | postgres | 
 pg_global  | postgres | 
(3 rows)

shop=# ALTER TABLE customers SET TABLESPACE fast;
ALTER TABLE

shop=# SELECT pg_relation_filepath('customers');
            pg_relation_filepath             
---------------------------------------------
 pg_tblspc/16428/PG_16_202307071/16386/16429
(1 row)
```

**O `ALTER TABLE … SET TABLESPACE` copia a tabela inteira** para o lugar novo e segura uma trava que
bloqueia toda leitura e escrita nela até a cópia terminar. Para 4,5 MB isso não é nada; para uma
tabela de 200 GB é uma indisponibilidade, e a lição 22 é sobre não causar essas. Repare também que só
a tabela mudou: os índices ficaram onde estavam, e cada um se move com o seu próprio `ALTER INDEX`.

O caminho novo começa com `pg_tblspc`, e esse diretório no cluster é como o servidor reencontra os
tablespaces depois de reiniciar:

```
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main/pg_tblspc
total 0
lrwxrwxrwx 1 postgres postgres 12 Oct 10 04:11 16428 -> /srv/pg/fast
ana@db:~$ sudo find /srv/pg/fast -maxdepth 3
/srv/pg/fast
/srv/pg/fast/PG_16_202307071
/srv/pg/fast/PG_16_202307071/16386
/srv/pg/fast/PG_16_202307071/16386/16429
/srv/pg/fast/PG_16_202307071/16386/16431
/srv/pg/fast/PG_16_202307071/16386/16430
/srv/pg/fast/PG_16_202307071/16386/16429_fsm
```

Um **link simbólico**, com o oid do tablespace como nome, apontando para o diretório. Lá dentro o
servidor criou `PG_16_202307071`, um subdiretório com o nome da versão maior e da versão do catálogo,
para que duas versões maiores possam dividir um local durante um upgrade; depois o oid do banco,
`16386`, e então os arquivos da tabela, exatamente como em `base/`. Dois dos outros números são a
tabela TOAST que `customers` carrega para valores longos e o índice dela.

## O que custa

Um tablespace faz parte do cluster e **não pode ser copiado, restaurado ou movido sozinho**. Uma
ferramenta de backup precisa saber seguir o link, uma restauração precisa recriar o diretório antes,
e um cluster cujo disco do tablespace não montou no boot sobe com tabelas que simplesmente sumiram.
Perder o disco de um tablespace perde aquelas tabelas, e o resto do cluster também deixa de ser
confiável, porque o catálogo continua dizendo que elas existem.

O que ele compra é menos do que já foi. Num servidor com um disco rápido, ou num armazenamento de
nuvem em que todo volume é do mesmo tipo ligado pela rede, não existe lugar mais rápido para pôr
nada. Os casos que sobram são reais, mas estreitos: uma tabela grande demais para o disco principal
enquanto se arranja um maior, ou arquivos temporários de ordenações grandes (`temp_tablespaces`) num
disco de rascunho de que ninguém precisa fazer backup.

**Ponha de volta antes de seguir**, para que o seu `shop` volte a bater com o curso:

```
shop=# ALTER TABLE customers SET TABLESPACE pg_default;
ALTER TABLE

shop=# DROP TABLESPACE fast;
DROP TABLESPACE
```

Um tablespace com qualquer coisa dentro não pode ser apagado, e por isso a tabela precisou sair
antes. O `/srv/pg/fast` fica vazio; `sudo rmdir /srv/pg/fast /srv/pg` o remove.
