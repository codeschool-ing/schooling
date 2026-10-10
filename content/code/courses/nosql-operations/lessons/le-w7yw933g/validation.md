---
title: Letting the server refuse
version: 1
---

A **validator** is a rule attached to a collection that every insert and update is checked
against. It does not give MongoDB tables; documents can still carry fields the rule does not
mention. What it gives is the one thing the last section lacked, **an error at the moment of the
mistake**, from the server, whatever program made it. The rule is written in JSON Schema, the same
vocabulary many APIs use to describe their payloads, under the operator `$jsonSchema`.

## A rule for products

`collMod` changes the options of a collection that exists. This rule says a product has a name
that is a string, a price that is a decimal of at least zero, and a stock that is a non-negative
integer:

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

**`{ ok: 1 }`, although two products in the collection already break the rule.** Adding a
validator checks nothing that is already stored; it applies from the next write on. The headset
insert that follows is that next write, and it is refused. The error is long because it is
specific, and it is worth reading once from the inside out: under `propertiesNotSatisfied` the
property is `price`, the rule was `bsonType: 'decimal'`, and the value the server considered was
`299.9`, of type `double`. That is the mistake from the first section of this lesson, a price typed
as a number, caught by the server instead of by a customer's invoice.

## The documents that were already wrong

With the rule in place, an update to the memory card, the one whose price is a string, is refused
even though the update itself only touches the stock. That is `validationLevel: "strict"`, the
default: **every document an update leaves behind must pass**. On a collection full of old
documents, it means the first deploy of a validator stops a working application from updating
them. `"moderate"` is the setting for that situation:

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

Under `moderate` the same `$inc` went through. The rule is still checked on every insert and on
updates to documents that pass it; documents that were already invalid may be updated and stay
invalid. The last query is the census for this collection: `$nor` around the validator itself
returns every document that fails it, here the memory card and the webcam.

| setting | values | what it decides |
|---|---|---|
| `validationLevel` | `strict` (default), `moderate`, `off` | which writes are checked: all of them, or not the updates to documents that already fail |
| `validationAction` | `error` (default), `warn` | what a failed check does: refuse the write, or accept it and write a line in the server's log |

## Warn first, then refuse

`validationAction: "warn"` lets the write through and records it. It is how a validator is rolled
out on a collection that real programs are writing to, because it shows which programs would break
before any of them does:

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

The insert was accepted, and the server's log holds the document and the same explanation the
error gave, as one line of JSON with the namespace and the time. **A warning in a log only helps if
somebody reads the log.** Lesson 20 turns lines like this into something that pages a person; until
then, `warn` is a measurement you take for a few days, not a place to stay.

When the log stops growing and the census is empty, the documents are repaired and the rule is
made strict:

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

`$set` gave the memory card and the headset decimal prices, and `$rename` moved the webcam's
`prcie` to `price` without retyping the value. The census came back `0`, and only then did
`strict` and `error` go back on. In that order, nothing the application does is refused by surprise.

## A rule from the first document

A collection that does not exist yet takes its validator in `createCollection`, so it never holds
an invalid document at all. A customer must have an e-mail, and the e-mail must have exactly one
`@` with something on each side:

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

The refusal names the rule, `pattern`, and the reason, `regular expression did not match`, and the
same insert with the address corrected went in.

A validator is not a reason to stop checking in the application: it is the last line, and its
error reaches the user as a server error unless the application translates it. And it can be
skipped by a client that sends `bypassDocumentValidation`, which needs a privilege that ordinary
application users should not be given.
