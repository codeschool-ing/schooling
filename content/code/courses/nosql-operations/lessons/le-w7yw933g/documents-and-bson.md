---
title: Documents, and the types JSON does not have
version: 1
---

This lesson needs one container, `mongo`, from lesson 1. If it is only stopped, `docker start mongo`
brings it back with its data. If you removed it, these two lines make it again; the first one
answers that the network already exists if it does, and that is harmless:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
```

Every session in this lesson opens the client the same way, with the database's name at the end:
`docker exec -it mongo mongosh --quiet shop`. Nothing has to be created first. The first write to
a collection in `shop` creates the collection and the database, and the next section shows what
that habit costs.

## A document looks like JSON and is not

mongosh prints documents in something close to JavaScript's object syntax, and drivers hand them
to programs as maps and dictionaries, so the obvious reading is that **MongoDB stores JSON**. It
stores **BSON**, a binary encoding of the same shape with more types than JSON has. JSON knows
strings, numbers, booleans, null, arrays and objects. BSON adds a date, a 32-bit and a 64-bit
integer beside the double, a 128-bit decimal, binary data and the `ObjectId`, among others. The
type is stored with every value, in every document, so two documents in one collection can hold
the same field with different types, which is where the third section of this lesson goes.

Ask the server for the type of each field of a document made on the spot. `$documents` feeds a
pipeline from a literal list instead of a collection, and `$type` names what each value became:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> ObjectId()
ObjectId('6ac9ed4939db61f1c1336db1')
shop> ObjectId()
ObjectId('6ac9ed4a39db61f1c1336db2')
shop> ObjectId().getTimestamp()
ISODate('2026-10-10T07:46:19.000Z')
shop> new Date("2026-03-14T10:30:00-03:00")
ISODate('2026-03-14T13:30:00.000Z')
shop> db.aggregate([
|   { $documents: [{ n: 12, x: 12.5, big: 12345678901, price: NumberDecimal("349.90"), when: new Date(), id: ObjectId() }] },
|   { $project: { n: { $type: "$n" }, x: { $type: "$x" }, big: { $type: "$big" }, price: { $type: "$price" }, when: { $type: "$when" }, id: { $type: "$id" } } }
| ])
[
  {
    n: 'int',
    x: 'double',
    big: 'double',
    price: 'decimal',
    when: 'date',
    id: 'objectId'
  }
]
shop> exit
```

Read the last answer first. **`12` arrived as an `int` and `12.5` as a `double`**, because
mongosh sends a whole number that fits in 32 bits as an integer and anything else as a double.
`12345678901` does not fit in 32 bits, and mongosh did not promote it to a 64-bit integer: it is a
double, which holds whole numbers exactly only up to 2^53. A counter that must stay an integer
past two billion is written `NumberLong("12345678901")`. Your application's driver has its own
rules for the same question, and they are worth reading once for the language you use.

## The ObjectId, and the clock inside it

When a document arrives without an `_id`, the client gives it an `ObjectId`: twelve bytes, printed
as 24 hexadecimal digits. The two at the top of the session above were made one after the other,
and they are nearly the same string:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"The twelve bytes of an ObjectId, in three groups. The first four bytes are a timestamp in seconds since 1970; the next five are a random value chosen once per process; the last three are a counter that goes up by one for every id the process makes. Two ids made one after the other are shown under the groups: they share the random part, their timestamps differ by one second, and their counters differ by one.\"><rect x=\"40\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"92\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"144\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"196\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"40\" width=\"208\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"144.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4 bytes</text><text x=\"144.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">timestamp</text><text x=\"144.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seconds since 1970</text><rect x=\"248\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"300\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"352\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"404\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"456\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"248\" y=\"40\" width=\"260\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"378.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 bytes</text><text x=\"378.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">random value</text><text x=\"378.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chosen once per process</text><rect x=\"508\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"560\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"612\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"40\" width=\"156\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"586.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 bytes</text><text x=\"586.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">counter</text><text x=\"586.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+1 for every id</text><rect x=\"44\" y=\"137\" width=\"200\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"144.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6ac9ed49</text><rect x=\"252\" y=\"137\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">39db61f1c1</text><rect x=\"512\" y=\"137\" width=\"148\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">336db1</text><rect x=\"44\" y=\"177\" width=\"200\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"144.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">6ac9ed4a</text><rect x=\"252\" y=\"177\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">39db61f1c1</text><rect x=\"512\" y=\"177\" width=\"148\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"586.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">336db2</text><text x=\"352\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">marked: what changed between the two</text></svg>", "caption": "An ObjectId is twelve bytes, and the first four are a clock. Two ids from the same mongosh, made a second apart, differ only where the time and the counter are."}
```

**The first four bytes are the time the id was made, in seconds**, and `getTimestamp()` reads them
back: `2026-10-10T07:46:19` was the lab's clock at that moment. Three consequences follow, and
each one surprises somebody:

- Sorting by `_id` sorts roughly by creation time, to the second, and only as well as the clocks
  of the machines that made the ids agree. Inside one second the counter decides.
- Anybody who sees an id knows when the document was created. **An ObjectId is not a secret**: in
  a URL it tells a stranger when every customer signed up, and the counter makes neighbouring ids
  easy to guess. A link that must not be guessed carries a random token of its own.
- The id is made by the client, not by the server, which is why it exists before the insert is
  acknowledged and why a retried insert of the same document collides with itself.

`_id` does not have to be an ObjectId. Any value that is unique in the collection will do, and
the next section gives each product its SKU as its `_id`, because that is the key every other
document will use to name it.

## A date is a moment, not a time of day

BSON's date is a count of milliseconds since 1970 in UTC, with no time zone stored beside it. The
session above typed half past ten in São Paulo, `-03:00`, and the server kept
`2026-03-14T13:30:00.000Z`: the same moment, written in UTC. The conversion back to local time is
the reader's job, every time, and lesson 8 does it when it groups orders by month. A date stored
as the string `"14/03/2026"` sorts as text and compares as text, which in that format puts April
before March.

## Money, and the two answers to three keyboards

The keyboard costs 349.90. Three of them, computed as doubles, the way JavaScript and most
languages compute by default:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> 0.1 + 0.2
0.30000000000000004
shop> 349.90 * 3
1049.6999999999998
shop> db.aggregate([
|   { $documents: [{ double: 349.90, decimal: NumberDecimal("349.90") }] },
|   { $project: { double: { $multiply: ["$double", 3] }, decimal: { $multiply: ["$decimal", 3] } } }
| ])
[ { double: 1049.6999999999998, decimal: Decimal128('1049.70') } ]
shop> NumberDecimal(349.90 * 3)
Warning: NumberDecimal: specifying a number as argument is deprecated and may lead to loss of precision, pass a string instead
Decimal128('1049.6999999999998')
shop> exit
```

**The double is wrong in the fourteenth digit, and the server's double is wrong in the same
place**, because it is not a bug in either: 349.90 has no exact binary representation, any more
than one third has an exact decimal one. `Decimal128` stores the digits in base ten and gives
`1049.70`, the number on the invoice.

The last line is the trap that remains. `NumberDecimal(349.90 * 3)` computed the double first and
then made a decimal of the wrong answer, and mongosh warned about it. **A decimal is built from a
string**, `NumberDecimal("349.90")`, or it inherits the error it was meant to avoid.
`sql-databases` keeps the same shop's prices in `numeric(10,2)`, a decimal type too. The other
sound choice is integer cents, `34990`; what is not a choice is a price stored as a double.
