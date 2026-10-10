---
title: Preferência de leitura, e uma leitura desatualizada
version: 1
---

Escritas têm um destino só, o primário. **Leituras podem ir a qualquer lugar, e a preferência de
leitura diz para onde.** O padrão também as manda ao primário, e essa é a única configuração em que
uma leitura com certeza vê a escrita que acabou de ser confirmada. Toda outra configuração troca
essa garantia por alguma coisa: um primário com menos trabalho, uma cópia mais perto de quem lê, ou
uma resposta enquanto não há primário nenhum.

| modo | para onde vai uma leitura |
|---|---|
| `primary` | o primário; sem primário, a leitura falha |
| `primaryPreferred` | o primário, e um secundário só enquanto não houver primário |
| `secondary` | um secundário; sem nenhum, a leitura falha |
| `secondaryPreferred` | um secundário, e o primário só enquanto nenhum secundário responder |
| `nearest` | quem responder mais rápido, primário ou não |

## Conectar como uma aplicação conecta

Até aqui toda sessão foi `direct:` a um contêiner. Uma aplicação se conecta ao **conjunto**: uma
string de conexão lista alguns membros e dá o nome do conjunto, e o driver pergunta a eles quem é
quem, encontra o primário e continua observando. O `mongosh` faz o mesmo quando recebe uma string
assim, e o prompt dele perde a palavra `direct`. Pergunte para onde cada modo manda uma leitura,
usando o `explain()`, que informa o servidor que a executou:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0"
rs0 [primary] shop> for (const mode of ["primary", "primaryPreferred", "secondary", "secondaryPreferred", "nearest"]) print(mode.padEnd(20), db.products.find().readPref(mode).explain().serverInfo.host)
primary              mongo3
primaryPreferred     mongo3
secondary            mongo1
secondaryPreferred   mongo1
nearest              mongo2

rs0 [primary] shop> exit
```

`primary` e `primaryPreferred` foram ao `mongo3`, o primário desta execução. `secondary` e
`secondaryPreferred` foram ao `mongo1`, um dos dois secundários. `nearest` escolheu o `mongo2`: o
driver mede a ida e volta até cada membro e sorteia entre os que estão a até 15 ms do mais rápido,
e numa máquina só todo membro está perto assim.

## Uma leitura desatualizada, de propósito

Um secundário fica atrás do primário pelo tempo que a replicação levar, geralmente milissegundos, e
a aula 5 disse o que uma aplicação precisa tolerar nessa janela. Para manter a janela aberta tempo
bastante para olhar para ela, congele os dois secundários de novo, `mongo1` e `mongo2` desta vez, e
mude um preço com `w: 1`:

```
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec -it mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0"
rs0 [primary] shop> db.products.updateOne({ _id: "KB-101" }, { $set: { price: Decimal128("329.90") } }, { writeConcern: { w: 1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
rs0 [primary] shop> db.products.find({ _id: "KB-101" }, { price: 1 })
[ { _id: 'KB-101', price: Decimal128('329.90') } ]
rs0 [primary] shop> db.products.find({ _id: "KB-101" }, { price: 1 }).readPref("secondary")
[ { _id: 'KB-101', price: Decimal128('349.90') } ]
rs0 [primary] shop> db.products.find({ _id: "KB-101" }, { price: 1 }).readConcern("majority")
[ { _id: 'KB-101', price: Decimal128('349.90') } ]
rs0 [primary] shop> exit
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0" --eval 'db.products.find({ _id: "KB-101" }, { price: 1 }).readConcern("majority")'
[ { _id: 'KB-101', price: Decimal128('329.90') } ]
```

O primário respondeu 329.90 e o secundário 349.90, **um produto com dois preços no mesmo
instante**, e as duas leituras deram certo. Nada na resposta diz qual delas é a velha.

## Read concern: o que uma leitura pode devolver

A última leitura daquela sessão pediu outra coisa. O **read concern** diz o quanto o dado precisa
estar assentado, independentemente de para onde vai a leitura. O padrão, `"local"`, devolve o que o
membro tiver, inclusive escritas que só ele viu. `"majority"` devolve só o que a maioria dos membros
confirmou, e isso nunca pode ser desfeito, porque qualquer primário futuro tem de tê-lo.

No primário, com os dois secundários congelados, `"local"` viu o preço novo e `"majority"` o
antigo: a mudança tinha chegado a um membro de três. Depois que os secundários foram destravados, a
mesma leitura `"majority"` devolveu 329.90.

Então **`"majority"` compra durabilidade, não atualidade**. Ela pode devolver algo mais antigo que
`"local"` no mesmo membro e no mesmo instante; o que ela nunca devolve é um valor prestes a sumir.
Um cliente que precisa ler o que acabou de escrever lê do primário, ou usa uma sessão causalmente
consistente, que diz ao servidor por qual escrita está esperando; essa segunda opção não foi
executada nesta aula.
