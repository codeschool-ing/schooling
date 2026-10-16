---
title: Uma cadeia para olhar, e o pg_locks
version: 1
---

A aula 12 fez sessões esperarem umas pelas outras e assistiu de dentro das janelas que esperavam.
Num servidor de verdade, ninguém está dentro dessas janelas. O que você vê é o sintoma: uma página
que carregava em poucos milissegundos agora dá timeout, o número de conexões sobe e **nada na
consulta lenta em si explica isso.** A pergunta que esta aula responde é a mesma com que a aula 12
terminou, feita de fora e enquanto acontece: pelo que ela está esperando, e quem está segurando
isso?

O instinto comum é achar a consulta lenta e olhar o plano dela. Quando o tempo é gasto esperando
uma trava (lock), o plano está bom e a consulta é inocente; **a culpada é outra sessão, e muitas
vezes uma que não está fazendo nada.**

## Montando a cadeia

Abra quatro terminais com `psql market`. As janelas A, B e C vão criar o problema; a janela D é
onde você investiga. Primeiro, em cada uma de A, B e C, peça o **id de processo** da sessão, o
número pelo qual o servidor a conhece:

```
market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           5792
(1 row)

Time: 0.797 ms
```

```
market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           5794
(1 row)

Time: 0.630 ms
```

```
market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           5796
(1 row)

Time: 0.636 ms
```

Os seus serão outros números; anote-os, porque tudo abaixo é dito em termos deles. Agora a janela A
muda o pedido 1 dentro de uma transação e depois não faz mais nada. Imagine uma aplicação que abriu
uma transação, rodou um update e foi chamar um serviço de pagamento que não responde:

```
market=# BEGIN;
BEGIN
Time: 0.177 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 2.112 ms
```

A janela B, na própria transação, muda o pedido 2 e depois o pedido 1, e espera a janela A:

```
market=# BEGIN;
BEGIN
Time: 0.119 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 1.723 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
```

A janela C muda o pedido 2 e espera a janela B:

```
market=# UPDATE orders SET status = 'cancelled' WHERE id = 2;
```

Três sessões, duas delas presas. Deixe-as assim por vinte segundos e então vá para a janela D.

## Lendo o `pg_locks`

O `pg_locks` tem uma linha para cada trava segura ou pedida no servidor neste momento. Num sistema
movimentado, são muitas linhas. Esta consulta fica só com os tipos que importam aqui: a trava de
tabela em `orders` e os dois tipos que uma trava de linha envolve, que os próximos parágrafos
explicam:

```
market=# SELECT pid, locktype, relation::regclass, page, tuple, transactionid, mode, granted FROM pg_locks WHERE pid <> pg_backend_pid() AND locktype IN ('relation', 'transactionid', 'tuple') AND (relation IS NULL OR relation = 'orders'::regclass) ORDER BY pid, granted DESC, locktype;
 pid  |   locktype    | relation | page | tuple | transactionid |       mode       | granted 
------+---------------+----------+------+-------+---------------+------------------+---------
 5792 | relation      | orders   |      |       |               | RowExclusiveLock | t
 5792 | transactionid |          |      |       |       1609205 | ExclusiveLock    | t
 5794 | relation      | orders   |      |       |               | RowExclusiveLock | t
 5794 | transactionid |          |      |       |       1609206 | ExclusiveLock    | t
 5794 | tuple         | orders   |    0 |     1 |               | ExclusiveLock    | t
 5794 | transactionid |          |      |       |       1609205 | ShareLock        | f
 5796 | relation      | orders   |      |       |               | RowExclusiveLock | t
 5796 | transactionid |          |      |       |       1609207 | ExclusiveLock    | t
 5796 | tuple         | orders   |    0 |     2 |               | ExclusiveLock    | t
 5796 | transactionid |          |      |       |       1609206 | ShareLock        | f
(10 rows)

Time: 2.457 ms
```

A coluna para ler primeiro é **`granted`**. Toda linha com `t` é uma trava que alguém tem; as duas
linhas com `f` são os pedidos que estão esperando, e elas são o problema inteiro.

**Cada transação segura um `ExclusiveLock` no próprio id de transação**, desde o momento em que muda
alguma coisa pela primeira vez até terminar: a janela A (5792) segura a transação 1609205, a janela
B (5794) segura a 1609206, a janela C (5796) segura a 1609207. É por essa trava que outras sessões
esperam por uma transação.

**Uma trava de linha não está nesta view.** A aula 12 disse que travas de linha moram nas próprias
linhas, e aqui está a consequência: nada no `pg_locks` diz "5792 travou o pedido 1". O que você vê
no lugar é a espera. A janela B encontrou o pedido 1 marcado como alterado pela transação 1609205.
Então pediu um **`ShareLock` na transação 1609205**, e ele não foi concedido: ela está esperando a
transação da janela A terminar, faça essa transação o que fizer com a linha. A janela C espera do
mesmo jeito pela 1609206, a transação da janela B.

**As linhas `tuple` são a fila de uma linha.** A janela B segura um `ExclusiveLock` na tupla 1 da
página 0 de `orders`, que é o lugar físico do pedido 1, e a janela C segura o da página 0, tupla 2,
o pedido 2. Quem espera pega a trava de tupla para que, se várias sessões esperarem pela mesma
linha, elas a recebam na ordem em que chegaram, e não todas de uma vez.

E as travas de tabela: as três seguram `RowExclusiveLock` em `orders`, que nunca conflitam entre
si, como diz a linha 3 da matriz da aula 12. **A espera aqui é inteiramente sobre linhas**, e é por
isso que uma consulta em `orders` que não muda nada, ou muda outras linhas, continua passando
enquanto isso acontece.

## Por que não parar no `pg_locks`

Tudo o que é preciso para descobrir quem espera por quem está nessas dez linhas: case cada
`transactionid` não concedido com a sessão que segura o mesmo `transactionid` com `ExclusiveLock`.
Fazer isso à mão num servidor com trezentas sessões é lento, e erra as regras para todo tipo de
trava menos este. **O PostgreSQL faz esse casamento por você**, numa função que a próxima seção usa;
o `pg_locks` continua sendo o lugar para ir quando você precisa saber exatamente qual trava, sobre
o quê.
