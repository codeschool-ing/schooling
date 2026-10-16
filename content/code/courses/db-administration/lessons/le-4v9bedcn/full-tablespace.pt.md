---
title: Um tablespace cheio
version: 1
---

A lição 4 criou um tablespace no mesmo disco de todo o resto. Este ganha um sistema de arquivos de
64 MB, feito do mesmo jeito que o do log, para poder ser enchido em um segundo:

```
ana@db:~$ sudo truncate -s 64M /srv/small.img
ana@db:~$ sudo mkfs.ext4 -q /srv/small.img
ana@db:~$ sudo mkdir /srv/small
ana@db:~$ sudo mount -o loop /srv/small.img /srv/small
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   24K   52M   1% /srv/small
ana@db:~$ sudo tune2fs -l /srv/small.img | grep -E "^(Block count|Reserved block count|Block size)"
Block count:              16384
Reserved block count:     819
Block size:               4096
```

**O `df` diz 56 MB de tamanho e 52 MB disponíveis, com nada usado.** Os quatro que faltam são quase
todos a reserva que o `tune2fs` mostra: 819 blocos de 4096 bytes, cinco por cento do sistema de
arquivos, que o ext4 guarda para o usuário root, para que um disco cheio ainda deixe a um
administrador espaço para trabalhar. O PostgreSQL roda como `postgres`, não como root, então para o
banco este sistema de arquivos está cheio em 52 MB. Guarde a reserva na memória; ela vai importar
daqui a pouco.

Dê ao `postgres` um diretório nele, crie o tablespace e ponha uma tabela lá:

```
ana@db:~$ sudo install -d -o postgres -g postgres -m 700 /srv/small/pg
```

```
shop=# CREATE TABLESPACE small LOCATION '/srv/small/pg';
CREATE TABLESPACE

shop=# CREATE TABLE filler (id bigint, pad text) TABLESPACE small;
CREATE TABLE

shop=# INSERT INTO filler SELECT i, repeat('x', 500) FROM generate_series(1, 200000) AS i;
ERROR:  could not extend file "pg_tblspc/16420/PG_16_202307071/16386/16421": No space left on device
HINT:  Check free disk space.

shop=# SELECT count(*) FROM filler;
 count 
-------
     0
(1 row)

shop=# SELECT pg_size_pretty(pg_relation_size('filler'));
 pg_size_pretty 
----------------
 51 MB
(1 row)

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)
```

O `install -d` criou o diretório com dono e modo num comando só. O insert queria cerca de 100 MB, e
o sistema de arquivos tinha 52.

## O que o erro diz

**`could not extend file` é um `ERROR`, a severidade que encerra um comando.** O insert foi
desfeito, a tabela não tem linhas, e o servidor seguiu em frente: a consulta seguinte leu um milhão
de pedidos do outro disco sem notar nada. O caminho é o arquivo da tabela, relativo ao diretório de
dados, e `pg_tblspc/16420` é o link do tablespace, como a lição 4 mostrou, que é como você sabe para
qual sistema de arquivos olhar. O log tem as mesmas linhas, com o comando que as causou:

```
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   52M     0 100% /srv/small
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:54:47.285 -03 [396] ana@shop ERROR:  could not extend file "pg_tblspc/16420/PG_16_202307071/16386/16421": No space left on device
2026-10-10 16:54:47.285 -03 [396] ana@shop HINT:  Check free disk space.
2026-10-10 16:54:47.285 -03 [396] ana@shop STATEMENT:  INSERT INTO filler SELECT i, repeat('x', 500) FROM generate_series(1, 200000) AS i;
```

**O rollback não devolveu nada.** A tabela não tem nenhuma linha e o arquivo dela continua com
51 MB, porque um insert desfeito deixa suas linhas para trás como tuplas mortas em páginas que agora
existem; a lição 14 trata do que as remove. O sistema de arquivos continua cheio, e o próximo
comando que precisar de uma página nele falha do mesmo jeito.

## Saindo

O `VACUUM` é o que remove linhas mortas, e quando as últimas páginas de uma tabela estão vazias ele
as devolve ao sistema de arquivos. Então ele deveria resolver isto:

```
shop=# VACUUM filler;
ERROR:  could not extend file "pg_tblspc/16420/PG_16_202307071/16386/16421_vm": No space left on device
HINT:  Check free disk space.
CONTEXT:  while scanning block 0 of relation "public.filler"
```

**A ferramenta que libera o espaço precisa de um pouco de espaço para rodar.** O arquivo `_vm` é o
mapa de visibilidade da tabela, um pequeno arquivo companheiro que o `VACUUM` cria enquanto
trabalha, e não havia um bloco livre para criá-lo. Esse é o formato de costume de uma emergência de
disco cheio: toda saída escreve alguma coisa primeiro.

É para isso que serve a reserva do ext4. O `tune2fs -m 0` entrega os cinco por cento a todo mundo,
no dispositivo montado, que o `findmnt` nomeia:

```
ana@db:~$ sudo tune2fs -m 0 "$(findmnt --noheadings --output SOURCE /srv/small)"
tune2fs 1.47.0 (5-Feb-2023)
Setting reserved blocks percentage to 0% (0 blocks)
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   52M  3.2M  95% /srv/small
```

```
shop=# VACUUM filler;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('filler'));
 pg_size_pretty 
----------------
 0 bytes
(1 row)

shop=# CHECKPOINT;
CHECKPOINT
```

```
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   60K   55M   1% /srv/small
ana@db:~$ sudo tune2fs -m 5 "$(findmnt --noheadings --output SOURCE /srv/small)"
tune2fs 1.47.0 (5-Feb-2023)
Setting reserved blocks percentage to 5% (819 blocks)
```

Com 3,2 MB para trabalhar, o `VACUUM` encontrou todas as páginas vazias e cortou o arquivo a nada.
**Depois a reserva volta**, porque ela só vale alguma coisa enquanto não é usada.

O `CHECKPOINT` importa mais do que parece. Até o próximo checkpoint, a recuperação depois de uma
queda começaria de um ponto anterior ao insert que falhou e o repetiria, página por página, neste
mesmo sistema de arquivos pequeno. Uma gravação anterior desta lição o deixou de fora, derrubou o
servidor na seção seguinte, e a recuperação parou com o mesmo `could not extend file` contra este
tablespace, desta vez durante o `WAL redo`. Um checkpoint move o ponto de partida da recuperação
para depois de tudo isso.

Isso funcionou porque as linhas mortas eram tudo o que havia. Num servidor de verdade, o sistema de
arquivos cheio guarda linhas de que alguém precisa, e as saídas são as que não dependem de sorte:

- **dar mais espaço ao sistema de arquivos**, o que a próxima seção faz com o do log;
- **mover uma tabela para um tablespace que tenha espaço**, com `ALTER TABLE ... SET TABLESPACE`,
  que a copia e a trava contra toda consulta enquanto copia;
- **remover o que pode ser removido**: `TRUNCATE` ou `DROP TABLE` em algo descartável libera o
  espaço no momento em que a transação confirma, enquanto o `DELETE` não libera nada.

**Nunca apague arquivos dentro do diretório de dados ou de um tablespace à mão.** Os arquivos
numerados pertencem a tabelas, e um que falta é uma tabela que dá erro em toda leitura dali em
diante.
