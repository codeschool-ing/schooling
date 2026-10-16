---
title: Um deadlock, e a ordem que o impede
version: 1
---

Tudo até aqui esperou e depois seguiu, porque a transação pela qual se esperava acabou terminando.
Um **deadlock** são duas transações esperando uma pela outra, de modo que nenhuma pode terminar e a
espera duraria para sempre. A crença comum é que um deadlock quer dizer que o banco está quebrado ou
sobrecarregado. Não quer dizer nenhum dos dois. **São duas transações corretas que travam as mesmas
linhas em ordens opostas**, e a resposta do PostgreSQL é cancelar uma delas, o que transforma um
travamento silencioso num erro que a sua aplicação precisa tratar.

## Fazendo um

Duas janelas, cada uma atualizando os pedidos 1 e 2, em ordens opostas. A janela A pega o pedido 1,
a janela B pega o pedido 2, e então a janela A pede o pedido 2:

```
market=# BEGIN;
BEGIN
Time: 0.359 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 1.932 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
```

```
market=# BEGIN;
BEGIN
Time: 0.420 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 1.906 ms
```

A janela A está esperando a janela B, o que até aqui é uma espera comum. Agora a janela B pede o
pedido 1, que a janela A segura:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
ERROR:  deadlock detected
DETAIL:  Process 8870 waits for ShareLock on transaction 1525089; blocked by process 8868.
Process 8868 waits for ShareLock on transaction 1525090; blocked by process 8870.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (16666,82) in relation "orders"
Time: 1001.015 ms (00:01.001)
```

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 5368.645 ms (00:05.369)
```

Leia o erro, porque ele diz exatamente o que aconteceu. **`deadlock detected`**, e o `DETAIL` dá o
ciclo: o processo 8870 (janela B) espera a transação 1525089, segura pelo processo 8868 (janela A),
e o processo 8868 espera a transação 1525090, segura pelo 8870. Uma trava de linha espera pela
**transação** que segura a linha, e é por isso que a trava citada é um `ShareLock on transaction` e
não algo sobre uma linha; o `CONTEXT` dá o endereço físico da linha em `orders`.

O comando da janela B falhou depois de **1001 ms**, e o número não é acaso. O servidor não procura
ciclos a cada espera, o que seria caro; uma sessão que espera faz a checagem depois de ter esperado
**`deadlock_timeout`**, um segundo por padrão. A checagem da janela B achou o ciclo e cancelou o
comando da janela B, e a transação junto. A janela A foi liberada no instante em que a transação da
janela B falhou e soltou o pedido 2: o update dela terminou depois de 5369 ms, a maior parte disso
a espera de antes de a janela B sequer pedir. Desfaça as duas janelas.

O `HINT` aponta para o log, que tem a metade que o cliente não recebe, o comando que cada processo
estava rodando:

```
ana@vm:~$ sudo tail -n 8 /var/log/postgresql/postgresql-16-main.log
2026-10-10 17:13:37.345 -03 [8870] ana@market ERROR:  deadlock detected
2026-10-10 17:13:37.345 -03 [8870] ana@market DETAIL:  Process 8870 waits for ShareLock on transaction 1525089; blocked by process 8868.
	Process 8868 waits for ShareLock on transaction 1525090; blocked by process 8870.
	Process 8870: UPDATE orders SET status = 'shipped' WHERE id = 1;
	Process 8868: UPDATE orders SET status = 'shipped' WHERE id = 2;
2026-10-10 17:13:37.345 -03 [8870] ana@market HINT:  See server log for query details.
2026-10-10 17:13:37.345 -03 [8870] ana@market CONTEXT:  while updating tuple (16666,82) in relation "orders"
2026-10-10 17:13:37.345 -03 [8870] ana@market STATEMENT:  UPDATE orders SET status = 'shipped' WHERE id = 1;
```

Essa entrada de log é escrita para todo deadlock, sejam quais forem as configurações de log, e é o
primeiro lugar para olhar quando uma aplicação relata `deadlock detected`: os dois comandos, lado a
lado, costumam mostrar as duas ordens num relance. A aula 13 acrescenta a linha de log para esperas
que são longas mas não são deadlocks.

## O que a aplicação faz com isso

Um erro de deadlock é o **SQLSTATE 40P01**, e a resposta certa é **desfazer e rodar a transação
inteira de novo**. Tentar de novo só o comando que falhou não funciona: a transação já está
abortada. A aula 14 escreve o laço de nova tentativa, porque uma falha de serialização precisa
exatamente do mesmo.

Tentar de novo torna um deadlock inofensivo; não o torna raro. Numa tabela movimentada, duas
transações que tocam o mesmo par de linhas em ordens opostas entram em deadlock sempre que se
sobrepõem, e cada vez custa um segundo de espera e uma transação inteira jogada fora.

## A cura: uma ordem para todo mundo

Um ciclo precisa de duas transações pegando as mesmas travas em ordens diferentes. **Se toda
transação travar as linhas que vai mudar na mesma ordem, nenhum ciclo se forma**: quem pega a
primeira linha pega todas, e todo o resto espera na fila. A ordem fácil é a chave primária, pega de
saída com um `SELECT … ORDER BY id FOR UPDATE`. A janela A, que por acaso lista os ids como
`(2, 1)`:

```
market=# BEGIN;
BEGIN
Time: 0.441 ms

market=*# SELECT id FROM orders WHERE id IN (2, 1) ORDER BY id FOR UPDATE;
 id 
----
  1
  2
(2 rows)

Time: 2.020 ms
```

A janela B os lista do outro jeito e pede as mesmas travas:

```
market=# BEGIN;
BEGIN
Time: 0.354 ms

market=*# SELECT id FROM orders WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
```

A janela B está esperando o pedido 1, antes de travar qualquer coisa, então não segura nada de que
a janela A possa precisar. A janela A faz os dois updates, na ordem que o código dela quiser, e
confirma:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 0.854 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 0.476 ms

market=*# COMMIT;
COMMIT
Time: 1.211 ms
```

```
market=*# SELECT id FROM orders WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
 id 
----
  1
  2
(2 rows)

Time: 5471.529 ms (00:05.472)
```

**A janela B esperou 5472 ms e pegou as duas linhas. Nenhum deadlock, nenhum erro, nada jogado
fora.** O `ORDER BY id` é o conserto inteiro: a ordem da lista do `IN` não importa, porque as
linhas são travadas na ordem do resultado. Um `UPDATE … WHERE id IN (…)` sem um `SELECT` antes não
dá essa garantia, já que a ordem em que ele chega às linhas é a ordem em que o plano dele as ler.

Três hábitos saem daqui:

- **Trave o que vai mudar, numa ordem fixa, no começo** — pela chave primária, ou por qualquer regra
  que todo caminho do código siga.
- **Mantenha a transação curta**, para que a janela em que duas delas se sobrepõem seja pequena.
- **Trate o 40P01 mesmo assim**, porque algumas ordens não têm conserto: uma checagem de chave
  estrangeira trava uma linha pai que você nunca citou.

## Antes da aula 13

Esta aula mudou alguns pedidos: o pedido 1 está `shipped` e três pedidos ficaram `packing` de vez.
Feche todas as janelas e ponha o `market` de volta com `~/reset-market.sh`, como no fim da aula 11.
