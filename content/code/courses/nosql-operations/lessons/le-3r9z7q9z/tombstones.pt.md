---
title: Um delete é uma escrita
version: 1
---

Como as SSTables nunca mudam, um `DELETE` não pode tirar uma linha do arquivo que a guarda. **Ele grava
um marcador, uma lápide (tombstone), num arquivo mais novo, dizendo "esta linha está apagada a partir
deste timestamp".** Uma leitura que encontra a linha antiga e a lápide fica com a mais nova, a lápide,
e não devolve nada. Os bytes da linha continuam no disco até a compactação juntar os dois arquivos.

## O marcador no disco

Apague o teclado da cesta da Ana, faça o flush e despeje a SSTable nova:

```
ana@vm:~$ docker exec c1 cqlsh -e "DELETE FROM shop.baskets WHERE customer = 'ana@example.com' AND sku = 'KB-101';"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"
nb-4-big-Data.db
nb-5-big-Data.db
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/baskets-*/nb-5-big-Data.db"
[
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "ana@example.com" ],
      "position" : 29
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 29,
        "clustering" : [ "KB-101" ],
        "deletion_info" : { "marked_deleted" : "2026-10-10T19:59:03.455773Z", "local_delete_time" : "2026-10-10T19:59:03Z" },
        "cells" : [ ]
      }
    ]
  }
]
```

O `nb-5` guarda **uma linha sem células e com um `deletion_info`**: a hora em que foi marcada como
apagada e a hora local do delete. Isso é a lápide inteira. O teclado com quantidade 1 continua no
`nb-4`, intocado; os dois arquivos juntos querem dizer "apagado". Um delete de uma célula só, de uma
partição inteira ou de um intervalo de chaves de clustering grava o mesmo tipo de marcador nessa
escala.

## Uma fila feita de deletes

As lápides machucam é em quantidade. O caso clássico é uma tabela usada como **fila**: um job insere
itens de trabalho numa partição e um consumidor apaga cada um depois de tratá-lo. Aqui ela está com
1500 e-mails a enviar, 1499 já enviados. Os dois arquivos de comandos são escritos por dois laços de
shell:

```sh
for i in $(seq 1 1500); do echo "INSERT INTO shop.outbox (queue, id, body) VALUES ('emails', $i, 'order confirmation');"; done > fill.cql
for i in $(seq 1 1499); do echo "DELETE FROM shop.outbox WHERE queue = 'emails' AND id = $i;"; done > drain.cql
```

```
ana@vm:~$ docker exec c1 cqlsh -e "CREATE TABLE shop.outbox (queue text, id int, body text, PRIMARY KEY (queue, id));"
ana@vm:~$ for i in $(seq 1 1500); do echo "INSERT INTO shop.outbox (queue, id, body) VALUES ('emails', $i, 'order confirmation');"; done > fill.cql
for i in $(seq 1 1499); do echo "DELETE FROM shop.outbox WHERE queue = 'emails' AND id = $i;"; done > drain.cql
ana@vm:~$ wc -l fill.cql drain.cql
  1500 fill.cql
  1499 drain.cql
  2999 total
ana@vm:~$ docker exec -i c1 cqlsh < fill.cql
ana@vm:~$ docker exec -i c1 cqlsh < drain.cql
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT id, body FROM shop.outbox WHERE queue = 'emails';

 id   | body
------+--------------------
 1500 | order confirmation

(1 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT id FROM shop.outbox WHERE queue = 'emails';" | grep -oE 'Read [0-9]+ live rows and [0-9]+ tombstone cells'
Read 0 live rows and 0 tombstone cells
Read 1 live rows and 1499 tombstone cells
Read 1 live rows and 1499 tombstone cells
ana@vm:~$ docker exec c1 grep -E "^tombstone_(warn|failure)_threshold" /etc/cassandra/cassandra.yaml
tombstone_warn_threshold: 1000
tombstone_failure_threshold: 100000
```

O `SELECT` devolveu uma linha, o que está certo, e parece barato. **O rastreio mostra quanto custou:
as réplicas que leram a partição leram cada uma 1 linha viva e passaram por cima de 1499 células de
lápide para achá-la.** A partição da fila guarda o histórico de 1500 linhas para uma linha de
resposta, e cada consulta à fila paga isso de novo até a compactação poder descartar as lápides, o
que, a próxima seção explica, leva pelo menos `gc_grace_seconds`. A terceira linha do rastreio, uma
leitura que não achou nada, faz parte do mesmo pedido; o rastreio não diz mais nada sobre ela.

O último comando mostra os dois limites que protegem contra isso. Uma leitura que encontra **mais de
1000 lápides** é registrada como aviso, com a consulta e a partição; uma leitura que encontra **mais de
100000** é abortada com erro, porque a essa altura o nó gastaria a memória com marcadores de dados que
não existem mais. Uma partição que passa do primeiro número é um problema de modelagem, e as correções
habituais são as que a aula 16 deu para tamanho: um balde de tempo na chave de partição, para as
partições velhas deixarem de ser lidas, ou um projeto em que o consumidor lembra até onde chegou em
vez de apagar o que tratou.

Então deletes não são de graça no Cassandra. São escritas, são lidos, e ficam por um tempo mínimo que
a próxima seção explica.
