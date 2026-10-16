---
title: Um pedido, duas tabelas, no Cassandra
version: 1
---

No Cassandra a cópia não é um campo, é **uma tabela inteira**. A aula 3 projetou uma tabela por
pergunta, e duas perguntas sobre pedidos, "mostrar o pedido 1001" e "os pedidos da Ana, do mais
novo", partem de chaves diferentes. Então todo pedido é gravado duas vezes: uma em `orders_by_id`,
particionada pelo número do pedido, e uma em `orders_by_customer`, particionada pelo cliente.

## Um batch registrado

Dois `INSERT` separados funcionariam até o dia em que a aplicação morre entre eles, e então uma
tabela tem o pedido e a outra não. Um **batch registrado** (logged batch) os agrupa:

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE orders_by_id (order_id int PRIMARY KEY, customer text, ordered_at timestamp, total decimal);
cqlsh:shop> CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at, order_id)) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);
cqlsh:shop> BEGIN BATCH INSERT INTO orders_by_id (order_id, customer, ordered_at, total) VALUES (1001, 'ana@example.com', '2026-09-14 10:22:00-0300', 268.80); INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 1001, 268.80); APPLY BATCH;
cqlsh:shop> SELECT * FROM orders_by_id WHERE order_id = 1001;

 order_id | customer        | ordered_at                      | total
----------+-----------------+---------------------------------+--------
     1001 | ana@example.com | 2026-09-14 13:22:00.000000+0000 | 268.80

(1 rows)
cqlsh:shop> SELECT * FROM orders_by_customer WHERE customer = 'ana@example.com';

 customer        | ordered_at                      | order_id | total
-----------------+---------------------------------+----------+--------
 ana@example.com | 2026-09-14 13:22:00.000000+0000 |     1001 | 268.80

(1 rows)
cqlsh:shop> exit
```

`BEGIN BATCH ... APPLY BATCH` envolveu os dois inserts, e cada tabela respondeu a sua pergunta com o
mesmo pedido. O batch foi digitado numa linha só aqui; em várias linhas funciona igual.

## O que um batch registrado promete

O coordenador, o nó que recebeu o batch, primeiro grava o batch inteiro num **batch log** em outros
nós, depois aplica cada comando, depois apaga a entrada do log. Se o coordenador morre no meio, outro
nó acha a entrada no log e a reaplica. Então a promessa é:

- **tudo ou nada, em algum momento.** Ou todo comando do batch é aplicado, ou, se o coordenador
  falhou, o batch log aplica o resto depois.

E o que ele não promete, que importa tanto quanto:

- **nenhum isolamento.** Um leitor pode ver o pedido em `orders_by_id` antes de ele aparecer em
  `orders_by_customer`. As duas escritas não são um instante só.
- **nenhuma velocidade.** Gravar o batch log antes é uma rodada extra de escritas, então um batch
  registrado é mais lento que os dois inserts sozinhos. Um batch é ferramenta de atomicidade entre
  tabelas, nunca de carregar muitas linhas mais rápido.
- **nenhum rollback.** Se um comando é inválido, o batch inteiro é recusado de saída; uma vez aceito,
  ele é aplicado, não desfeito.

Num nó só, com uma cópia, como aqui, não há um segundo nó para assumir no lugar de um coordenador que
falhou, então o laboratório não consegue mostrar a reaplicação acontecendo. **Esta aula a descreve e
não a demonstra**; a aula 17 tem o cluster de três nós onde um coordenador pode falhar.

## Um batch não é uma transação

A diferença aparece no momento em que uma escrita precisa ser condicional. O pedido do Bruno só deve
ser inserido se o pedido 1002 ainda não existir, nas duas tabelas:

```
ana@vm:~$ docker exec -it cassandra cqlsh -k shop
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh:shop> BEGIN BATCH INSERT INTO orders_by_id (order_id, customer, ordered_at, total) VALUES (1002, 'bruno@example.com', '2026-09-15 14:05:00-0300', 1499.00) IF NOT EXISTS; INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 1002, 1499.00) IF NOT EXISTS; APPLY BATCH;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Batch with conditions cannot span multiple tables"
cqlsh:shop> exit
```

`Batch with conditions cannot span multiple tables`. Uma condição, `IF NOT EXISTS`, é uma lightweight
transaction, e o Cassandra só consegue rodar uma contra uma única partição de uma única tabela; a
aula 17 mostra quanto ela custa. Então "inserir este pedido exatamente uma vez, nos dois lugares" são
dois passos: um insert condicional na tabela dona da identidade, `orders_by_id`, e depois, se deu
certo, um batch ou uma escrita comum na cópia.

A forma geral vale guardar: **uma tabela é a fonte da verdade de um fato, e as outras são cópias
gravadas depois dela.** Quando discordam, a fonte vence e a cópia é regravada a partir dela.
