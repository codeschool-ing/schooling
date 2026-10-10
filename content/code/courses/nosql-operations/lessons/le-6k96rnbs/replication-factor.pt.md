---
title: Três cópias de cada partição
version: 1
---

A aula 16 manteve uma cópia de cada partição, então o nó dono de um token era o único lugar onde
suas linhas existiam. Pare esse nó e essas linhas somem até ele voltar. **O fator de replicação é o
número de cópias, e ele pertence ao keyspace, não à tabela nem à consulta.** Esta aula o sobe para
três, a escolha habitual em produção, e passa o resto do tempo no outro número, o que cada consulta
escolhe: quantas dessas cópias precisam responder.

Esta aula precisa dos três nós da aula 16, rodando, com o keyspace `shop`. Se você os removeu, o laço
da aula 16 os monta de novo em poucos minutos, e o `CREATE KEYSPACE shop` do `orders.cql` dela cria o
keyspace.

## Subindo o número, e o aviso que vem junto

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> ALTER KEYSPACE shop WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3};

Warnings :
When increasing replication factor you need to run a full (-full) repair to distribute the data.

cqlsh> exit
ana@vm:~$ docker exec c1 nodetool status shop
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  172.18.0.3  80.02 KiB   16      100.0%            4e6c6943-bad2-4a89-a579-c61d93c795b4  rack1
UN  172.18.0.2  114.69 KiB  16      100.0%            4f53c005-bbb3-41b0-85b5-e123a1c42d23  rack1
UN  172.18.0.4  119.66 KiB  16      100.0%            1480b2b6-2542-4292-8efe-6389e94e299a  rack1
```

`NetworkTopologyStrategy` recebe um número de cópias **por data center**, pelo nome que cada nó deu a
si mesmo com `CASSANDRA_DC`: aqui, três cópias em `dc1`. Com três nós e três cópias, todo nó guarda
toda partição, que é o que `Owns (effective)` diz agora, `100.0%` cada.

**O aviso é a linha importante.** Mudar o fator de replicação muda onde o Cassandra procura os dados,
e nada mais. Não copia as linhas que já existem. Os pedidos da aula 16 foram gravados quando cada um
tinha uma cópia, e depois deste `ALTER` dois dos três nós que agora deveriam guardar cada partição
nunca a viram. Uma leitura que por acaso pergunte só a um desses nós não acha nada. O repair completo
que o aviso pede é o que as copia, e a aula 19 o roda.

`SimpleStrategy`, que a aula 2 usou num nó só, ignora data centers e põe as cópias nos próximos nós do
anel. Serve para um único data center num laboratório; o motivo para aprender a outra é que um
cluster que ganha um segundo data center precisa estar nela, e trocar de estratégia depois é outro
`ALTER` seguido de outro repair.

## Uma tabela para esta aula

A pergunta que a aula 1 fez sobre duas cidades e um monitor é a que esta aula responde na prática,
então a tabela é de estoque:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.stock (sku text PRIMARY KEY, name text, units int);
cqlsh> CONSISTENCY
Current consistency level is ONE.
cqlsh> CONSISTENCY ALL
Consistency level set to ALL.
cqlsh> INSERT INTO shop.stock (sku, name, units) VALUES ('MN-330', '27-inch monitor', 1);
cqlsh> SELECT * FROM shop.stock WHERE sku = 'MN-330';

 sku    | name            | units
--------+-----------------+-------
 MN-330 | 27-inch monitor |     1

(1 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 nodetool getendpoints shop stock MN-330
172.18.0.2
172.18.0.4
172.18.0.3
```

Duas linhas antes do `INSERT` importam. `CONSISTENCY` sem argumento mostra o nível atual, e **o
`cqlsh` começa em `ONE`**: se você não disser nada, a resposta de uma réplica basta. `CONSISTENCY ALL`
o muda nesta sessão, e a escrita seguinte foi confirmada pelas três. Depois o `getendpoints` lista
três endereços para `MN-330`: os três nós.

Três cópias mudam o que pode falhar. **Com uma cópia, qualquer nó caído é algum dado indisponível.
Com três, um nó pode cair e toda partição ainda tem duas cópias de pé**, e se uma consulta dá certo
passa a depender de quantas cópias ela exige ouvir. Esse é o nível de consistência, e a próxima seção
para nós para vê-lo decidir.
