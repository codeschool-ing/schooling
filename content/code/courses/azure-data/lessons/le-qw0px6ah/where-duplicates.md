---
title: Where duplicates come from
version: 1
---

**A duplicate is not a fault of the stream; it is what a correct retry produces.** Four places make
them, and only one of the four is a reader crashing. This section names all four and runs the first.

The emulator of lesson 22, started the same way, and the variable it needs:

```
ana@laptop:~/azure$ docker compose --profile eventhubs up -d 2>&1 | tail -1
 Container azure-eventhubs-1 Started 
```

```sh
export EVENTHUB_CONNECTION_STRING='Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;'
```

## The producer that retries

Quitanda's shop sends one event per paid order. The lab has one event hub, `clicks`, and the
payments go to it: Event Hubs never looks inside an event, so a hub named for clicks carries
payments exactly as well. Save this as `pay.py`:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [
{"code": "import json\nimport os\n\nfrom azure.eventhub import EventData, EventHubProducerClient\n\n", "note": "The library of lesson 22."},
{"code": "PAYMENTS = [\n    (\"o-301\", \"c-17\", 4590), (\"o-302\", \"c-02\", 12800), (\"o-303\", \"c-17\", 990),\n    (\"o-304\", \"c-05\", 2350), (\"o-305\", \"c-02\", 1500), (\"o-306\", \"c-17\", 7200),\n]\nRETRIED = {\"o-303\"}\n\n", "note": "Six payments, in cents, for three customers. **The order id is what makes a payment the same payment**: an order is paid once, so a second event for one order is a duplicate whatever caused it. `o-303` will be sent twice."},
{"code": "hub = EventHubProducerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], eventhub_name=\"clicks\")\nwith hub:\n    for order, customer, cents in PAYMENTS:\n        body = json.dumps({\"order\": order, \"customer\": customer, \"cents\": cents})\n        for _ in range(2 if order in RETRIED else 1):\n            hub.send_event(EventData(body), partition_id=\"0\")\n            print(f\"sent {order} {customer} {cents:>6}\")\n", "note": "**The second send of `o-303` is what a producer does when its first send timed out**: the answer did not come back, so it cannot tell whether the event was stored, and it sends again. Everything goes to partition 0, so the reader of the next section has one log to read."}
]}
```

```
ana@laptop:~/azure$ python pay.py
sent o-301 c-17   4590
sent o-302 c-02  12800
sent o-303 c-17    990
sent o-303 c-17    990
sent o-304 c-05   2350
sent o-305 c-02   1500
sent o-306 c-17   7200
```

**Seven events for six payments.** The service stored both copies of `o-303`, as two events with two
sequence numbers, because it has no way to know they are one payment: it does not compare events and
does not look inside them. The correct totals are the sums of the six: 12,780 cents for `c-17`,
14,300 for `c-02` and 2,350 for `c-05`. Those are the numbers to compare against in the rest of the
lesson.

A producer can only avoid this by not retrying, which turns a lost answer into a lost payment. The
client libraries retry on their own when a send fails for a reason they consider temporary, so a
producer that never wrote a retry still has one.

## The reader that crashes

The second place is the one the next section runs. **A reader that handled events and died before
checkpointing them handles them again when it restarts**, from its previous checkpoint. How many
come back is how many it handled since that checkpoint: a reader that checkpoints every hundred
events replays up to ninety-nine.

## The partition that changes hands

**Load balancing makes duplicates without any crash.** Lesson 22 showed the ownership blobs: copies
of a reader in one consumer group split the partitions between them. When a copy is added, removed
or restarted, a partition moves from one owner to another, and the new owner starts from the last
checkpoint, the same place a restarted reader would. Whatever the old owner handled after that
checkpoint, it handled once and the new owner handles again. A deployment that restarts the copies
one by one, as rolling deployments do, moves partitions several times in a few minutes.

## The service that retries for you

**A managed reader retries too, and it says so.** The Event Hubs trigger of Azure Functions hands a
function a batch of events; Microsoft's documentation describes a function that fails or times out
as seeing the same batch again. Stream Analytics retries a write its output refused and documents its
delivery to outputs as at least once, so a row of the checkout counter can reach the SQL table twice.
Neither is a defect: both are the at-least-once promise kept.

## Two that are not duplicates

**A second event that looks like the first is not a duplicate.** `c-17` can pay 990 cents twice, for
two orders, on the same evening; a reader that removed "the same customer and the same amount"
would delete a real payment. What makes two events the same is an identity the producer gave them,
here the order id, never a resemblance between their contents. And **an event the producer sent
again with a new id is not one the reader can recognise**: if the shop gave each send its own fresh
id, the two copies of `o-303` would look like two orders to everybody downstream. The identity has to
be fixed before the first send, which is why the order id, decided when the order was placed, is the
right one.
