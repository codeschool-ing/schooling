---
title: "Event Hubs: a log that every reader walks at its own pace"
version: 1
---

Event Hubs takes events in, like the other two, and so it is tempting to read it as a queue that
copes with more of them. **Reading from an event hub removes nothing and settles nothing.** An event
hub is an append-only log, split into **partitions**; each event is written at the end of one of them
and stays there until its retention time is up, an hour by default on the Standard tier and at most
seven days. A reader is a position in the log, not a lock on a message. Two applications read the
same events through two **consumer groups**, each with its own positions, and neither can take an
event away from the other. Where a reader got to is the reader's own business, and saving it is
called **checkpointing**.

## The emulator, with storage beside it

The Event Hubs emulator is another Microsoft image, and the storage it needs is Azurite, the Azure
Storage emulator. Its declaration names one event hub, `orders`, with two partitions and two consumer
groups of the shop's own; a third, `$Default`, exists on every event hub without being declared. Save
it as `~/azure/eventhubs/Config.json`:

```json
{
  "UserConfig": {
    "NamespaceConfig": [
      {
        "Type": "EventHub",
        "Name": "emulatorNs1",
        "Entities": [
          {
            "Name": "orders",
            "PartitionCount": "2",
            "ConsumerGroups": [
              {
                "Name": "billing"
              },
              {
                "Name": "analytics"
              }
            ]
          }
        ]
      }
    ],
    "LoggingConfig": {
      "Type": "Console"
    }
  }
}
```

And the two containers as `~/azure/eventhubs/compose.yaml`. Port 10000 is Azurite's blob service,
which the checkpoints will use:

```yaml
# eventhubs/compose.yaml
name: eventhubs
services:
  emulator:
    container_name: eventhubs-emulator
    image: mcr.microsoft.com/azure-messaging/eventhubs-emulator:2.2.1
    volumes:
      - ./Config.json:/Eventhubs_Emulator/ConfigFiles/Config.json
    ports:
      - "5672:5672"
      - "5300:5300"
    environment:
      BLOB_SERVER: azurite
      METADATA_SERVER: azurite
      ACCEPT_EULA: "Y"
    depends_on:
      - azurite
  azurite:
    container_name: azurite
    image: mcr.microsoft.com/azure-storage/azurite:3.37.0
    ports:
      - "10000:10000"
```

The connection string is the Service Bus emulator's, character for character, because both
emulators answer on `localhost:5672`, which is also why only one of them can run at a time. The
storage one is Azurite's published development account, the same on every machine:

```
ana@laptop:~/azure$ docker compose -f eventhubs/compose.yaml up -d
 Network eventhubs_default Creating 
 Network eventhubs_default Creating 
 Network eventhubs_default Created 
 Network eventhubs_default Created 
 Container azurite Creating 
 Container azurite Created 
 Container eventhubs-emulator Creating 
 Container eventhubs-emulator Created 
 Container azurite Starting 
 Container azurite Started 
 Container eventhubs-emulator Starting 
 Container eventhubs-emulator Started 
ana@laptop:~/azure$ until curl -sf localhost:5300/health; do sleep 2; done; echo
{"status":"healthy","message":"Service is healthy."}
ana@laptop:~/azure$ export EVENTHUBS="Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
ana@laptop:~/azure$ export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
```

## Partitions and the partition key

The producer sends each step of an order with the order as its **partition key**. Event Hubs hashes
the key to choose a partition, so every event with the same key lands in the same partition, in the
order it was sent. Save it as `~/azure/produce.py`:

```python
# produce.py
import json
import os
import sys

from azure.eventhub import EventData, EventHubProducerClient

producer = EventHubProducerClient.from_connection_string(os.environ["EVENTHUBS"], eventhub_name="orders")
with producer:
    for arg in sys.argv[1:]:
        order, step = arg.split(":")
        batch = producer.create_batch(partition_key=f"order-{order}")
        batch.add(EventData(json.dumps({"order": int(order), "step": step})))
        producer.send_batch(batch)
        print(f"sent order {order} {step}")
```

The reader takes a consumer group's name and reads every partition from the start of the log, the
position `"-1"`. A consumer never ends on its own, so this one closes itself after five seconds. Save
it as `~/azure/consume.py`:

```python
# consume.py
import os
import sys
import threading

from azure.eventhub import EventHubConsumerClient

group = sys.argv[1]
consumer = EventHubConsumerClient.from_connection_string(os.environ["EVENTHUBS"], consumer_group=group, eventhub_name="orders")


def on_event(partition_context, event):
    print(f"{group}: partition {partition_context.partition_id} seq {event.sequence_number}: {event.body_as_str()}")


threading.Timer(5, consumer.close).start()
with consumer:
    consumer.receive(on_event=on_event, starting_position="-1")
```

Six events for three orders, then both consumer groups read. Each read goes through `sort`, because
the partitions are read side by side and the order *between* them is not defined: it differs from run
to run, and the order within each is the one worth looking at.

```
ana@laptop:~/azure$ messaging/bin/python produce.py 42:paid 43:paid 42:packed 43:packed 42:shipped 44:paid
sent order 42 paid
sent order 43 paid
sent order 42 packed
sent order 43 packed
sent order 42 shipped
sent order 44 paid
ana@laptop:~/azure$ messaging/bin/python consume.py billing | sort
billing: partition 0 seq 0: {"order": 42, "step": "paid"}
billing: partition 0 seq 1: {"order": 42, "step": "packed"}
billing: partition 0 seq 2: {"order": 42, "step": "shipped"}
billing: partition 0 seq 3: {"order": 44, "step": "paid"}
billing: partition 1 seq 0: {"order": 43, "step": "paid"}
billing: partition 1 seq 1: {"order": 43, "step": "packed"}
ana@laptop:~/azure$ messaging/bin/python consume.py analytics | sort
analytics: partition 0 seq 0: {"order": 42, "step": "paid"}
analytics: partition 0 seq 1: {"order": 42, "step": "packed"}
analytics: partition 0 seq 2: {"order": 42, "step": "shipped"}
analytics: partition 0 seq 3: {"order": 44, "step": "paid"}
analytics: partition 1 seq 0: {"order": 43, "step": "paid"}
analytics: partition 1 seq 1: {"order": 43, "step": "packed"}
```

**Each order kept to one partition, and kept its order there**: `paid`, `packed`, `shipped` for order
42 in partition 0 with sequence numbers 0, 1 and 2. Order 43 hashed to the other partition, and order
44 to the same one as 42; a key decides *which* partition, never that it has one to itself. The
sequence number counts from 0 within each partition and means nothing across them. **And `analytics`
read exactly what `billing` had read**, from the beginning, because reading took nothing out: the
events are still in the log for anyone else who asks.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"The event hub orders as two partitions, each a row of events in the order they were written. Partition 0 holds order 42 paid, packed and shipped, then order 44 paid, sequence numbers 0 to 3. Partition 1 holds order 43 paid, packed and shipped, sequence numbers 0 to 2. New events are appended at the right. The consumer group billing has a checkpoint after the last event of each partition. The consumer group analytics has none and reads from the start.\"><defs><marker id=\"log-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"log-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"16\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-weight=\"600\">partition 0</text><text x=\"166.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 0</text><rect x=\"120\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"166.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">42 paid</text><text x=\"264.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 1</text><rect x=\"218\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"264.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">42 packed</text><text x=\"362.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 2</text><rect x=\"316\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"362.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">42 shipped</text><text x=\"460.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 3</text><rect x=\"414\" y=\"50\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"460.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">44 paid</text><path d=\"M509.0 44 L509.0 90\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"515.0\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">billing</text><text x=\"515.0\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">checkpoint</text><path d=\"M116 44 L116 90\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></path><text x=\"16\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-weight=\"600\">partition 1</text><text x=\"166.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 0</text><rect x=\"120\" y=\"140\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"166.0\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43 paid</text><text x=\"264.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 1</text><rect x=\"218\" y=\"140\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"264.0\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43 packed</text><text x=\"362.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">seq 2</text><rect x=\"316\" y=\"140\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"362.0\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43 shipped</text><path d=\"M411.0 134 L411.0 180\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"417.0\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">billing</text><text x=\"417.0\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">checkpoint</text><path d=\"M116 134 L116 180\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></path><path d=\"M570 65 L650 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#log-p)\"></path><text x=\"610\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new events</text><text x=\"610\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">go on the end</text><text x=\"116\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">analytics</text><text x=\"180\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no checkpoint: reads from the start</text></svg>", "caption": "Two partitions, each in the order it was written, and two consumer groups with positions of their own. Reading moved nothing: the events stay until their retention ends."}
```

The number of partitions is fixed when the event hub is created, and on the Standard tier it stays
fixed. The Premium and Dedicated tiers can add partitions later, and doing so moves keys to new
partitions, which breaks the order of anything in flight. **It is also the most readers a consumer group can
usefully have**, since within a group one reader owns a partition at a time: two partitions, as here,
means at most two billing workers sharing the load.

## Checkpoints: where a reader got to

`consume.py` started from the beginning every time, which is right for a report and wrong for
billing, which must charge each order once. The library keeps a reader's position in a **checkpoint
store**, a blob container, and Azurite provides one. Create the container with the Azure CLI, which
works against Azurite without signing in, because the connection string carries the key:

```
ana@laptop:~/azure$ az storage container create --name checkpoints
{
  "created": true
}
```

Save the reader that checkpoints as `~/azure/checkpoint.py`:

```schooling-example
{"language": "python", "file": "checkpoint.py", "parts": [{"code": "# checkpoint.py\nimport os\nimport sys\nimport threading\n\nfrom azure.eventhub import EventHubConsumerClient\nfrom azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore\n\ngroup = sys.argv[1]\nsave = sys.argv[2:] != [\"nocheckpoint\"]\nstore = BlobCheckpointStore.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"], container_name=\"checkpoints\")\nconsumer = EventHubConsumerClient.from_connection_string(os.environ[\"EVENTHUBS\"], consumer_group=group, eventhub_name=\"orders\", checkpoint_store=store)\n", "note": "The same consumer as before, given a checkpoint store: the container `checkpoints` in Azurite. With a store, the library also shares the partitions out among every reader of the group that is running, through the same container."}, {"code": "\n\ndef on_event(partition_context, event):\n    print(f\"{group}: partition {partition_context.partition_id} seq {event.sequence_number}: {event.body_as_str()}\")\n    if save:\n        partition_context.update_checkpoint(event)\n", "note": "The work, here a line printed, and then the checkpoint: this partition's reader has finished this event. Given `nocheckpoint`, it does the work and saves nothing."}, {"code": "\n\nthreading.Timer(10, consumer.close).start()\nwith consumer:\n    consumer.receive(on_event=on_event, starting_position=\"-1\")\n", "note": "`\"-1\"` now applies only to a partition with no checkpoint yet; one that has a checkpoint starts after it. Ten seconds rather than five, because claiming the partitions through the store takes a few."}]}
```

It is run twice, then one more event is sent, and a run that does the work and stops before
checkpointing is followed by one that checkpoints:

```
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing | sort
billing: partition 0 seq 0: {"order": 42, "step": "paid"}
billing: partition 0 seq 1: {"order": 42, "step": "packed"}
billing: partition 0 seq 2: {"order": 42, "step": "shipped"}
billing: partition 0 seq 3: {"order": 44, "step": "paid"}
billing: partition 1 seq 0: {"order": 43, "step": "paid"}
billing: partition 1 seq 1: {"order": 43, "step": "packed"}
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing | sort
ana@laptop:~/azure$ messaging/bin/python produce.py 43:shipped
sent order 43 shipped
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing nocheckpoint
billing: partition 1 seq 2: {"order": 43, "step": "shipped"}
ana@laptop:~/azure$ messaging/bin/python checkpoint.py billing
billing: partition 1 seq 2: {"order": 43, "step": "shipped"}
```

The first run read all six events, from the start of each partition, because no checkpoint existed
yet, and saved one after each. The second read nothing: both partitions now had a checkpoint, and
nothing had been written after it.
**The `nocheckpoint` run is a consumer that crashed after doing its work**, and the run after it read
the same event again. That is not a fault of the emulator or of the library: the position is saved
after the work, so there is always a moment in which the work is done and the position is not, and a
crash in that moment means a second delivery. Saving the position *before* the work moves the hole to
the other side, a crash that loses the event. The checkpoints themselves are blobs, whose
metadata holds the sequence number and the offset of the last event each partition's reader finished:

```
ana@laptop:~/azure$ az storage blob list --container-name checkpoints --include m --query "[?contains(name, 'checkpoint')].{name: name, seq: metadata.sequencenumber, offset: metadata.offset}" --output table
Name                                   Seq    Offset
-------------------------------------  -----  --------
localhost/orders/billing/checkpoint/0  3      432
localhost/orders/billing/checkpoint/1  2      288
```

Stop the emulator when you are done:

```
ana@laptop:~/azure$ docker compose -f eventhubs/compose.yaml down
 Container eventhubs-emulator Stopping 
 Container eventhubs-emulator Stopped 
 Container eventhubs-emulator Removing 
 Container eventhubs-emulator Removed 
 Container azurite Stopping 
 Container azurite Stopped 
 Container azurite Removing 
 Container azurite Removed 
 Network eventhubs_default Removing 
 Network eventhubs_default Removed 
```

## Queue, event, stream

| | Service Bus | Event Grid | Event Hubs |
| --- | --- | --- | --- |
| what it carries | a message: work somebody must do | an event: news of something that happened | a stream: a series of events, kept |
| how it reaches the consumer | the consumer receives, and settles | Event Grid pushes it to the handler | the consumer reads from a position |
| after it is handled | gone, once completed | gone, once delivered | still there until retention ends |
| several consumers | competing on a queue, a copy per subscription on a topic | a copy per event subscription | a full view per consumer group |
| order | per session | none promised | per partition |
| when it cannot be handled | dead-letter subqueue | dead-letter container, if set | nothing: the reader decides |

The shop uses all three, each for what it is. Service Bus carries orders, which must be charged and
shipped exactly as many times as they were paid. Event Grid carries notices: a large order needs a
person, the nightly sales report has landed in a storage account. Event Hubs carries the stream of
every click and page view the site produces, read by a report and by fraud checks at their own pace.

## At least once, so the handler decides

**All three deliver at least once.** Two second deliveries were on screen in this lesson, a lock
that ran out and a reader that stopped before its checkpoint, and Event Grid's documentation names
its own, a retry after an answer that came too late. Duplicate
detection in Service Bus removes the sender's repeats within a window, and nothing removes the
consumer's. So the consumer is written to be **idempotent**: handling the same message twice has the
effect of handling it once.

The way to do it is a key that names the piece of work, carried in the message, and a record of the
keys already done, kept in a store that outlives any message. The `MessageId` of the first section,
`order-41`, is one such key; the `id` of a CloudEvent is another; an event hub's events carry the
order and the step. Billing inserts `charge-42` into a table where that column is unique, inside the
same transaction as the charge, and a second insert fails, so the second copy is recognised and
skipped. **The uniqueness is checked by the database, not by the program**, which is what keeps two
workers holding two copies at the same moment from both winning.
