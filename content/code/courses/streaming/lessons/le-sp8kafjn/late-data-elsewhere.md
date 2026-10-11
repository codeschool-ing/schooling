---
title: Late data goes somewhere
version: 1
---

**A late event that is dropped in silence is a sale that never happened as far as every report is
concerned, and nobody can say how many there were.** The fix is not to accept everything; it is to
send what is too late somewhere it can be counted, inspected and, if it matters, put back.

Flink calls this a **side output**, `sideOutputLateData`: a second stream out of the same window
operator, holding exactly the events it refused. With Kafka as the transport the natural place is a
topic of its own, often called a dead-letter topic, a name borrowed from queues, which lesson 15
returns to. `watermark.py` does it with `--late-topic`. Make the topic and run it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-late --partitions 1
Created topic sales-late.
ubuntu@stream:~/work$ python watermark.py --late-topic sales-late
 #  happened  shop      watermark  what happened
 1  09:00:40  recife    08:58:40  
 2  09:02:10  natal     09:00:10  
 3  09:03:55  olinda    09:01:55  
 4  09:05:00  recife    09:03:00  
 5  09:06:20  natal     09:04:20  
 6  09:12:30  caruaru   09:10:30  
                              emit 09:00:00-09:05:00: 3 sales, 12470
                              emit 09:05:00-09:10:00: 2 sales, 12390
 7  09:13:05  recife    09:11:05  
 8  09:08:50  natal     09:11:05  too late for 09:05:00-09:10:00: sent to sales-late
 9  09:14:10  olinda    09:12:10  
10  09:21:00  recife    09:19:00  
                              emit 09:10:00-09:15:00: 3 sales, 12690
11  09:04:30  natal     09:19:00  too late for 09:00:00-09:05:00: sent to sales-late
12  09:23:10  olinda    09:21:10  
still open: 09:20:00 (2)
```

The same two sales as before are too late, and this time the line says where they went. Each was
sent with the watermark it lost to, which is the evidence somebody will want later: not only that
it was late, but by how much.

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-late --from-beginning --max-messages 2
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
{"at": "09:08:50", "shop": "natal", "cents": 8990, "watermark": "09:11:05"}
{"at": "09:04:30", "shop": "natal", "cents": 4490, "watermark": "09:19:00"}
Processed a total of 2 messages
```

## What happens to them next

A topic of late sales is useful only if something reads it. Three things usually do:

- **A count, watched.** The number of late events per hour is the most direct measure of whether
  the bound fits the stream. A day with a hundred times the usual count means a till, a network or
  a clock went wrong, and it is the alert lesson 9's false "Natal sold nothing" was standing in for.
- **A correction, later.** The nightly batch from lesson 1 reads the whole day, late sales
  included, and produces the complete numbers. The stream answered quickly and almost right; the
  batch answers the next morning and exactly. Most platforms that use watermarks keep both, for
  this reason.
- **A person, sometimes.** A late sale from three weeks ago, or one stamped in the future as in
  lesson 9's lying clocks, is a question about a device, and the late topic is where somebody finds
  it.

**The point is that late data stops being invisible.** Dropping it and counting it are the same
cost to the stream processor, and only one of them leaves a trail.
