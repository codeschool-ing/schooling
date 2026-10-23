---
title: The idempotent consumer
version: 1
---

The first instinct when duplicates appear is to stop the broker sending them. The previous section
showed why that cannot be done: the duplicate is born in the gap between the work and the
acknowledgement, and no setting on the broker closes a gap that sits in your program. **The fix
belongs to the consumer: make handling the same message twice leave the same state as handling it
once.** An operation with that property is **idempotent**, and Hohpe and Woolf (2003) call a
consumer built that way an Idempotent Receiver.

## Some operations already are

Look at what a message asks the consumer to do. Some operations are idempotent by nature:

- "The price of butter 200 g is now R$ 12,00." Setting a value twice leaves the same value.
- "Order 4711 is cancelled." A cancelled order cancelled again is still cancelled.
- "Delete the delivery address with id 88." The second deletion finds nothing and does nothing.

Others are not, and they are the ones that cost money:

- "Add R$ 3.480,90 to Mercado Central's payments." Twice is R$ 6.961,80.
- "Insert a goods receipt for 4,120 litres from farm 10233." Twice pays the farm for milk it
  did not deliver.
- "Send the certificate of analysis to the customer." Twice is an embarrassment, and a hundred times
  is a complaint.

So the first question about a consumer is which kind its messages are. **A message that states a
new value is safer than a message that states a change**, and where you design the message
yourself, prefer the first. The last section of this lesson returns to it, because a stated value
is also what makes ordering manageable.

When the operation is not idempotent by nature, the consumer makes it so by remembering what it has
done.

## Remember the id, in the same transaction

Every message carries an id given by its publisher. The consumer keeps a table of the ids it has
processed, and handles a message in three steps inside **one database transaction**: record the id,
do the work, commit. If the id is already in the table, the message is a repeat and the consumer
does nothing but acknowledge it.

The words *one transaction* carry the design. Take the two other arrangements:

- Record the id in its own transaction **after** the work. A crash between the two commits leaves
  the work done and the id missing, and the redelivered message is processed again.
- Record the id **before** the work, in its own transaction. A crash between them leaves the id
  recorded and the work never done, and the redelivery is skipped: the message is lost, which is
  at-most-once by a longer road.

Only when the two writes commit together is there no moment at which one is true and the other is
not.

## The program

The program below is the consumer of Serra Alta's `invoice.paid` messages, cut down to what this
section is about. It keeps a ledger of payments in SQLite, which is part of Python's standard
library, so there is nothing to install. Running it is optional; reading the program and its output
is enough to follow the lesson, and lesson 1 says where to run the programs in this course.

The messages first. A real consumer reads them from a broker; this one reads a file with one JSON
message per line, which lets you redeliver a message by hand. This short script writes two files:
three messages, and a copy of the second one on its own:

```sh
# make-messages.sh: three "invoice paid" messages, then the second one again
cat > first.jsonl <<'END'
{"id": "m-1", "invoice": "NF-18231", "customer": "Padaria Estrela", "cents": 125000}
{"id": "m-2", "invoice": "NF-18232", "customer": "Mercado Central", "cents": 348090}
{"id": "m-3", "invoice": "NF-18233", "customer": "Padaria Nova", "cents": 61540}
END
grep '"m-2"' first.jsonl > again.jsonl
```

The ids here are written by hand. In the next section they come from the publisher's own database,
which is where they belong. Amounts are integer cents, never a fraction: R$ 1.250,00 travels as
`125000`.

Save the consumer beside the script as `consumer.py`. The notes say what each part is for; the copy
button takes the program without them.

```schooling-example
{
  "language": "python",
  "file": "consumer.py",
  "parts": [
    {
      "code": "# consumer.py: apply \"invoice paid\" messages to a ledger, each one once\nimport json\nimport sqlite3\nimport sys",
      "note": "Three modules from the standard library and nothing to install. `sqlite3` is a whole database in one file, which is all this example needs."
    },
    {
      "code": "\ndb = sqlite3.connect(\"ledger.db\")\ndb.executescript(\"\"\"\nCREATE TABLE IF NOT EXISTS ledger (invoice TEXT, customer TEXT, cents INTEGER);\nCREATE TABLE IF NOT EXISTS processed (message_id TEXT PRIMARY KEY);\n\"\"\")",
      "note": "Two tables. `ledger` is the work: one row per payment received. `processed` is the memory: one row per message handled, and its primary key refuses the same id twice. The first run creates `ledger.db`; later runs reuse it."
    },
    {
      "code": "\n\ndef brl(cents):\n    return f\"R$ {cents // 100:,}\".replace(\",\", \".\") + f\",{cents % 100:02d}\"",
      "note": "Money stays in integer cents and is only formatted for a person to read, in the Brazilian way: `125000` becomes `R$ 1.250,00`. No float touches it."
    },
    {
      "code": "\n\ndef handle(message):\n    with db:  # one transaction: both rows are written, or neither is\n        try:\n            db.execute(\"INSERT INTO processed VALUES (?)\", (message[\"id\"],))\n        except sqlite3.IntegrityError:\n            print(f\"skip {message['id']}: already processed\")\n            return",
      "note": "The heart of it. `with db:` opens one transaction and commits it at the end of the block, or rolls it back if anything raises. The id goes in first, with no question asked beforehand: if the primary key refuses it, this message was handled before, and the consumer writes nothing."
    },
    {
      "code": "        db.execute(\"INSERT INTO ledger VALUES (?, ?, ?)\",\n                   (message[\"invoice\"], message[\"customer\"], message[\"cents\"]))\n        print(f\"paid {message['invoice']} for {message['customer']}: {brl(message['cents'])}\")",
      "note": "The work, inside the same transaction as the id. Both rows commit together, so there is no moment at which the payment is recorded and the id is not, or the other way round."
    },
    {
      "code": "\n\nfor line in open(sys.argv[1]):\n    handle(json.loads(line))\ncount, total = db.execute(\"SELECT count(*), sum(cents) FROM ledger\").fetchone()\nprint(f\"ledger: {count} payments, {brl(total)}\")",
      "note": "One message per line of the file named on the command line, then the state of the ledger. With a real broker, the acknowledgement would be sent here, after `handle` returns: work first, then acknowledge."
    }
  ]
}
```

Run the script, then hand the consumer the three messages, then the repeat. On Windows the command
is `python` rather than `python3`, and the two `.jsonl` files can be written in any editor.

```
$ sh make-messages.sh
$ python3 consumer.py first.jsonl
paid NF-18231 for Padaria Estrela: R$ 1.250,00
paid NF-18232 for Mercado Central: R$ 3.480,90
paid NF-18233 for Padaria Nova: R$ 615,40
ledger: 3 payments, R$ 5.346,30
$ python3 consumer.py again.jsonl
skip m-2: already processed
ledger: 3 payments, R$ 5.346,30
```

The second run is the redelivery the previous section said would come. **The consumer recognised
`m-2`, wrote nothing, and the ledger still holds three payments and the same total.** Without the
`processed` table the second run would have inserted the payment again, and Mercado Central's
R$ 3.480,90 would have been counted twice.

## Why "check, then insert" is not enough

A natural first version asks before it acts:

```python
seen = db.execute("SELECT 1 FROM processed WHERE message_id = ?", (msg["id"],)).fetchone()
if not seen:
    apply_payment(msg)
    db.execute("INSERT INTO processed VALUES (?)", (msg["id"],))
```

It passes every test run by one consumer, and it fails in exactly the case that produces
duplicates. Two instances of the consumer read the same queue. Instance A takes `m-2` and is slow;
the broker's timeout expires and instance B receives `m-2` too. Both run the `SELECT`, both find
nothing, because neither has committed, and both apply the payment. The check and the insert are
two steps, and another consumer can act between them.

`consumer.py` never asks. It inserts the id and lets the **primary key** refuse a second copy. The
database is the one place both instances meet, and a unique constraint is its way of saying "only
one of you": whichever transaction inserts second fails, rolls back and writes nothing. **The
constraint does not need the consumers to agree; it decides for them.**

## Natural key or message id

The `processed` table remembers *messages*. Sometimes the business fact itself has an identity that
can do the same job, a **natural key**. An NF-e has a 44-digit access key and is authorised once;
a consumer that stores NF-e records can put a unique constraint on the access key and ignore any
second message about the same invoice, whatever the message's id.

The two fail in different places, and the choice depends on which failure is possible:

| | stops | fails when |
|---|---|---|
| message id | the same message delivered twice | the publisher sends the same fact twice under two ids, for example a person re-sending it from a console |
| natural key | any second message about the same fact | the fact can legitimately happen twice: a bakery paying invoice NF-18232 in two instalments is two payments with one invoice number |

`consumer.py` uses the message id because a payment is not unique per invoice. For an NF-e
authorisation, the natural key is better. **Use the natural key where the business says the fact
happens once, and the message id everywhere else.** Then make sure the publisher fixes the id
when the fact is recorded, not when the message is sent, which is the subject of the next section.

## What the transaction cannot cover

The trick works because the ledger and the `processed` table are in the same database. When the
work is somewhere else, a call to SAP or an email, there is no shared transaction. Two answers,
in order of preference:

1. **Pass the id on.** Many APIs accept an idempotency key with a request and return the first
   result to a repeat; Stripe's payment API is the well-known example. The consumer sends the
   message id as that key, and the duplicate is absorbed one system further on.
2. **Record the attempt and accept the rare repeat.** For an email, record the id before sending
   and accept that a crash at the wrong moment means one email is lost or sent twice. Choose which,
   on purpose, and write it down.

Last, the `processed` table grows by one row per message. Keep the ids for longer than any
redelivery could take, including a replay from a dead-letter queue weeks later (two sections on),
and delete older ones on a schedule. Serra Alta keeps them for 90 days.
