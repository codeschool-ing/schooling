---
title: "Service Bus queues: lock, settle, dead-letter"
version: 1
---

The picture most people bring to a queue is a pipe: a message goes in at one end, a consumer takes
it out at the other, and it is gone. **Receiving a message from a Service Bus queue does not remove
it.** In the default mode, peek-lock, the queue hands the message over and locks it for a while, the
lock duration, so that no other consumer can have it. The consumer then *settles* it: *complete*
removes it, *abandon* puts it back at once, *dead-letter* moves it aside for good. A consumer that
does none of the three, because it crashed, lets the lock run out, and the message comes back. Each return counts, and past a limit the queue stops trying. This section runs all four
endings on the shop's order queue.

The other mode, receive-and-delete, removes the message the moment it is sent to the consumer. A
consumer that dies halfway loses the message, which Microsoft's documentation calls at-most-once
processing; it suits data that is worthless a minute later, and not an order somebody paid for.

## The emulator, and what it is made of

No Service Bus namespace exists on a laptop, but its data plane does. Microsoft publishes an
emulator as a Docker image that speaks AMQP, the protocol the client libraries use, and accepts the
same connection-string shape as a namespace in Azure. It keeps its messages in SQL Server, which runs
beside it as a second container. **Its queues and topics are declared in a file read at start-up**,
`Config.json`, and nothing else creates them: a change to the file needs a restart, and a restart
forgets every message. Microsoft's documentation lists what it leaves out, among them partitioned
entities, Entra ID sign-in and autoscale, and caps it at one namespace and 50 queues or topics; it
asks for 2 GB of memory.

Make a directory for it, `~/azure/servicebus`, and save the declaration as
`~/azure/servicebus/Config.json`. It declares everything this lesson uses, and the next section uses
the rest of it:

```json
{
  "UserConfig": {
    "Namespaces": [
      {
        "Name": "sbemulatorns",
        "Queues": [
          {
            "Name": "orders",
            "Properties": {
              "LockDuration": "PT5S",
              "MaxDeliveryCount": 3
            }
          },
          {
            "Name": "order-steps",
            "Properties": {
              "RequiresSession": true
            }
          },
          {
            "Name": "payments",
            "Properties": {
              "RequiresDuplicateDetection": true,
              "DuplicateDetectionHistoryTimeWindow": "PT1M"
            }
          }
        ],
        "Topics": [
          {
            "Name": "order-paid",
            "Subscriptions": [
              {
                "Name": "billing"
              },
              {
                "Name": "shipping",
                "Rules": [
                  {
                    "Name": "physical-only",
                    "Properties": {
                      "FilterType": "Sql",
                      "SqlFilter": {
                        "SqlExpression": "kind = 'physical'"
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ],
    "Logging": {
      "Type": "Console"
    }
  }
}
```

The namespace's name, `sbemulatorns`, is the emulator's own and cannot be changed. The queue
`orders` carries two settings that matter now. **`LockDuration` is how long a received message stays
locked**, written as an ISO 8601 duration: `PT5S` is five seconds, chosen so that the lab moves
quickly; the default is one minute and the maximum five. **`MaxDeliveryCount` is how many
deliveries a message gets** before the queue gives up on it; the default is 10, and 3 is enough to
watch.

The two containers are started with Docker Compose, which the `docker` course used. Save this as
`~/azure/servicebus/compose.yaml`:

```yaml
# servicebus/compose.yaml
name: servicebus
services:
  emulator:
    container_name: servicebus-emulator
    image: mcr.microsoft.com/azure-messaging/servicebus-emulator:2.0.1
    volumes:
      - ./Config.json:/ServiceBus_Emulator/ConfigFiles/Config.json
    ports:
      - "5672:5672"
      - "5300:5300"
    environment:
      SQL_SERVER: mssql
      MSSQL_SA_PASSWORD: "Shop-lab-2026"
      ACCEPT_EULA: "Y"
    depends_on:
      - mssql
  mssql:
    container_name: mssql
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "Shop-lab-2026"
```

**`ACCEPT_EULA: "Y"` accepts two licences**, the emulator's and SQL Server's, and neither container
starts without it; read them at the addresses Microsoft's documentation gives before you set it. The
password is for a database that lives and dies on your laptop, and SQL Server only asks that it be
eight characters or more and mix kinds of character. Port 5672 is AMQP, where messages travel, and
5300 answers a health check. Start both, and wait for the check to say so; SQL Server takes most of
the half a minute:

```
ana@laptop:~/azure$ docker compose -f servicebus/compose.yaml up -d
 Network servicebus_default Creating 
 Network servicebus_default Creating 
 Network servicebus_default Created 
 Network servicebus_default Created 
 Container mssql Creating 
 Container mssql Created 
 Container servicebus-emulator Creating 
 Container servicebus-emulator Created 
 Container mssql Starting 
 Container mssql Started 
 Container servicebus-emulator Starting 
 Container servicebus-emulator Started 
ana@laptop:~/azure$ until curl -sf localhost:5300/health; do sleep 2; done; echo
{"status":"healthy","message":"Service is healthy."}
```

The programs below use Microsoft's Python library, `azure-servicebus`, at version 7.15.0. It goes in
a virtual environment of its own, `~/azure/messaging`, so that it cannot change a library the Azure
CLI depends on, together with the two libraries the Event Hubs section needs:

```
ana@laptop:~/azure$ python3 -m venv messaging
ana@laptop:~/azure$ messaging/bin/pip install -q azure-servicebus==7.15.0 azure-eventhub==5.15.1 azure-eventhub-checkpointstoreblob==1.2.0
ana@laptop:~/azure$ messaging/bin/pip list 2>/dev/null | grep -E "^azure-(servicebus|eventhub)"
azure-eventhub                     5.15.1
azure-eventhub-checkpointstoreblob 1.2.0
azure-servicebus                   7.15.0
```

The emulator's connection string is fixed and the same on every machine. `UseDevelopmentEmulator=true`
tells the library to talk plain AMQP to `localhost` rather than over TLS to a namespace in Azure, and
the key is a placeholder the emulator accepts. Put it in the environment of the terminal, where the
programs read it:

```sh
export SERVICEBUS="Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
```

## Send, receive, complete

Ana's first program sends one message per order number it is given. The message id is the order's,
`order-41`, rather than one the library would invent, and the next section shows why that matters.
Save it as `~/azure/send.py`:

```python
# send.py
import json
import os
import sys

from azure.servicebus import ServiceBusClient, ServiceBusMessage

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client, client.get_queue_sender("orders") as sender:
    for order in sys.argv[1:]:
        body = json.dumps({"order": int(order)})
        sender.send_messages(ServiceBusMessage(body, message_id=f"order-{order}"))
        print(f"sent order-{order}")
```

The second receives one message and ends it in the way it is told. Save it as `~/azure/work.py`:

```schooling-example
{"language": "python", "file": "work.py", "parts": [{"code": "# work.py\nimport os\nimport sys\n\nfrom azure.servicebus import ServiceBusClient\n\naction = sys.argv[1]\nclient = ServiceBusClient.from_connection_string(os.environ[\"SERVICEBUS\"])\n", "note": "The ending is the first argument: `complete`, `abandon`, `reject`, or anything else, such as `crash`, which settles nothing. The connection string comes from the environment, so the file holds no key."}, {"code": "with client, client.get_queue_receiver(\"orders\") as receiver:\n    received = receiver.receive_messages(max_message_count=1, max_wait_time=2)\n    if not received:\n        sys.exit(\"nothing to receive\")\n    msg = received[0]\n    print(f\"{msg.message_id}: delivery_count {msg.delivery_count}, locked until {msg.locked_until_utc:%H:%M:%S} UTC\")\n", "note": "A receiver is peek-lock unless told otherwise. It waits up to two seconds for one message, and what comes back is locked to this receiver until `locked_until_utc`."}, {"code": "    if action == \"complete\":\n        receiver.complete_message(msg)\n    elif action == \"abandon\":\n        receiver.abandon_message(msg)\n    elif action == \"reject\":\n        receiver.dead_letter_message(msg, reason=\"UnknownProduct\", error_description=\"no such product in the catalogue\")\n    print(f\"{msg.message_id}: {action}\")\n", "note": "The three settlements, each a request to the broker while the lock is still held. Any other word falls through, and the program leaves the `with` block holding a message it never settled, which is what a crash looks like from the queue."}]}
```

Three orders go in, and the first is received and completed:

```
ana@laptop:~/azure$ messaging/bin/python send.py 41 42 43
sent order-41
sent order-42
sent order-43
ana@laptop:~/azure$ messaging/bin/python work.py complete
order-41: delivery_count 0, locked until 18:51:16 UTC
order-41: complete
```

**The delivery count of a first delivery reads 0 in this library**: it is the AMQP header's count of
earlier attempts, not of deliveries so far. The lock lasts five seconds from the receive, which the
time beside it shows in UTC.

## Abandon, crash, reject

Order 42 is abandoned three times, as a consumer would that fails on it every time. Order 43 is
received by a consumer that crashes, which `crash` imitates by leaving without settling:

```
ana@laptop:~/azure$ for i in 1 2 3; do messaging/bin/python work.py abandon; done
order-42: delivery_count 0, locked until 18:51:18 UTC
order-42: abandon
order-42: delivery_count 1, locked until 18:51:21 UTC
order-42: abandon
order-42: delivery_count 2, locked until 18:51:24 UTC
order-42: abandon
ana@laptop:~/azure$ messaging/bin/python work.py crash
order-43: delivery_count 0, locked until 18:51:27 UTC
order-43: crash
ana@laptop:~/azure$ messaging/bin/python work.py complete
nothing to receive
ana@laptop:~/azure$ sleep 5; messaging/bin/python work.py reject
order-43: delivery_count 1, locked until 18:51:39 UTC
order-43: reject
```

Read it from the top. Each abandon released `order-42` at once, and its count went up by one. After
the third, the queue did not hand it out again: a fourth delivery would have passed
`MaxDeliveryCount`, so it moved the message to the queue's **dead-letter subqueue** instead. That is
why the next receive got `order-43`. The crash left `order-43` locked, so the receive straight after
it found nothing, although the queue was not empty. Five seconds later the lock had run out and the
message was back, with its count raised, and this time the consumer rejected it on purpose, with a
reason of its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The life of a message in the queue orders. An available message is received and becomes locked for 5 seconds to one consumer. From the lock there are three ways out: complete_message removes it; abandon_message, or the lock running out, makes it available again with its delivery count raised by one; dead_letter_message, or a delivery that would pass MaxDeliveryCount, moves it to the dead-letter subqueue.\"><defs><marker id=\"settle-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"settle-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"95\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">available</text><text x=\"95\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in the queue</text><rect x=\"285\" y=\"100\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"360\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">locked for 5 s</text><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">to one consumer</text><rect x=\"550\" y=\"16\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"625\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">removed</text><text x=\"625\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the work is done</text><rect x=\"550\" y=\"184\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"625\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dead-letter subqueue</text><text x=\"625\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">kept until somebody reads it</text><path d=\"M172 112 L282 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-p)\"></path><text x=\"227\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">receive_messages</text><path d=\"M285 142 L174 142\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-a)\"></path><text x=\"227\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">abandon_message</text><text x=\"227\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">or the lock runs out</text><text x=\"227\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">delivery count + 1</text><path d=\"M435 108 L547 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-p)\"></path><text x=\"462\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">complete_message</text><path d=\"M435 144 L547 200\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#settle-a)\"></path><text x=\"476\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dead_letter_message</text><text x=\"476\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">or count past MaxDeliveryCount</text></svg>", "caption": "Receiving locks a message; settling it decides what happens next. Every way back to the queue raises its delivery count, and past the limit the queue moves it aside."}
```

Every queue, and every subscription of a topic, has its own dead-letter subqueue, and **nothing
leaves it on its own**: no time-to-live applies there, and a message stays until somebody receives it
from the subqueue and completes it. The third program looks without taking. Save it as
`~/azure/dead.py`:

```python
# dead.py
import os

from azure.servicebus import ServiceBusClient, ServiceBusSubQueue

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
dlq = client.get_queue_receiver("orders", sub_queue=ServiceBusSubQueue.DEAD_LETTER)
with client, dlq:
    for msg in dlq.peek_messages(max_message_count=10):
        print(f"{msg.message_id}: {msg.dead_letter_reason}: {msg.dead_letter_error_description}")
```

```
ana@laptop:~/azure$ messaging/bin/python dead.py
order-42: MaxDeliveryCountExceeded: Message could not be consumed after 3 delivery attempts.
order-43: UnknownProduct: no such product in the catalogue
```

**Peeking reads a message without locking it**, so it changes nothing: run it twice and the same two
lines come back. The two reasons are the two ways in. `MaxDeliveryCountExceeded` is the queue's own,
with its sentence; `UnknownProduct` is the one `work.py` wrote. Microsoft's documentation suggests
putting the exception's type in the reason and its stack trace in the description, so that whoever
opens the subqueue later knows what failed. An alert on the subqueue's message count above
zero is how somebody finds out at all, which `azure-operations` lesson 8 builds with Azure Monitor.

## The same queue in Azure

In a subscription the queue is a resource of a namespace, and the two settings are flags of the
command that creates it. Not run in this course: it needs a subscription.

```sh
az servicebus namespace create --resource-group shop-rg --name shop-bus --sku Standard
az servicebus queue create --resource-group shop-rg --namespace-name shop-bus --name orders \
  --lock-duration PT30S --max-delivery-count 10
```

The Basic tier supports queues only; topics, which the next section uses, need Standard or Premium.
**A lock is a lease, and a long job has to renew it**: the library can renew it automatically, and
Microsoft's documentation advises a lock duration longer than the normal processing time, so that
renewal is the exception. A lock is also lost with the connection that holds it, and settling a
message after that fails; the documented answer is to receive the message again rather than retry
the settlement.

Leave the emulator running: the next section uses it.
