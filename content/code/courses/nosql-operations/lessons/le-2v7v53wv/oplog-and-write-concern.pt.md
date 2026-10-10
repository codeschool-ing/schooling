---
title: O oplog, e quando uma escrita conta como escrita
version: 1
---

O palpite óbvio é que os secundários copiam os arquivos de dados do primário. Não copiam. **Um
secundário copia operações**: cada mudança que o primário faz é gravada, na mesma transação de
armazenamento, como uma entrada numa coleção chamada `oplog.rs` no banco `local`, e cada secundário
busca essas entradas e as aplica em ordem. Insira um produto e veja o que ele deixou para trás:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") })
{ acknowledged: true, insertedId: 'KB-101' }
rs0 [direct: primary] shop> db.getSiblingDB("local").oplog.rs.find({ ns: "shop.products" }, { op: 1, ns: 1, o: 1, ts: 1, wall: 1 }).sort({ $natural: -1 }).limit(1)
[
  {
    op: 'i',
    ns: 'shop.products',
    o: {
      _id: 'KB-101',
      name: 'Mechanical keyboard',
      price: Decimal128('349.90')
    },
    ts: Timestamp({ t: 1791618877, i: 2 }),
    wall: ISODate('2026-10-10T07:54:37.170Z')
  }
]
rs0 [direct: primary] shop> db.adminCommand({ getDefaultRWConcern: 1 }).defaultWriteConcern
{ w: 'majority', wtimeout: 0 }
rs0 [direct: primary] shop> db.adminCommand({ getDefaultRWConcern: 1 }).defaultWriteConcernSource
implicit
rs0 [direct: primary] shop> exit
```

`op: 'i'` é um insert, `ns` é o banco e a coleção, e `o` é o documento como foi gravado. `ts` é a
posição da entrada no log: segundos desde 1970 e um contador das operações dentro de um mesmo
segundo, e todo membro o usa para dizer até onde chegou. `wall` é a hora do relógio, em UTC. A
projeção no `find` guarda cinco campos; a entrada real tem mais, sobre sessões, novas tentativas e
versões, que esta aula não usa.

O oplog é uma **coleção limitada** (capped): tem tamanho fixo, e as entradas mais antigas são
sobrescritas conforme chegam novas. Um secundário que fica mais atrasado que a entrada mais antiga
ainda presente não consegue mais se atualizar pelo log e precisa copiar o conjunto de dados inteiro
de novo. Quantas horas o log cobre é, portanto, um número que vale a pena conhecer em todo replica
set que você opera.

## Write concern: quantos membros precisam ter a escrita

Um cliente que escreve recebe "feito" em algum momento, e o **write concern** diz qual momento.
`w: 1` responde assim que o primário tem a escrita. `w: "majority"` responde quando a maioria dos
membros a tem, dois de três aqui. As duas últimas linhas da sessão acima mostram o padrão do
MongoDB 8.0: `majority`, e `implicit`, que quer dizer que ninguém o definiu e o servidor escolheu.
`wtimeout: 0` quer dizer que o cliente espera o tempo que for preciso.

Para ver a diferença, os dois secundários precisam ficar para trás de propósito. O `db.fsyncLock()`
descarrega os dados do membro no disco e então **bloqueia toda escrita nesse membro**, replicação
incluída. A aula 11 o usa para o que ele serve. Aqui ele faz o papel de dois secundários que não
dão conta de acompanhar:

```
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
```

Com os dois secundários congelados, escreva uma vez de cada jeito:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> db.products.insertOne({ _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") }, { writeConcern: { w: 1 } })
{ acknowledged: true, insertedId: 'MS-204' }
rs0 [direct: primary] shop> db.products.insertOne({ _id: "MN-330", name: "27-inch monitor", price: Decimal128("1499.00") }, { writeConcern: { w: "majority", wtimeout: 3000 } })
Uncaught:
MongoWriteConcernError[WriteConcernFailed]: waiting for replication timed out
Additional information: {
  wtimeout: true,
  writeConcern: { w: 'majority', wtimeout: 3000, provenance: 'clientSupplied' }
}
Result: {
  n: 1,
  electionId: ObjectId('7fffffff0000000000000001'),
  opTime: { ts: Timestamp({ t: 1791618884, i: 1 }), t: 1 },
  writeConcernError: {
    code: 64,
    codeName: 'WriteConcernFailed',
    errmsg: 'waiting for replication timed out',
    errInfo: {
      wtimeout: true,
      writeConcern: { w: 'majority', wtimeout: 3000, provenance: 'clientSupplied' }
    }
  },
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791618884, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: 0
    }
  },
  operationTime: Timestamp({ t: 1791618884, i: 1 })
}
rs0 [direct: primary] shop> db.products.countDocuments()
3
rs0 [direct: primary] shop> exit
```

O insert com `w: 1` respondeu na hora. O insert com majority esperou os três segundos que o
`wtimeout` permitia e falhou com `WriteConcernFailed`. **Depois o `countDocuments()` contou três
produtos, então o monitor foi gravado mesmo assim.** Um erro de write concern não desfaz nada. Ele
diz que o servidor não conseguiu confirmar a garantia pedida no tempo permitido, e a escrita fica
no primário sem promessa de que vai sobreviver. Uma aplicação que a repete às cegas grava duas
vezes; aqui o `_id` fixo transformaria a repetição num erro de chave duplicada, que é o desfecho
melhor.

Destrave os dois secundários e eles aplicam o que perderam, em ordem, a partir do oplog:

```
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
```

Por que esperar pela maioria, se `w: 1` é mais rápido? Porque **uma escrita que só o primário tem
pode se perder**. Se o primário morrer antes de um secundário copiá-la, o membro eleito em seguida
nunca ouviu falar dela. A última seção desta aula perde exatamente assim uma escrita `w: 1`
confirmada.
