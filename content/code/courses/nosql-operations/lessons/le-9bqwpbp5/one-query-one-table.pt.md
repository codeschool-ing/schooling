---
title: Uma consulta, uma tabela, no Cassandra
version: 1
---

No Cassandra o método desta aula deixa de ser conselho. **Uma consulta precisa nomear uma partição**,
então uma tabela só serve para as perguntas cuja chave de partição a aplicação já tem, e o costume é
projetar uma tabela por pergunta e dar a ela o nome da pergunta. A linha 4 da lista, "meus pedidos,
do mais novo, dez por vez", vira `orders_by_customer`.

## Da pergunta à chave

Leia a linha da esquerda para a direita e a chave primária sai dela:

- a aplicação sabe **quem é a cliente**, então a cliente é a chave de partição, e todos os pedidos
  dela moram juntos;
- ela os quer **do mais novo**, então a data do pedido é uma coluna de clustering, guardada em ordem
  decrescente;
- ela os quer **dez por vez**, então a consulta é um `LIMIT` numa partição que já está em ordem.

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at)) WITH CLUSTERING ORDER BY (ordered_at DESC);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-08-02 19:40:00-0300', 987, 349.90);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 1001, 268.80);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1013, 1499.00);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 1002, 1499.00);
cqlsh:shop> SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com' LIMIT 2;

 ordered_at                      | order_id | total
---------------------------------+----------+---------
 2026-10-03 12:15:00.000000+0000 |     1013 | 1499.00
 2026-09-14 13:22:00.000000+0000 |     1001 |  268.80

(2 rows)
cqlsh:shop> SELECT customer, order_id FROM orders_by_customer ORDER BY ordered_at DESC LIMIT 3;
InvalidRequest: Error from server: code=2200 [Invalid query] message="ORDER BY is only supported when the partition key is restricted by an EQ or an IN."
cqlsh:shop> exit
```

`WITH CLUSTERING ORDER BY (ordered_at DESC)` é a parte do projeto que responde "do mais novo". As
linhas da partição da Ana estão guardadas com o pedido de outubro no topo, então o `LIMIT 2` pegou as
duas primeiras e parou. Nada foi ordenado quando a consulta rodou, e a partição do Bruno nem foi
aberta:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 215\" role=\"img\" aria-label=\"Duas partições de orders_by_customer. A partição da Ana guarda os três pedidos dela do mais novo ao mais velho: 1013 em outubro, 1001 em setembro, 987 em agosto. Uma consulta que nomeia a Ana com LIMIT 2 lê as duas primeiras linhas dessa partição e para. A partição do Bruno, com o pedido 1002, nunca é lida.\"><defs><marker id=\"obc3-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição</text><rect x=\"30\" y=\"32\" width=\"240\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ana@example.com</text><rect x=\"42\" y=\"66\" width=\"216\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-10-03</text><text x=\"150\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1013</text><text x=\"248\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1499.00</text><rect x=\"42\" y=\"108\" width=\"216\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-09-14</text><text x=\"150\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1001</text><text x=\"248\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">268.80</text><rect x=\"42\" y=\"150\" width=\"216\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-08-02</text><text x=\"150\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">987</text><text x=\"248\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">349.90</text><line x1=\"290\" y1=\"160\" x2=\"290\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#obc3-ah-paper-dim)\"></line><text x=\"298\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais novo</text><text x=\"298\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais velho</text><line x1=\"360\" y1=\"66\" x2=\"372\" y2=\"66\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"372\" y1=\"66\" x2=\"372\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"140\" x2=\"372\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"380\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o LIMIT 2 lê estas</text><text x=\"580\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição</text><rect x=\"480\" y=\"32\" width=\"200\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"580\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bruno@example.com</text><rect x=\"492\" y=\"66\" width=\"176\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"502\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-09-15</text><text x=\"658\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1002</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca lida</text></svg>", "caption": "\"Meus pedidos\" é o topo de uma partição. As linhas já estão na ordem em que a página as mostra, então a consulta lê duas linhas e não toca em mais nada."}
```

O segundo `SELECT` faz a pergunta para a qual esta tabela não foi projetada, os pedidos de todos os
clientes do mais novo, e o Cassandra a recusa: `ORDER BY is only supported when the partition key is
restricted by an EQ or an IN`. **A ordem existe dentro de uma partição e em nenhum outro lugar.**
Ordenar entre partições exigiria ler todas, em todos os nós, que é o tipo de pergunta da linha 6, e
ela precisa de outra estrutura.

## A chave que perde um pedido

O projeto acima tem um defeito que nenhum teste com três pedidos arrumados mostra. Em 3 de outubro a
Ana faz um segundo pedido no mesmo instante do monitor, um cabo comprado de outra aba, e a loja o
grava:

```
ana@vm:~$ docker exec -it cassandra cqlsh -k shop
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1014, 39.90);
cqlsh:shop> SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com';

 ordered_at                      | order_id | total
---------------------------------+----------+--------
 2026-10-03 12:15:00.000000+0000 |     1014 |  39.90
 2026-09-14 13:22:00.000000+0000 |     1001 | 268.80
 2026-08-02 22:40:00.000000+0000 |      987 | 349.90

(3 rows)
cqlsh:shop> DROP TABLE orders_by_customer;
cqlsh:shop> CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at, order_id)) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1013, 1499.00);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1014, 39.90);
cqlsh:shop> SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com';

 ordered_at                      | order_id | total
---------------------------------+----------+---------
 2026-10-03 12:15:00.000000+0000 |     1013 | 1499.00
 2026-10-03 12:15:00.000000+0000 |     1014 |   39.90

(2 rows)
cqlsh:shop> exit
```

O primeiro `SELECT` mostra três linhas, não quatro. **O pedido 1013, o monitor, sumiu**, substituído
pelo 1014 sem erro nenhum. Uma chave primária no Cassandra é a identidade de uma linha, e um `INSERT`
para uma chave que já existe a sobrescreve. Não há verificação de chave duplicada, porque verificar
exigiria ler antes de toda escrita, e o caminho de escrita foi feito justamente para evitar isso. Dois
pedidos com a mesma cliente e o mesmo horário tinham a mesma chave.

A correção é fazer a chave dizer o que torna uma linha única. Com `order_id` acrescentado como
segunda coluna de clustering, a partição continua ordenada por data, do mais novo, e dois pedidos no
mesmo instante são duas linhas, como mostra o último `SELECT`. Mudar uma chave primária significa uma
tabela nova, e é por isso que o `DROP TABLE` e o `CREATE TABLE` estão ali; numa tabela com dados de
verdade, significa copiar todas as linhas para a nova, o assunto da aula 4.

**A regra a guardar**: a chave de partição é o que a consulta nomeia, as colunas de clustering são a
ordem que ela quer, e a chave primária inteira é o que torna uma linha diferente de todas as outras.
A aula 16 volta às três com um cluster por baixo.
