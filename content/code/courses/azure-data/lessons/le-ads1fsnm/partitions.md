---
title: An event hub is a set of partitions
version: 1
---

**An event hub is not one queue.** It is a fixed number of **partitions**, and each partition is an
ordered log of its own: events are appended at its end, kept for a period of time, and read from any
point in it. An event sent to the hub goes into exactly one partition. Everything else in this
lesson, ordering, reading, checkpoints and price, is a property of the partition rather than of the
hub, so the partition is where to start.

Three names come first, because Azure's documentation uses all three in one sentence. A
**namespace** is the resource you create and pay for, with an address of its own such as
`evhns-quitanda-app-prd.servicebus.windows.net`; it holds the capacity. An **event hub** lives inside
a namespace and is what a producer sends to; Kafka users would call it a topic. A **partition** lives
inside an event hub. Quitanda's app sends its clicks to one event hub, `clicks`, in one namespace.

## Starting the emulator

The Event Hubs emulator came with the lab in lesson 1: `compose.yaml` names it under the profile
`eventhubs`, and `eventhubs/config.json` declares one namespace, `emulatorNs1`, with one event hub,
`clicks`, of four partitions and one extra consumer group, `fraud`. **The emulator keeps its own
bookkeeping in Azurite**, which is why Compose starts Azurite first. In `~/azure`, with the
terminal prepared as lesson 1 says:

```
ana@laptop:~/azure$ docker compose --profile eventhubs up -d 2>&1 | tail -1
 Container azure-eventhubs-1 Started 
```

The line comes back at once and the emulator is not ready yet: it is ready when its log says so,
which takes a few seconds more.

```
ana@laptop:~/azure$ docker compose logs eventhubs 2>&1 | grep -o 'Emulator Service is Successfully Up!' | head -1
Emulator Service is Successfully Up!
```

The programs in this lesson find it through one variable, which you export in the same terminal:

```sh
export EVENTHUB_CONNECTION_STRING='Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;'
```

**That is the emulator's own connection string, published by Microsoft and the same on every
computer.** `SAS_KEY_VALUE` is literally the key; the emulator checks nothing. On Azure the same
string carries the namespace's address and a real shared access key, and `UseDevelopmentEmulator`
is absent. Lesson 6 is about what such a key gives to whoever holds it, and it applies here word for
word.

The command line has commands for Event Hubs too, `az eventhubs`, and they are no use here. They
manage namespaces and hubs, which is Azure Resource Manager, the control plane, and lesson 1 showed
what the command line does with a question no emulator answers:

```
ana@laptop:~/azure$ az eventhubs eventhub show -g rg-quitanda-stream-prd --namespace-name evhns-quitanda-app-prd -n clicks 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

## Four partitions, empty

This program asks the hub about each of its partitions. Save it as `partitions.py`:

`partitions.py`:

```python
import os

from azure.eventhub import EventHubProducerClient

hub = EventHubProducerClient.from_connection_string(
    os.environ["EVENTHUB_CONNECTION_STRING"], eventhub_name="clicks")
with hub:
    for pid in hub.get_partition_ids():
        p = hub.get_partition_properties(pid)
        print(f"partition {pid}  first {p['beginning_sequence_number']:>2}  "
              f"last {p['last_enqueued_sequence_number']:>2}  "
              f"last offset {p['last_enqueued_offset']:>4}  empty {p['is_empty']}")
```

```
ana@laptop:~/azure$ python partitions.py
partition 0  first -1  last -1  last offset   -1  empty True
partition 1  first -1  last -1  last offset   -1  empty True
partition 2  first -1  last -1  last offset   -1  empty True
partition 3  first -1  last -1  last offset   -1  empty True
```

**The partitions are named `0` to `3`, as strings, and each one is empty.** `-1` is how the service
says "no event yet". The two numbers it reports, the sequence number and the offset, are the two ways
of naming a position in a partition, and the next section reads them.

## Sending clicks, keyed by customer

Quitanda's app sends one event per tap. Save this as `send_clicks.py`:

```schooling-example
{"language": "python", "file": "send_clicks.py", "parts": [
{"code": "import json\nimport os\nimport sys\n\nfrom azure.eventhub import EventData, EventHubProducerClient\n\n", "note": "`azure-eventhub` is Microsoft's library for Event Hubs, installed into the lab's virtual environment in lesson 1. It speaks AMQP, the protocol the service is built on, to port 5672."},
{"code": "CLICKS = [\n    (\"c-17\", \"/fruit\"), (\"c-02\", \"/search?q=banana\"), (\"c-17\", \"/fruit/banana\"),\n    (\"c-05\", \"/bakery\"), (\"c-02\", \"/cart\"), (\"c-17\", \"/cart\"),\n    (\"c-03\", \"/dairy\"), (\"c-05\", \"/cart\"), (\"c-17\", \"/checkout\"), (\"c-03\", \"/cart\"),\n]\n\n", "note": "Ten taps by four customers, in the order they happened. `c-17` browses fruit, buys a banana and checks out; the others wander."},
{"code": "first = int(sys.argv[1]) if len(sys.argv) > 1 else 1\nhub = EventHubProducerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], eventhub_name=\"clicks\")\n", "note": "Each click is numbered from `first`, so that a second run, `python send_clicks.py 11`, sends the same taps numbered 11 to 20 and the two runs can be told apart."},
{"code": "with hub:\n    for n, (customer, page) in enumerate(CLICKS, first):\n        body = json.dumps({\"n\": n, \"customer\": customer, \"page\": page})\n        hub.send_event(EventData(body), partition_key=customer)\nprint(f\"sent clicks {first} to {first + len(CLICKS) - 1}\")\n", "note": "**The partition key is the customer.** The service hashes the key and the hash picks the partition, so every click of one customer lands in the same one. The body is a line of JSON, and Event Hubs never looks inside it."}
]}
```

```
ana@laptop:~/azure$ python send_clicks.py
sent clicks 1 to 10
ana@laptop:~/azure$ python partitions.py
partition 0  first  0  last  1  last offset  144  empty False
partition 1  first  0  last  1  last offset  152  empty False
partition 2  first -1  last -1  last offset   -1  empty True
partition 3  first  0  last  5  last offset  728  empty False
```

**Ten clicks, four customers, four partitions, and one partition got nothing.** Partition 3 holds six
events, numbered 0 to 5, partition 0 and partition 1 hold two each, and partition 2 is still empty.
Notice what the producer did not learn: `send_event` returned nothing, and the program has no idea
where its clicks went. It took a second question to the hub to find out, and the reading program in
the next section says which customer is where.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Four customers&#x27; keys hashed onto the four partitions of the event hub clicks. c-05 goes to partition 0, which holds clicks 4 and 8. c-02 goes to partition 1, which holds clicks 2 and 5. Partition 2 receives nothing. c-17 and c-03 both go to partition 3, which holds clicks 1, 3, 6, 7, 9 and 10 in the order they were sent.\" data-fig=\"l22-partitions\"><text x=\"60\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition key</text><text x=\"240\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition: an ordered log</text><rect x=\"20\" y=\"36\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-05</text><line x1=\"102\" y1=\"49\" x2=\"220.0\" y2=\"49.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,49 220.0,52.0 220.0,46.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"20\" y=\"82\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-02</text><line x1=\"102\" y1=\"95\" x2=\"220.0\" y2=\"95.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,95 220.0,98.0 220.0,92.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"20\" y=\"128\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-17</text><line x1=\"102\" y1=\"141\" x2=\"220.4\" y2=\"184.9\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,187 219.3,187.7 221.4,182.1\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"20\" y=\"174\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-03</text><line x1=\"102\" y1=\"187\" x2=\"220.0\" y2=\"187.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,187 220.0,190.0 220.0,184.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"230\" y=\"30\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 0</text><rect x=\"340\" y=\"37\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#4</text><rect x=\"394\" y=\"37\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"417\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#8</text><rect x=\"230\" y=\"76\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 1</text><rect x=\"340\" y=\"83\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#2</text><rect x=\"394\" y=\"83\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"417\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#5</text><rect x=\"230\" y=\"122\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 2</text><text x=\"345\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing yet</text><rect x=\"230\" y=\"168\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 3</text><rect x=\"340\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#1</text><rect x=\"394\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"417\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#3</text><rect x=\"448\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"471\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#6</text><rect x=\"502\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#7</text><rect x=\"556\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"579\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#9</text><rect x=\"610\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"633\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#10</text></svg>", "caption": "The hash of the key picks one partition per customer; two customers share partition 3 and partition 2 is left empty."}
```

## What the partition key decides

**The key decides two things at once, and they pull in opposite directions.** Every event with the
same key goes to the same partition, so the key is the unit of order: one customer's clicks are read
back in the order they were sent. And the key is the unit of spread: the partitions share the load
only as evenly as the keys share the hash. Four keys over four partitions is too few to spread, and
the run above shows it: two of the four customers hashed to partition 3. With Quitanda's tens of
thousands of customers the hashes even out; keyed by store, with three stores, at most three
partitions of the hub would ever receive anything.

The hash is computed by the service, and a producer has no way to choose the partition through the
key. A producer can bypass it in two ways. It can name a partition directly, with `partition_id`
instead of `partition_key`, which makes the producer responsible for spreading the load. Or it can
send with neither, and then the service spreads events over the partitions itself, keeping no order
between them.

**The two choices behave differently when a partition is unavailable**, and Microsoft's
documentation is explicit about it. An event with no key is sent to a partition that is up, so a
send succeeds while some partition is being moved or repaired. An event with a key, or with a named
partition, has exactly one place to go, so the send waits or fails until that partition is back. A
key buys order and pays for it in availability. Choose it as the smallest thing whose events must
stay in order, and send with no key at all when nothing needs to.

**The number of partitions is chosen when the hub is created**, and on the Basic and Standard tiers
it cannot be changed afterwards. Premium and Dedicated allow it to be increased, never decreased, and
the documentation warns about the consequence: with more partitions the hash maps a key to a
different partition, so a key's old events and its new ones are in two logs, and the order between
them is lost at that moment. The last section of this lesson puts partitions against price.
