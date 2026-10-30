---
title: Tiers, throughput units and the Kafka door
version: 1
---

**This section is taught from Microsoft's documentation and was not run.** The emulator has no
tiers, no throughput limits and no bill; it accepted every click this lesson sent as fast as Python
could send them.

**The tier is chosen on the namespace and decides three things: how capacity is bought, what the hub
may hold, and which features exist.** Four tiers, and their documented differences:

| | Basic | Standard | Premium | Dedicated |
|---|---|---|---|---|
| capacity bought in | throughput units | throughput units | processing units | capacity units, on a cluster |
| longest retention | 1 day | 7 days | 90 days | 90 days |
| consumer groups per hub | 1 | 20 | 100 | 1,000 |
| partitions per hub | 32 | 32 | 100 | 1,024 |
| Capture | no | at an extra charge | included | included |
| Kafka endpoint | no | yes | yes | yes |

**Basic is a tier for a single reader**, because its one consumer group is `$Default`: Quitanda's
fraud check and lake copy could not both read it, so Basic is ruled out before price is mentioned.
Standard is where most workloads sit. Premium and Dedicated give a namespace resources that are not
shared with other customers, and they are the tiers where the partition count can grow.

## A throughput unit

**On Basic and Standard, capacity is a number of throughput units bought for the whole namespace**,
shared by every hub in it. The documentation defines one unit as up to 1 MB a second or 1,000 events
a second coming in, whichever is reached first, and up to 2 MB a second or 4,096 events a second
going out. A namespace sending in more than its units allow has its requests refused as busy, and
the client libraries retry them; the producer slows down rather than losing events, as long as it
keeps retrying.

Two consequences follow from the definition. **Readers count against the outgoing limit, once per
consumer group**: the fraud check and the lake copy each read every click, so the hub sends out
twice what came in. And the limit counts events as well as bytes, so a stream of many tiny events
can need units while moving very little data.

**Auto-inflate raises the units on a Standard namespace when traffic needs them**, up to a maximum
you set, which in the declaration of the previous section is six. It never lowers them again on its own,
and the documentation says so: after a busy evening the namespace stays at the higher count, and is
billed for it, until somebody or something lowers it. A monitored metric and a scheduled job that
puts the count back are the usual companions of the setting.

Premium and Dedicated do not count units this way. A processing unit of Premium and a capacity unit
of Dedicated buy a share of isolated resources, and how much traffic one carries depends on the
size of the events and the number of readers rather than on a fixed per-second number.

## The Kafka door

**A Standard, Premium or Dedicated namespace also speaks the Kafka protocol**, on port 9093 of the
same address, so a program written for Apache Kafka can send to and read from an event hub by
changing its configuration and not its code. The event hub plays the part of a Kafka topic, the
partitions are the topic's partitions, and the consumer groups are Kafka's consumer groups. Quitanda
has no Kafka programs, and this course does not use the protocol: the lab publishes only the
emulator's AMQP port, 5672, so this lesson does no more than name the door; it matters to a company moving an existing Kafka system onto Azure without
rewriting it.

## What Quitanda's clicks would cost

**The meters of a Standard namespace are throughput units by the hour, ingress events by the
million, and Capture by the throughput unit and hour.** An ingress event is counted per 64 KB of data,
so a click of half a kilobyte is one event. The arithmetic below uses illustrative prices, which are
round numbers for the sum and not Azure's: 0.03 USD per throughput unit-hour, 0.03 USD per million
ingress events, and 0.10 USD per throughput unit-hour for Capture.

Quitanda's app sends 150 clicks a second on average and 600 at the evening peak. The peak is 600
events and about 0.3 MB a second in, under one unit's 1,000 events; the two readers take 1,200 events
a second out, under one unit's 4,096. One unit is enough and two leave room for a promotion, so the
namespace has two, with auto-inflate as a ceiling:

| meter | quantity in a 30-day month | illustrative price | month |
|---|---|---|---|
| throughput units | 2 × 730 hours = 1,460 unit-hours | 0.03 USD | 43.80 USD |
| ingress events | 150 × 86,400 × 30 = 388.8 million | 0.03 USD per million | 11.66 USD |
| Capture | 1,460 unit-hours | 0.10 USD | 146.00 USD |
| | | | **201.46 USD** |

**At these numbers Capture is most of the bill, and it is billed per throughput unit**, so every unit
auto-inflate adds for a busy evening is paid twice, once for the hub and once for Capture. That is
the shape worth remembering whatever the real prices are: the cost of a Standard namespace follows
its unit count, and a unit count left high after a peak is the commonest waste. The alternative to
Capture, a reader of your own writing files, has a bill of its own, a machine or a function and the
storage writes, and the comparison is worth doing with real numbers.

For the real prices, the course's price sheet from lesson 1, with the network:

```sh
python prices.py "Event Hubs" Standard
```

It was not run for this course, as lesson 1 explains. Read the unit of each line before its price:
throughput units are priced per hour and ingress events per million.
