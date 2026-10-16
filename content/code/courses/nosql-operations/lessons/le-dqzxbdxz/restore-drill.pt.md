---
title: O exercício de restore
version: 1
---

Um arquivo de backup prova que um comando de backup rodou. Não prova que os dados podem ser
trazidos de volta, por você, num dia ruim, num tempo que alguém aceitaria. **O único backup que
conta é um que já foi restaurado**, que é a aula 1 inteira de `db-reliability`. Vale aqui pelos mesmos
motivos: um dump sai vazio porque uma credencial estava errada, um arquivo é cortado por um disco
cheio, e um restore leva dez vezes mais do que alguém imaginou.

## Num servidor novo

O exercício usa um contêiner que nunca viu a loja, para que nada nele faça o restore parecer melhor
do que é. Inicie-o, espere um ou dois segundos até ele responder, copie o arquivo para dentro e
restaure:

```
ana@vm:~$ docker run -d --name mongo-restore --network nosql mongo:8.0
b96c9fd9230ac1b9e69ea7969d8b61068a8b34afa6f8041cfb4409ae33862d18
ana@vm:~$ docker cp shop.archive.gz mongo-restore:/tmp/shop.archive.gz
ana@vm:~$ time docker exec mongo-restore mongorestore --oplogReplay --gzip --archive=/tmp/shop.archive.gz
2026-10-10T20:15:36.244+0000	preparing collections to restore from
2026-10-10T20:15:36.246+0000	don't know what to do with subdirectory `shop`, skipping...
2026-10-10T20:15:36.246+0000	don't know what to do with subdirectory ``, skipping...
2026-10-10T20:15:36.246+0000	don't know what to do with subdirectory `admin`, skipping...
2026-10-10T20:15:36.286+0000	reading metadata for `shop.orders` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.286+0000	reading metadata for `shop.customers` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.286+0000	reading metadata for `shop.payments` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.286+0000	reading metadata for `shop.products` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.302+0000	restoring `shop.products` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.313+0000	finished restoring `shop.products` (4 documents, 0 failures)
2026-10-10T20:15:36.320+0000	restoring `shop.payments` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.340+0000	finished restoring `shop.payments` (119 documents, 0 failures)
2026-10-10T20:15:36.348+0000	restoring `shop.customers` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.360+0000	finished restoring `shop.customers` (5 documents, 0 failures)
2026-10-10T20:15:36.369+0000	restoring `shop.orders` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:37.618+0000	finished restoring `shop.orders` (100000 documents, 0 failures)
2026-10-10T20:15:37.618+0000	replaying oplog
2026-10-10T20:15:37.629+0000	applied 26 oplog entries
2026-10-10T20:15:37.629+0000	restoring indexes for collection `shop.orders` from metadata
2026-10-10T20:15:37.629+0000	index: &idx.IndexDocument{Options:bson.M{"name":"customer_1_placedAt_-1", "v":2}, Key:bson.D{bson.E{Key:"customer", Value:1}, bson.E{Key:"placedAt", Value:-1}}, PartialFilterExpression:(*bson.D)(nil)}
2026-10-10T20:15:37.629+0000	index: &idx.IndexDocument{Options:bson.M{"name":"sku_1", "v":2}, Key:bson.D{bson.E{Key:"sku", Value:1}}, PartialFilterExpression:(*bson.D)(nil)}
2026-10-10T20:15:37.629+0000	restoring indexes for collection `shop.customers` from metadata
2026-10-10T20:15:37.629+0000	index: &idx.IndexDocument{Options:bson.M{"name":"email_1", "unique":true, "v":2}, Key:bson.D{bson.E{Key:"email", Value:1}}, PartialFilterExpression:(*bson.D)(nil)}
2026-10-10T20:15:37.629+0000	no indexes to restore for collection `shop.payments`
2026-10-10T20:15:37.629+0000	no indexes to restore for collection `shop.products`
2026-10-10T20:15:37.934+0000	100128 document(s) restored successfully. 0 document(s) failed to restore.

real	0m1.924s
user	0m0.036s
sys	0m0.014s
ana@vm:~$ docker exec mongo-restore mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
payments 142 _id_
products 4 _id_
ana@vm:~$ docker exec mongo mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
payments 500 _id_
products 4 _id_
```

`--gzip` e `--archive` combinam com o jeito como o dump foi gravado. `--oplogReplay` aplica as 26
entradas que o dump capturou, depois das coleções e antes dos índices, e o log diz cada passo:
primeiro os documentos, depois `applied 26 oplog entries`, depois `restoring indexes`, uma linha por
definição de índice lida dos metadados. O restore inteiro levou 1,924 segundo.

## Conferindo, contra o original

Os dois últimos comandos rodam a mesma verificação no servidor restaurado e no original, e as linhas
são o veredito. Clientes, pedidos e produtos batem, contagem por contagem e índice por índice. **Os
pagamentos não batem, e não devem bater:** o restore tem 142, o original 500. O dump copiou 119
pagamentos, e reaplicar o oplog levou a coleção até o momento em que o dump terminou; os pagamentos
restantes foram gravados depois desse momento, e nenhum backup feito ali poderia contê-los.

É para isso que serve um exercício. "142 contra 500" é um fato que você quer ter descoberto numa
terça-feira à tarde: mede o que um restore perde, as escritas depois do último backup, e diz com que
frequência os backups precisam rodar para essa perda ser aceitável.

## O que um exercício registra

Um exercício termina quando alguém registrou quatro coisas, porque da próxima vez é isso que se
compara:

| | nesta aula |
|---|---|
| qual backup foi restaurado | o arquivo do `mongodump --oplog`, 810.350 bytes |
| quanto tempo o restore levou | 1,924 s |
| o que foi conferido | a contagem e os nomes de índice de cada coleção, contra a origem |
| o que não bateu, e por quê | `payments`, 142 contra 500: gravados depois do fim do dump |

Remova os dois servidores que o exercício e o snapshot iniciaram, e o volume em que o snapshot foi
desempacotado. Mantenha o `mongo` e o volume `mongo-data`: pará-lo devolve a memória à VM, e
`docker start mongo` traz a loja de volta com os dados, porque os dados moram no volume:

```sh
docker rm -f mongo-copy mongo-restore
docker volume rm mongo-copy
docker stop mongo
```
