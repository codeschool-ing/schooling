---
title: O pgbench, e o banco que vem com ele
version: 1
---

Toda aula desde a segunda usou o `pgbench` para gerar tráfego. Esta aula o usa para **medir**, que é
outro trabalho: um número que vai decidir se uma mudança vai para produção precisa vir de uma
execução parecida com a produção, e a primeira coisa a saber sobre o `pgbench` é que, deixado por
conta própria, ele se parece com um banco — dos que guardam dinheiro.

## O teste embutido

O `pgbench` vem com uma carga própria, inspirada de longe num antigo benchmark da indústria chamado
TPC-B. Ela precisa de tabelas próprias, então dê a ela um banco de dados próprio e deixe o `-i`
criá-las. `-s 10` é a escala: dez agências, cem caixas e um milhão de contas:

```
ana@vm:~$ createdb bench
ana@vm:~$ pgbench -i -s 10 bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 1000000 tuples (10%) done (elapsed 0.05 s, remaining 0.45 s)
200000 of 1000000 tuples (20%) done (elapsed 0.11 s, remaining 0.44 s)
300000 of 1000000 tuples (30%) done (elapsed 0.17 s, remaining 0.39 s)
400000 of 1000000 tuples (40%) done (elapsed 0.24 s, remaining 0.35 s)
500000 of 1000000 tuples (50%) done (elapsed 0.29 s, remaining 0.29 s)
600000 of 1000000 tuples (60%) done (elapsed 0.36 s, remaining 0.24 s)
700000 of 1000000 tuples (70%) done (elapsed 0.41 s, remaining 0.18 s)
800000 of 1000000 tuples (80%) done (elapsed 0.48 s, remaining 0.12 s)
900000 of 1000000 tuples (90%) done (elapsed 0.54 s, remaining 0.06 s)
1000000 of 1000000 tuples (100%) done (elapsed 0.59 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.95 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 0.61 s, vacuum 0.11 s, primary keys 0.22 s).
```

Um milhão de linhas em menos de um segundo. E aqui está o que cada transação dele faz, impresso pelo
próprio `pgbench`:

```
ana@vm:~$ pgbench --show-script=tpcb-like
-- tpcb-like: <builtin: TPC-B (sort of)>
\set aid random(1, 100000 * :scale)
\set bid random(1, 1 * :scale)
\set tid random(1, 10 * :scale)
\set delta random(-5000, 5000)
BEGIN;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
END;
```

Uma conta muda o saldo, e o caixa e a agência a que ela pertence mudam os seus, e uma linha vai para
uma tabela de histórico. Rode-o do jeito que a aula 2 rodou a carga, oito clientes em quatro threads
por trinta segundos:

```
ana@vm:~$ pgbench -c 8 -j 4 -T 30 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 119440
number of failed transactions: 0 (0.000%)
latency average = 2.010 ms
initial connection time = 8.750 ms
tps = 3979.789440 (without initial connection time)
```

**3980 transações por segundo, 2 milissegundos cada.** Na mesma máquina, a carga do marketplace da
aula 2 roda a cerca de um terço disso, e o relatório da próxima seção fica em torno de 1234. Nenhum
dos números está errado. São respostas a duas perguntas diferentes, e só uma das perguntas é sua.

## Por que essa não é a sua carga

Leia o script de novo pensando no `market`:

- **toda transação escreve.** Três `UPDATE` e um `INSERT` contra um `SELECT`. O tráfego do
  marketplace é sobretudo leitura, com um décimo dele comprando alguma coisa.
- **dez agências.** Com `-s 10` há dez linhas em `pgbench_branches`, e toda transação atualiza uma
  delas. Oito clientes disputam dez linhas, então parte do que esta execução mede é a rapidez com que
  as travas (locks) de linha trocam de mãos — o assunto da aula 12 —, e isso depende mais da escala
  do que do servidor.
- **toda chave é igualmente provável.** `random(1, 100000 * :scale)` escolhe qualquer conta com a
  mesma probabilidade. O tráfego real tem favoritos: o maior vendedor, os pedidos desta semana, os
  clientes que voltam.
- **cabe na memória muitas vezes.** Um milhão de linhas curtas, numa máquina em que a aula 1 achou
  14 GB livres.

**Um benchmark mede um servidor rodando uma carga, nunca um servidor sozinho.** Mude a carga e o
número muda, e uma mudança no servidor — um índice, um ajuste, uma máquina maior — pode ajudar uma
carga e não fazer nada por outra. Um índice em `orders` não mexeria no número do banco de jeito
nenhum.

## Para que ele serve

O teste embutido é uma carga rápida e repetível que qualquer um reproduz com um comando. Isso o torna
útil para um tipo de pergunta: **esta máquina está com defeito?** Dois servidores que deveriam ser
iguais e dão números muito diferentes no `pgbench -i -s 10`, ou um disco novo que corta pela metade a
vazão do banco, merecem ser conhecidos antes de a sua carga rodar. Para qualquer coisa sobre a sua
aplicação — este índice vai ajudar, esta máquina vai aguentar dezembro —, a carga tem de ser a sua, e
a próxima seção a monta.

O banco de dados do banco não é mais necessário:

```
ana@vm:~$ dropdb bench
```
