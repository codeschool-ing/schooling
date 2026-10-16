---
title: Por que um índice é reconstruído
version: 1
---

Um índice parece parte da tabela, e é fácil pensar nele como algo que existe ou não existe. **Ele é
uma segunda cópia de parte dos dados da tabela, ordenada, guardada em arquivos próprios**, e uma
cópia pode se desencontrar do que copia. O `REINDEX` joga a cópia fora e a constrói de novo a partir
da tabela. Há três razões para querer isso, e elas são muito diferentes em urgência.

**Inchaço.** A lição 15 o mediu com `pgstatindex`: depois de muitos updates e deletes um índice pode
ser quase só páginas vazias, e uma reconstrução o compacta de novo. É a razão comum e a menos
urgente, porque um índice inchado ainda dá respostas certas.

**Corrupção.** Um disco falhando, uma controladora que mentiu sobre uma escrita, um bug do kernel ou
do PostgreSQL. O índice não bate mais com a tabela, e uma consulta que o usa pode devolver linhas
que não satisfazem a condição ou deixar de achar linhas que satisfazem. A seção sobre amcheck desta
lição mostra como procurar isso.

**Uma mudança nas regras pelas quais o índice foi ordenado.** Esta é a menos óbvia, acontece durante
a manutenção rotineira do sistema operacional, e dá respostas erradas sem nada no log.

## A ordem do texto pertence ao sistema operacional

Um índice numa coluna de texto guarda as entradas na ordem que a **collation** da coluna diz. Com o
provedor libc, o padrão, essa ordem vem da biblioteca C da máquina, a glibc no Ubuntu, e collations
diferentes ordenam as mesmas strings de jeitos diferentes:

```
ana@db:~$ ldd --version | head -1
ldd (Ubuntu GLIBC 2.39-0ubuntu8) 2.39
ana@db:~$ printf 'B\na\n11\n1-1\n' | LC_COLLATE=C sort
1-1
11
B
a
ana@db:~$ printf 'B\na\n11\n1-1\n' | LC_COLLATE=en_US.UTF-8 sort
1-1
11
a
B
```

`C` compara bytes, então `B` vem antes de `a`. `en_US.UTF-8` segue as regras de uma língua, e `a`
vem primeiro. As duas estão certas, pelas suas próprias regras. O problema é que **as regras de uma
mesma collation mudaram entre versões da glibc**, e a grande mudança veio na glibc 2.28: na 2.27 e
antes, `en_US.UTF-8` punha `11` antes de `1-1`, e da 2.28 em diante põe `1-1` primeiro, como acima.
Esse resultado antigo foi tirado da página da wiki do PostgreSQL sobre mudanças nos dados de locale
e não foi rodado aqui; esta máquina tem glibc 2.39. O Ubuntu 18.04 vinha com a 2.27 e o 20.04 com a
2.31, então um upgrade entre os dois cruzou a linha.

Um índice construído com as regras antigas tem as entradas na ordem antiga. Depois do upgrade, o
PostgreSQL o percorre com as novas. A busca desce a árvore comparando chaves, vira para o lado
errado onde quer que as duas ordens discordem, e **não acha nada onde a linha está no índice o
tempo todo**. Um índice único deixa de ver a duplicata que existe para recusar. Nada dá erro.

## O PostgreSQL registra a versão, e avisa

Desde o PostgreSQL 15, cada banco registra a versão da biblioteca de collation com que foi criado, e
a compara a cada conexão.

```
shop=# SELECT datname, datcollate, datcollversion FROM pg_database WHERE datname = 'shop';
 datname | datcollate | datcollversion 
---------+------------+----------------
 shop    | C.UTF-8    | 
(1 row)

shop=# CREATE DATABASE coll_check TEMPLATE template0 LOCALE 'en_US.UTF-8';
CREATE DATABASE

shop=# SELECT datname, datcollate, datcollversion FROM pg_database WHERE datname = 'coll_check';
  datname   | datcollate  | datcollversion 
------------+-------------+----------------
 coll_check | en_US.UTF-8 | 2.39
(1 row)
```

O cluster da máquina da gravação foi criado com `C.UTF-8`, que compara pontos de código e não tem
versão a registrar, então `datcollversion` está vazio para `shop`. Um servidor instalado pelo
instalador do Ubuntu em inglês costuma ter `en_US.UTF-8`, e o seu pode muito bem mostrar uma versão
ao lado de `shop`. O banco descartável `coll_check` é criado com `en_US.UTF-8` para ter uma: glibc
2.39.

Esta máquina só tem uma glibc, então para ver o aviso o próximo passo **trapaceia**: edita à mão a
versão registrada, para a que um servidor Ubuntu 18.04 teria escrito. Nunca faça isso num banco que
alguém guarda; em `coll_check`, que é apagado duas linhas depois, mostra exatamente o que o servidor
diz depois de um upgrade de verdade:

```
shop=# UPDATE pg_database SET datcollversion = '2.27' WHERE datname = 'coll_check';
UPDATE 1

shop=# \c coll_check
WARNING:  database "coll_check" has a collation version mismatch
DETAIL:  The database was created using collation version 2.27, but the operating system provides version 2.39.
HINT:  Rebuild all objects in this database that use the default collation and run ALTER DATABASE coll_check REFRESH COLLATION VERSION, or build PostgreSQL with the right library version.
You are now connected to database "coll_check" as user "ana".

coll_check=# REINDEX DATABASE coll_check;
REINDEX

coll_check=# ALTER DATABASE coll_check REFRESH COLLATION VERSION;
NOTICE:  changing version from 2.27 to 2.39
ALTER DATABASE

coll_check=# \c shop
You are now connected to database "shop" as user "ana".

shop=# DROP DATABASE coll_check;
DROP DATABASE
```

O `WARNING` nomeia o problema e o `HINT` nomeia a cura, nessa ordem: **reconstruir o que usa a
collation, e depois dizer ao banco que a versão nova é a que ele tem agora**. O `REINDEX DATABASE`
reconstrói todo índice do banco, o que num banco vazio é instantâneo e num grande é a parte longa.
Atualizar a versão primeiro só calaria o aviso e deixaria os índices como estavam.

Duas coisas decorrem disso para um administrador. Antes de mover um servidor para uma nova versão do
sistema operacional, confira se a glibc cruza uma mudança, e planeje o reindex como parte da
mudança. E saiba quais caminhos de upgrade levam os arquivos de índice antigos junto: o `pg_upgrade`
e uma réplica física no sistema novo levam, enquanto um dump e restore ou a replicação lógica
constroem todo índice de novo na máquina nova. A lição 20 faz os upgrades; esta é a pergunta a fazer
antes de escolher um.
