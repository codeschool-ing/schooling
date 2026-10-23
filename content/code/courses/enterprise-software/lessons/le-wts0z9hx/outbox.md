---
title: The transactional outbox
version: 1
---

The consumer in the previous section is safe against duplicates. The publisher has a problem of its
own, and it is easy to write without seeing it. A service that records something in its database
and then publishes a message about it is writing to **two systems that share no transaction**. One
write can succeed and the other fail, and **no ordering of the two calls, and no amount of retrying,
makes them succeed or fail together**. This is the *dual-write problem*, and the transactional
outbox is the standard answer to it.

## Four outcomes, two of them wrong

The Portal B2B's first version took a bakery's order like this: commit the order in its own
PostgreSQL database, then put a message on `SA.PORTAL.ORDERS` for SAP. The two writes give four
outcomes:

| database commit | publish | result |
|---|---|---|
| succeeds | succeeds | correct |
| fails | not attempted | correct: the bakery sees an error and tries again |
| succeeds | fails | the bakery has a confirmed order that SAP never hears of |
| fails after the publish | succeeds | SAP creates a sales order the portal has no record of |

The third row is the one that happened. On a Sunday night in 2024 the queue manager was restarted
for maintenance while the portal was running, and for about forty minutes every put failed. The
portal had saved each order and shown each bakery a confirmation; the error from the put went to a
log nobody read on Sundays. **47 orders were never delivered.** Serra Alta found out on Monday
morning, when the first bakeries called to ask where their butter was.

Reversing the order of the calls only moves the problem to the fourth row: publish first, then
commit, and a commit that fails leaves SAP with an order the portal never confirmed. A retry loop
around the publish helps with a short outage and does nothing when the portal process itself dies
between the two calls, which is the moment a deploy or a crash chooses.

## One transaction, then a relay

The outbox puts both writes into the one system that has transactions: the service's own database.

1. In one local transaction, write the business row **and** a row in an `outbox` table that holds
   the message, as it will be published, with its id.
2. A separate process, the **relay**, reads outbox rows not yet sent, publishes each one, and marks
   it sent.

Step 1 is atomic: the order exists if and only if its message exists. Step 2 can fail at any point
and be retried, because the message is safe in the table until it is marked. Chris Richardson
named the pattern *transactional outbox* in his catalogue of microservice patterns and his book
*Microservices Patterns* (2018); the idea is older than the name.

Step 2 has the same gap as every consumer in the previous sections. **If the relay publishes and
stops before marking the row sent, it publishes the same message again when it restarts.** The
outbox does not remove duplicates; it turns lost messages into duplicated ones, which the idempotent
consumer already knows how to absorb. That is why the two belong together: the outbox makes the
publisher at-least-once, and the idempotent consumer makes at-least-once harmless.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l10-outbox\" aria-label=\"A sequence diagram with five lifelines: the portal, the portal database, the relay, the queue and the consumer. The portal writes the payment and outbox row portal-1 in one transaction. The relay reads the unsent rows and publishes portal-1 to the queue, then stops before marking it sent. On restart it reads the unsent rows again, finds portal-1 still there, publishes it a second time, and marks it sent. The queue delivers both copies to the consumer, which applies the first and skips the second because its id is already processed.\"><defs><marker id=\"l10-outbox-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-outbox-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"72.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">portal</text><path d=\"M72.0 40.0 L72.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"160.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">portal database</text><path d=\"M216.0 40.0 L216.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"304.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">relay</text><path d=\"M360.0 40.0 L360.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"448.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">queue</text><path d=\"M504.0 40.0 L504.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"592.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consumer</text><path d=\"M648.0 40.0 L648.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"144.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">one transaction</text><path d=\"M76.0 90.0 L210.0 90.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"144.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payment + portal-1</text><path d=\"M356.0 128.0 L222.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"288.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read unsent</text><path d=\"M364.0 156.0 L498.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"432.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publish portal-1</text><path d=\"M353.0 175.0 L367.0 189.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M353.0 189.0 L367.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"376.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">stops before marking sent</text><path d=\"M356.0 216.0 L222.0 216.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"288.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read unsent: portal-1 again</text><path d=\"M364.0 244.0 L498.0 244.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-amber)\"></path><text x=\"432.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publish portal-1</text><path d=\"M356.0 272.0 L222.0 272.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"288.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mark sent</text><path d=\"M508.0 304.0 L642.0 304.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"576.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal-1</text><text x=\"640.0\" y=\"318.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">applied</text><path d=\"M508.0 340.0 L642.0 340.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-amber)\"></path><text x=\"576.0\" y=\"331.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal-1</text><text x=\"640.0\" y=\"354.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">skipped: processed</text></svg>", "caption": "The outbox turns a lost message into a duplicated one, and the idempotent consumer turns the duplicate into nothing. The id is fixed in the outbox row, so both copies carry the same one."}
```

One detail decides whether the consumer can recognise the duplicate: **the message id is fixed when
the outbox row is written, not when the relay sends it.** A relay that generated a fresh id on each
attempt would publish the same payment under two ids, and the consumer's `processed` table would
see two different messages. The previous section's table of natural keys and message ids assumed
the id belonged to the fact; this is where that is made true.

## The program

`outbox.py` is the portal's side of the payment example. Its `pay` command records a payment and
its outbox message in one transaction; its `relay` command publishes whatever is pending. The broker
is again a file, `queue.jsonl`, so that the consumer from the previous section can read what the
relay published. To stage the failure this section is about, `relay --crash` stops the relay after
it publishes the first message and before it marks it sent, which is what a deploy or a power cut
does at the wrong moment.

Save it as `outbox.py` in the same directory as `consumer.py`.

```schooling-example
{
  "language": "python",
  "file": "outbox.py",
  "parts": [
    {
      "code": "# outbox.py: record a payment and its message in one transaction; a relay publishes\nimport json\nimport sqlite3\nimport sys",
      "note": "The same three modules as `consumer.py`. The portal's database is a separate file, `portal.db`, because publisher and consumer never share one."
    },
    {
      "code": "\ndb = sqlite3.connect(\"portal.db\")\ndb.executescript(\"\"\"\nCREATE TABLE IF NOT EXISTS payments (invoice TEXT PRIMARY KEY, customer TEXT, cents INTEGER);\nCREATE TABLE IF NOT EXISTS outbox (id INTEGER PRIMARY KEY, body TEXT, sent INTEGER DEFAULT 0);\n\"\"\")",
      "note": "`payments` is the portal's business data. `outbox` holds each message exactly as it will be published, and `sent` says whether the relay has finished with it."
    },
    {
      "code": "\n\ndef pay(invoice, customer, cents):\n    with db:  # the payment and the message about it commit together, or not at all\n        db.execute(\"INSERT INTO payments VALUES (?, ?, ?)\", (invoice, customer, cents))\n        row = db.execute(\"INSERT INTO outbox (body) VALUES ('')\").lastrowid\n        body = {\"id\": f\"portal-{row}\", \"invoice\": invoice, \"customer\": customer, \"cents\": cents}\n        db.execute(\"UPDATE outbox SET body = ? WHERE id = ?\", (json.dumps(body), row))\n    print(f\"recorded {invoice} with outbox message portal-{row}\")",
      "note": "One transaction for the payment and its message. The message id comes from the outbox row's own number, so it is fixed here, once, and every later copy of the message carries the same id."
    },
    {
      "code": "\n\ndef relay(crash):\n    pending = db.execute(\"SELECT id, body FROM outbox WHERE sent = 0 ORDER BY id\").fetchall()\n    for row, body in pending:\n        with open(\"queue.jsonl\", \"a\") as queue:  # the broker, for this example\n            queue.write(body + \"\\n\")\n        print(f\"published portal-{row}\")",
      "note": "The relay reads every unsent row in id order and publishes it. The broker here is a file the consumer can read; with IBM MQ it would be a put to a topic."
    },
    {
      "code": "        if crash:\n            sys.exit(f\"relay stopped before marking portal-{row} sent\")\n        with db:\n            db.execute(\"UPDATE outbox SET sent = 1 WHERE id = ?\", (row,))",
      "note": "The staged failure, then the mark. `--crash` stops the program in the one place that matters: after the publish and before the row is marked sent. A deploy or a power cut can stop it there too."
    },
    {
      "code": "\n\nif sys.argv[1] == \"pay\":\n    pay(sys.argv[2], sys.argv[3], int(sys.argv[4]))\nelse:\n    relay(crash=\"--crash\" in sys.argv)",
      "note": "Two commands: `pay` with an invoice, a customer and an amount in cents, and `relay`, with or without `--crash`."
    }
  ]
}
```

Record two payments, run the relay with the staged crash, then run it again as a restart would, and
look at what reached the broker:

```
$ python3 outbox.py pay NF-18240 "Mercado Central" 48000
recorded NF-18240 with outbox message portal-1
$ python3 outbox.py pay NF-18241 "Casa Minas" 91050
recorded NF-18241 with outbox message portal-2
$ python3 outbox.py relay --crash
published portal-1
relay stopped before marking portal-1 sent
$ python3 outbox.py relay
published portal-1
published portal-2
$ cat queue.jsonl
{"id": "portal-1", "invoice": "NF-18240", "customer": "Mercado Central", "cents": 48000}
{"id": "portal-1", "invoice": "NF-18240", "customer": "Mercado Central", "cents": 48000}
{"id": "portal-2", "invoice": "NF-18241", "customer": "Casa Minas", "cents": 91050}
```

`portal-1` is in the queue twice: once from the run that crashed and once from the restart, which
found the row still unsent. Nothing was lost, and something was duplicated, exactly as the outbox
promises. Now give the queue to the consumer from the previous section, whose ledger already holds
its three payments:

```
$ python3 consumer.py queue.jsonl
paid NF-18240 for Mercado Central: R$ 480,00
skip portal-1: already processed
paid NF-18241 for Casa Minas: R$ 910,50
ledger: 5 payments, R$ 6.736,80
```

**The consumer applied `portal-1` once, skipped the copy, and applied `portal-2`.** The ledger went
from three payments to five, not six. The two halves have met: the outbox made sure the payments
reached the queue whatever happened to the relay, and the `processed` table made sure the repeat
changed nothing.

## Relaying in practice

The relay in `outbox.py` polls the table: read what is unsent, publish, mark. That is the simplest
relay and often enough. It costs a query every few seconds and adds up to one polling interval of
latency, which for a bakery's order is nothing.

The alternative is to read the database's transaction log instead of the table, the change data
capture that lesson 9 described. Debezium, for one, has an outbox mode that turns inserted outbox
rows into published messages. It has no polling and lower latency, and it is one more component to
run and monitor. Serra Alta's portal polls; Joana's ADR says that a latency requirement under a few
seconds would be the reason to change.

Three operational rules complete the pattern:

- **Publish in id order, from one relay at a time.** Two relays reading the same table would publish
  the same rows twice as a matter of course, and could publish them out of order. If one relay is
  not enough, split the outbox so that each relay owns a part of it.
- **Delete sent rows on a schedule.** The table is a buffer, not an archive; the portal keeps sent
  rows for seven days, which is long enough to answer "was it published?" during an incident.
- **Alarm on the oldest unsent row.** A relay that has stopped looks exactly like a quiet day. An
  outbox row older than five minutes means the relay is down or the broker is refusing it, and
  somebody should know before a bakery calls.

The Monday of the 47 orders is the reason the portal's order flow now works this way. During the
SAP maintenance window every Sunday, orders still wait in the queue; what changed is that an order
can no longer exist in the portal without its message existing too.
