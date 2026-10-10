---
title: Escreva a consulta primeiro
version: 1
---

Num banco relacional você modela os dados e depois escreve as consultas que quiser contra eles; um
índice ou um join cobre as que você não previu. **O Cassandra inverte a ordem.** Você lista as
consultas primeiro, e cada tabela é a resposta a uma delas, com o formato que faz a consulta nomear
uma partição e ler uma fatia. A aula 3 defendeu isso para todos os bancos do curso. Aqui o próprio
banco impõe, e vale a pena ver as recusas por inteiro.

## As recusas

`orders_by_customer` responde "os pedidos de um cliente, do mais novo para o mais antigo". Pergunte
qualquer outra coisa:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE ordered_at >= '2026-04-01';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer ORDER BY ordered_at;
InvalidRequest: Error from server: code=2200 [Invalid query] message="ORDER BY is only supported when the partition key is restricted by an EQ or an IN."
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped' ALLOW FILTERING;

 order_id | customer
----------+-------------------
   A-1007 | bruno@example.com
   A-1006 |   ana@example.com
   A-1005 | diego@example.com

(3 rows)
cqlsh> exit
```

Três recusas, e são três faces de uma regra só. Um intervalo em `ordered_at` sem o cliente, e uma
condição em `status`, teriam cada um de ler **todas as partições de todos os nós** para achar as
linhas, então o Cassandra recusa com a frase sobre `ALLOW FILTERING`. Um `ORDER BY` sem partição
nomeada não tem uma partição ordenada para ler em ordem, e é recusado por isso.

`ALLOW FILTERING` faz a consulta rodar, e ela deu as três linhas certas. **A recusa não era sobre
correção.** Era sobre custo, e o custo é invisível com oito pedidos. O tracing o mostra. Cada comando
abaixo pede ao `cqlsh` que rastreie uma consulta e conta, com `grep` e `uniq -c`, as linhas do
rastreio que dizem como o coordenador, o `c1`, chegou aos dados:

```
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE customer = 'ana@example.com';" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Executing single-partition query on orders_by_customer
      1 Sending READ_REQ message to /172.18.0.3:7000
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE status = 'shipped' ALLOW FILTERING;" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
     13 Sending RANGE_REQ message to /172.18.0.3:7000
     17 Sending RANGE_REQ message to /172.18.0.4:7000
      1 Submitting range requests on 49 ranges
```

A consulta que nomeia a Ana é **uma leitura de partição única**, enviada para `172.18.0.3`, que é o
`c2`, o nó que o `getendpoints` apontou. A consulta com filtro dividiu o anel inteiro em **49
intervalos** e mandou 13 pedidos de intervalo ao `c2` e 17 ao `c3`; o resto leu localmente. Com
oito pedidos, cada consulta achou quase nada. Com oitenta milhões, cada um desses pedidos varre a
sua parte da tabela, e o custo da consulta cresce com o tamanho da tabela, não com o tamanho da
resposta. `ALLOW FILTERING` é aceitável quando você sabe que a partição é pequena ou a tabela é
minúscula. No caminho principal de uma aplicação, é a consulta lenta do ano que vem.

## Um índice, e o SAI em particular

O Cassandra 5.0 traz o **Storage-Attached Indexing**, SAI, um índice secundário guardado ao lado de
cada SSTable em vez de numa tabela escondida própria. Ele torna `status = 'shipped'` uma consulta
legal:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE INDEX orders_status ON shop.orders_by_customer (status) USING 'sai';
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped';

 order_id | customer
----------+-------------------
   A-1007 | bruno@example.com
   A-1006 |   ana@example.com
   A-1005 | diego@example.com

(3 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE status = 'shipped';" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
      3 Executing single-partition query on orders_by_customer
     13 Sending RANGE_REQ message to /172.18.0.3:7000
     17 Sending RANGE_REQ message to /172.18.0.4:7000
      1 Submitting range requests on 49 ranges
```

A consulta agora roda sem `ALLOW FILTERING`, e cada nó acha as linhas que batem pelo índice em vez
de varrer: as três leituras de partição única no rastreio são os três pedidos que ele achou. **Mas o
coordenador ainda dividiu o anel em 49 intervalos e ainda perguntou a todos os nós.** Um índice
secundário é local a cada nó, então uma consulta por `status` não tem como saber de antemão qual nó
guarda um pedido enviado; ela precisa perguntar a todos. O SAI barateia a parte de cada nó. Não muda
quantos nós são consultados, e é por isso que não muda a regra de modelagem.

O SAI é a ferramenta certa para uma consulta ocasional, ou que sempre nomeia também a chave de
partição, como "os pedidos enviados da Ana", em que o índice estreita as linhas dentro de uma
partição. É a fundação errada para a consulta mais movimentada de uma aplicação, que deve ler uma
partição.

## Uma tabela por consulta

O depósito faz uma pergunta diferente da página da conta: "todos os pedidos feitos num dado dia", na
ordem em que chegaram. Isso é uma partição por dia, ordenada pelo horário. Salve isto como
`days.cql`:

```sql
CREATE TABLE shop.orders_by_day (
  day        date,
  ordered_at timestamp,
  order_id   text,
  customer   text,
  total      decimal,
  PRIMARY KEY (day, ordered_at, order_id)
);

INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-02', '2026-03-02 13:15:00+0000', 'A-1001', 'ana@example.com',    349.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-02', '2026-03-02 15:40:00+0000', 'A-1002', 'bruno@example.com', 1499.00);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-02', '2026-03-02 19:05:00+0000', 'A-1003', 'carla@example.com',   39.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-20', '2026-03-20 00:02:00+0000', 'A-1004', 'ana@example.com',    189.00);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-20', '2026-03-20 11:20:00+0000', 'A-1005', 'diego@example.com',  349.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-04-08', '2026-04-08 12:30:00+0000', 'A-1006', 'ana@example.com',   1499.00);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-04-08', '2026-04-08 14:10:00+0000', 'A-1007', 'bruno@example.com',   39.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-04-09', '2026-04-09 09:45:00+0000', 'A-1008', 'elisa@example.com',  189.00);
```

```
ana@vm:~$ docker exec -i c1 cqlsh < days.cql
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT ordered_at, order_id, customer, total FROM shop.orders_by_day WHERE day = '2026-03-02';

 ordered_at                      | order_id | customer          | total
---------------------------------+----------+-------------------+---------
 2026-03-02 13:15:00.000000+0000 |   A-1001 |   ana@example.com |  349.90
 2026-03-02 15:40:00.000000+0000 |   A-1002 | bruno@example.com | 1499.00
 2026-03-02 19:05:00.000000+0000 |   A-1003 | carla@example.com |   39.90

(3 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_day WHERE day = '2026-03-02';" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Executing single-partition query on orders_by_day
```

**Uma partição, e desta vez o rastreio não tem linha `Sending` nenhuma**: a partição de
`2026-03-02` mora no `c1`, o próprio coordenador, então a leitura nem saiu do nó. Os mesmos oito
pedidos agora estão guardados duas vezes, uma por pergunta, e isso é o projeto, não uma concessão. O
preço é que todo pedido feito tem de ser gravado nas duas tabelas, o que a aula 4 chamou de gravar o
mesmo dado duas vezes de propósito e a aula 5 mostrou que pode deixar as duas cópias discordando por
um instante.

O método, então, como uma lista que você aplica a qualquer funcionalidade nova:

1. Anote cada consulta que a tela ou o job vai rodar, com seus parâmetros.
2. Para cada uma, o parâmetro que sempre vem com `=` vira a chave de partição.
3. Aquilo por que a consulta ordena ou recorta vira as colunas de clustering, nessa ordem.
4. Acrescente o que torna uma linha única como última coluna de clustering.
5. Confira que a partição não pode crescer sem limite, que é a próxima seção.
