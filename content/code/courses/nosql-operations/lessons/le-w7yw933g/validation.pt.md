---
title: Deixando o servidor recusar
version: 1
---

Um **validador** é uma regra presa a uma coleção, contra a qual todo insert e todo update é
verificado. Ele não dá tabelas ao MongoDB; os documentos ainda podem ter campos que a regra não
menciona. O que ele dá é a única coisa que faltou na seção anterior, **um erro no momento do
engano**, vindo do servidor, seja qual for o programa que errou. A regra é escrita em JSON Schema,
o mesmo vocabulário que muitas APIs usam para descrever seus payloads, sob o operador `$jsonSchema`.

## Uma regra para produtos

`collMod` muda as opções de uma coleção que existe. Esta regra diz que um produto tem um nome que é
string, um preço que é um decimal de no mínimo zero e um estoque que é um inteiro não negativo:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.runCommand({
|   collMod: "products",
|   validator: { $jsonSchema: {
|     bsonType: "object",
|     required: ["name", "price", "stock"],
|     properties: {
|       name: { bsonType: "string" },
|       price: { bsonType: "decimal", minimum: 0 },
|       stock: { bsonType: "int", minimum: 0 }
|     }
|   } }
| })
{ ok: 1 }
shop> db.products.insertOne({ _id: "HS-300", name: "Headset", price: 299.90, stock: 5 })
Uncaught:

MongoServerError: Document failed validation
Additional information: {
  failingDocumentId: 'HS-300',
  details: {
    operatorName: '$jsonSchema',
    schemaRulesNotSatisfied: [
      {
        operatorName: 'properties',
        propertiesNotSatisfied: [
          {
            propertyName: 'price',
            details: [
              {
                operatorName: 'bsonType',
                specifiedAs: { bsonType: 'decimal' },
                reason: 'type did not match',
                consideredValue: 299.9,
                consideredType: 'double'
              }
            ]
          }
        ]
      }
    ]
  }
}
shop> exit
```

**`{ ok: 1 }`, embora dois produtos da coleção já quebrem a regra.** Acrescentar um validador não
verifica nada do que já está guardado; ele vale da próxima escrita em diante. O insert do headset
que vem em seguida é essa próxima escrita, e é recusado. O erro é longo porque é específico, e vale
lê-lo uma vez de dentro para fora: em `propertiesNotSatisfied` a propriedade é `price`, a regra era
`bsonType: 'decimal'`, e o valor que o servidor considerou foi `299.9`, do tipo `double`. É o engano
da primeira seção desta aula, um preço digitado como número, pego pelo servidor em vez de pela nota
fiscal de um cliente.

## Os documentos que já estavam errados

Com a regra no lugar, um update no cartão de memória, aquele cujo preço é string, é recusado mesmo
que o update só mexa no estoque. Isso é `validationLevel: "strict"`, o padrão: **todo documento que
um update deixa para trás precisa passar**. Numa coleção cheia de documentos antigos, isso quer dizer
que o primeiro deploy de um validador impede uma aplicação que funcionava de atualizá-los.
`"moderate"` é a configuração para essa situação:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.updateOne({ _id: "SD-128" }, { $inc: { stock: -1 } })
Uncaught:

MongoServerError: Document failed validation
Additional information: {
  failingDocumentId: 'SD-128',
  details: {
    operatorName: '$jsonSchema',
    schemaRulesNotSatisfied: [
      {
        operatorName: 'properties',
        propertiesNotSatisfied: [
          {
            propertyName: 'price',
            details: [
              {
                operatorName: 'bsonType',
                specifiedAs: { bsonType: 'decimal' },
                reason: 'type did not match',
                consideredValue: '79.90',
                consideredType: 'string'
              }
            ]
          }
        ]
      }
    ]
  }
}
shop> db.runCommand({ collMod: "products", validationLevel: "moderate" })
{ ok: 1 }
shop> db.products.updateOne({ _id: "SD-128" }, { $inc: { stock: -1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.find({ $nor: [db.getCollectionInfos({ name: "products" })[0].options.validator] }, { name: 1 })
[
  { _id: 'SD-128', name: '128 GB memory card' },
  { _id: 'WC-720', name: 'Webcam' }
]
shop> exit
```

Com `moderate` o mesmo `$inc` passou. A regra continua verificada em todo insert e nos updates de
documentos que passam nela; documentos que já eram inválidos podem ser atualizados e continuar
inválidos. A última consulta é o censo desta coleção: `$nor` em volta do próprio validador devolve
todo documento que falha nele, aqui o cartão de memória e a webcam.

| configuração | valores | o que ela decide |
|---|---|---|
| `validationLevel` | `strict` (padrão), `moderate`, `off` | quais escritas são verificadas: todas, ou não os updates de documentos que já falham |
| `validationAction` | `error` (padrão), `warn` | o que uma verificação que falha faz: recusa a escrita, ou a aceita e escreve uma linha no log do servidor |

## Primeiro avisar, depois recusar

`validationAction: "warn"` deixa a escrita passar e a registra. É assim que um validador é
implantado numa coleção em que programas de verdade estão escrevendo, porque mostra quais programas
quebrariam antes de algum quebrar:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.runCommand({ collMod: "products", validationAction: "warn" })
{ ok: 1 }
shop> db.products.insertOne({ _id: "HS-300", name: "Headset", price: 299.90, stock: 5 })
{ acknowledged: true, insertedId: 'HS-300' }
shop> exit
ana@vm:~$ docker logs mongo 2>&1 | grep "would fail validation"
{"t":{"$date":"2026-10-10T07:47:59.424+00:00"},"s":"W",  "c":"STORAGE",  "id":20294,   "ctx":"conn52","msg":"Document would fail validation","attr":{"namespace":"shop.products","document":{"_id":"HS-300","name":"Headset","price":299.9,"stock":5},"errInfo":{"failingDocumentId":"HS-300","details":{"operatorName":"$jsonSchema","schemaRulesNotSatisfied":[{"operatorName":"properties","propertiesNotSatisfied":[{"propertyName":"price","details":[{"operatorName":"bsonType","specifiedAs":{"bsonType":"decimal"},"reason":"type did not match","consideredValue":299.9,"consideredType":"double"}]}]}]}}}}
```

O insert foi aceito, e o log do servidor guarda o documento e a mesma explicação que o erro dava,
numa linha de JSON com o namespace e a hora. **Um aviso num log só ajuda se alguém lê o log.** A
aula 20 transforma linhas como essa em algo que chama uma pessoa; até lá, `warn` é uma medição que
você faz por alguns dias, não um lugar para ficar.

Quando o log para de crescer e o censo está vazio, os documentos são consertados e a regra fica
estrita:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.updateOne({ _id: "SD-128" }, { $set: { price: NumberDecimal("79.90") } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.updateOne({ _id: "WC-720" }, { $rename: { prcie: "price" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.updateOne({ _id: "HS-300" }, { $set: { price: NumberDecimal("299.90") } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.find({ $nor: [db.getCollectionInfos({ name: "products" })[0].options.validator] }).count()
0
shop> db.runCommand({ collMod: "products", validationLevel: "strict", validationAction: "error" })
{ ok: 1 }
shop> exit
```

`$set` deu preços decimais ao cartão de memória e ao headset, e `$rename` levou o `prcie` da webcam
para `price` sem redigitar o valor. O censo voltou `0`, e só então `strict` e `error` voltaram. Nessa
ordem, nada que a aplicação faz é recusado de surpresa.

## Uma regra desde o primeiro documento

Uma coleção que ainda não existe recebe o validador em `createCollection`, e assim nunca guarda um
documento inválido. Um cliente precisa ter um e-mail, e o e-mail precisa ter exatamente um `@` com
algo de cada lado:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.createCollection("customers", {
|   validator: { $jsonSchema: {
|     required: ["email"],
|     properties: { email: { bsonType: "string", pattern: "^[^@\\s]+@[^@\\s]+$" } }
|   } }
| })
{ ok: 1 }
shop> db.customers.insertOne({ _id: 1, name: "Ana Ribeiro", email: "ana.example.com" })
Uncaught:

MongoServerError: Document failed validation
Additional information: {
  failingDocumentId: 1,
  details: {
    operatorName: '$jsonSchema',
    schemaRulesNotSatisfied: [
      {
        operatorName: 'properties',
        propertiesNotSatisfied: [
          {
            propertyName: 'email',
            details: [
              {
                operatorName: 'pattern',
                specifiedAs: { pattern: '^[^@\\s]+@[^@\\s]+$' },
                reason: 'regular expression did not match',
                consideredValue: 'ana.example.com'
              }
            ]
          }
        ]
      }
    ]
  }
}
shop> db.customers.insertOne({ _id: 1, name: "Ana Ribeiro", email: "ana@example.com" })
{ acknowledged: true, insertedId: 1 }
shop> exit
rc=0
```

A recusa nomeia a regra, `pattern`, e o motivo, `regular expression did not match`, e o mesmo insert
com o endereço corrigido entrou.

Um validador não é motivo para parar de verificar na aplicação: ele é a última linha, e o erro dele
chega ao usuário como erro do servidor, a menos que a aplicação o traduza. E ele pode ser pulado por
um cliente que envia `bypassDocumentValidation`, o que exige um privilégio que usuários comuns de
aplicação não deveriam receber.
