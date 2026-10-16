---
title: Repeatable read, e o erro no lugar da perda
version: 1
---

O `REPEATABLE READ` muda uma coisa no que uma transação vê, e a mudança tem uma consequência que a
maioria das pessoas conhece primeiro como mensagem de erro. **A transação tira um snapshot no
primeiro comando, e todo comando dela lê desse snapshot.** Nada que outra pessoa confirme depois
fica visível para ela, quantas vezes ela perguntar.

A expectativa comum é que o nível mais alto faça o segundo escritor esperar e depois fazer a coisa
certa. Ele não sai do conflito esperando. **Se uma transação `REPEATABLE READ` tenta mudar uma linha
que outra pessoa mudou depois do snapshot dela, ela falha**, e a aplicação precisa rodá-la de novo.

## Read committed vê a mudança

Primeiro o padrão, para comparar. Na janela A, comece uma transação e leia o preço do produto 2:

```
market=# BEGIN;
BEGIN
Time: 0.340 ms

market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       21990
(1 row)

Time: 1.346 ms
```

Na janela B, aumente-o em 100, fora de qualquer transação explícita, para que confirme na hora:

```
market=# UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
UPDATE 1
Time: 2.626 ms
```

De volta à janela A, mesma transação, mesma consulta:

```
market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       22090
(1 row)

Time: 0.521 ms

market=*# COMMIT;
COMMIT
Time: 0.499 ms
```

**21990, depois 22090**, dentro de uma transação. Essa é a **leitura não repetível** que dá nome ao
nível: em `READ COMMITTED` cada comando tira uma visão nova, então um relatório que lê um total numa
consulta e o detalhe na seguinte pode descobrir que os dois não batem.

## Repeatable read não vê

Agora a janela A começa uma transação `REPEATABLE READ`:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.372 ms

market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       22090
(1 row)

Time: 0.614 ms
```

A janela B aumenta o preço de novo:

```
market=# UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
UPDATE 1
Time: 2.034 ms
```

E a janela A o lê, e então tenta aumentá-lo também:

```
market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       22090
(1 row)

Time: 0.431 ms

market=*# UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
ERROR:  could not serialize access due to concurrent update
Time: 0.856 ms

market=!# ROLLBACK;
ROLLBACK
Time: 0.381 ms
```

O segundo `SELECT` ainda diz **22090**: o snapshot foi tirado na primeira consulta da janela A, e o
commit da janela B veio depois. É isso que torna o nível útil para relatórios, exportações e tudo o
que lê várias tabelas e precisa que elas concordem entre si.

Então o `UPDATE` falhou com **`could not serialize access due to concurrent update`**. A janela A
ia somar 100 a uma linha cuja versão atual ela não consegue ver. Em `READ COMMITTED` o update teria
esperado, relido a linha e seguido, como a seção 02 desta aula mostrou; em `REPEATABLE READ` o
servidor recusa, porque seguir seria escrever por cima de uma mudança que a transação nunca viu, o
que é exatamente a atualização perdida. A transação agora está falha, e a única coisa a fazer com
ela é `ROLLBACK`.

**O erro é a proteção.** A aplicação recebe o SQLSTATE **40001**, desfaz e roda a transação
inteira de novo desde o começo, agora com um snapshot que inclui a mudança da janela B.

## A carga de novo

O mesmo `price-bump.sql`, dez segundos, oito clientes, com toda transação em `REPEATABLE READ`. O
pgbench não tem opção para o nível, então ele é definido para cada conexão pelo `PGOPTIONS`, que
passa uma configuração ao servidor quando a conexão abre; a barra invertida impede que o espaço em
`repeatable read` termine o valor:

```
market=# SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \gset
Time: 1.602 ms

market=# \! PGOPTIONS='-c default_transaction_isolation=repeatable\ read' pgbench -n -c 8 -j 4 -T 10  -f ~/workload/price-bump.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/price-bump.sql
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 49741
number of failed transactions: 28848 (36.707%)
latency average = 1.018 ms (including failures)
initial connection time = 11.943 ms
tps = 4974.825330 (without initial connection time)

market=# SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
 cents_added 
-------------
       49741
(1 row)

Time: 0.603 ms
```

Leia os três números juntos. **49.741 transações confirmadas, e os preços subiram exatamente 49.741
centavos: nada se perdeu.** E **28.848 transações, 36,7%, falharam**: cada uma era uma leitura
seguida de escrita que perdeu a corrida pela linha e foi recusada em vez de poder sobrescrever. O
pgbench foi instruído a tentar cada uma uma vez, então essas falhas só são contadas; uma aplicação
que não fizesse nada com o erro mostraria um erro aos usuários em um pedido a cada três.

Então o nível troca uma resposta errada e silenciosa por uma falha barulhenta. **Essa é a troca
certa**, e ela só fica completa quando alguma coisa tenta de novo, que é a seção 05 desta aula.

## O que ele não pega

O `REPEATABLE READ` se recusa a sobrescrever uma linha mudada depois do snapshot. Ele não percebe
duas transações que leem algo cada uma, decidem a partir disso e então escrevem linhas
**diferentes**. Nenhuma sobrescreveu a outra, então nenhuma é recusada, e a regra que cada uma
checou ainda pode terminar quebrada. A próxima seção monta esse caso com dois pedidos.
