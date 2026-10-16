---
title: Um armazenamento de coluna larga, o Cassandra
version: 1
---

O nome engana duas vezes. "Coluna larga" soa como uma tabela com muitíssimas colunas, e soa como o
armazenamento orientado a colunas dos motores analíticos, que guardam cada coluna de uma tabela no
seu próprio arquivo. **Não é nenhum dos dois.** Um armazenamento de coluna larga agrupa linhas em
partições por uma chave, mantém as linhas de uma partição juntas e ordenadas, e responde perguntas
sobre uma partição por vez. Uma partição pode crescer até milhares de linhas, e essa fileira de
linhas é o "largo" do nome.

## Um keyspace, uma tabela e o pedido 1001

No Cassandra um keyspace contém tabelas, e é onde se define o número de cópias. Com um nó só só pode
haver uma cópia, então o keyspace abaixo pede uma; a aula 17 trata de escolher mais.

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE order_lines_by_customer (customer text, ordered_at timestamp, sku text, order_id int, name text, qty int, unit_price decimal, PRIMARY KEY ((customer), ordered_at, sku));
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 'CB-012', 1001, 'USB-C cable', 2, 39.90);
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 'MS-204', 1001, 'Wireless mouse', 1, 189.00);
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-08-02 19:40:00-0300', 'KB-101', 987, 'Mechanical keyboard', 1, 349.90);
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 'MN-330', 1002, '27-inch monitor', 1, 1499.00);
cqlsh:shop> SELECT ordered_at, sku, order_id, qty, unit_price FROM order_lines_by_customer WHERE customer = 'ana@example.com';

 ordered_at                      | sku    | order_id | qty | unit_price
---------------------------------+--------+----------+-----+------------
 2026-08-02 22:40:00.000000+0000 | KB-101 |      987 |   1 |     349.90
 2026-09-14 13:22:00.000000+0000 | CB-012 |     1001 |   2 |      39.90
 2026-09-14 13:22:00.000000+0000 | MS-204 |     1001 |   1 |     189.00

(3 rows)
cqlsh:shop> SELECT customer, sku, unit_price FROM order_lines_by_customer WHERE unit_price > 500;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh:shop> SELECT customer, sku, unit_price FROM order_lines_by_customer WHERE unit_price > 500 ALLOW FILTERING;

 customer          | sku    | unit_price
-------------------+--------+------------
 bruno@example.com | MN-330 |    1499.00

(1 rows)
cqlsh:shop> exit
```

A chave primária é a linha importante do `CREATE TABLE`, e os parênteses carregam o projeto:

- **`(customer)` é a chave de partição.** Ela decide qual nó guarda as linhas, e toda linha de
  `ana@example.com` vive na mesma partição, nos mesmos nós.
- **`ordered_at, sku` são as colunas de clustering.** Elas decidem a ordem das linhas dentro da
  partição, e junto com a chave de partição tornam cada linha única.

Então o pedido 1001 da Ana são duas linhas, uma por item, e o pedido anterior dela, do teclado, é uma
terceira. O `SELECT` da partição dela devolveu as três **já ordenadas por data**, o teclado de agosto
primeiro, sem `ORDER BY`, porque é nessa ordem que estão guardadas. Os horários voltam em UTC: 10:22
em `-0300` é 13:22 em `+0000`.

## A pergunta para a qual a tabela não foi feita

As linhas com preço acima de 500 estão espalhadas por várias partições, e o único jeito de achá-las é
ler todas as partições. **O Cassandra se recusa a fazer isso a menos que mandem**, e a mensagem diz
por quê: a consulta "might involve data filtering and thus may have unpredictable performance". Com
`ALLOW FILTERING` ela roda, e com quatro linhas num nó é instantânea. Num cluster com milhões de
partições o mesmo comando lê todas elas, em todos os nós, para devolver um punhado.

A recusa é o projeto falando. Um banco relacional teria rodado a consulta e sido lento; o Cassandra
obriga você a dizer em voz alta que queria varrer. A resposta comum não é `ALLOW FILTERING`, e sim
**uma segunda tabela cuja chave de partição é a pergunta**, gravada junto com a primeira. A aula 3
projeta tabelas assim e a aula 4 as mantém em dia.

## Para que serve esta forma

Escritas no Cassandra são baratas e se espalham pelos nós segundo a chave de partição, e a leitura de
uma partição é uma fatia ordenada dos dados de um nó. Isso serve para dados gravados muito mais do que
lidos de jeitos novos: pedidos por cliente, leituras por sensor, eventos por conta. O total do pedido
1001 não está guardado em lugar nenhum desta tabela; somar as duas linhas é trabalho da aplicação, ou
de uma terceira coluna gravada junto com elas.

O Cassandra é o armazenamento de coluna larga que este curso opera. O ScyllaDB fala o mesmo CQL, e o
HBase e o Bigtable do Google são da mesma família com outras interfaces.
