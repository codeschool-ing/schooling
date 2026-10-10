---
title: Clocks that lie
version: 1
---

**Event time is only as good as the clock that wrote it, and the clock that writes it belongs to a
device you do not run.** Everything in the last three sections assumed that each till knows what
time it is. Most do. The ones that do not are not rare, and they fail in ways an event-time
pipeline amplifies rather than absorbs.

The ways a till's clock goes wrong are few and well known:

- **It drifts.** A cheap crystal gains or loses a second or two a day. Left alone for a year, a
  till is minutes out, and nobody notices because the receipt still prints.
- **It resets.** A dead clock battery and a power cut, and the till boots believing it is 1 January
  2000, or 1970. Every sale it makes is a quarter of a century late.
- **Its time zone is wrong.** A till set to UTC that writes its reading with `-03:00` on the end
  claims every sale happened three hours later than it did, consistently, all day.
- **Somebody sets it by hand**, to the wall clock, which is itself five minutes fast.

A clock that is **behind** makes its sales look late, and they are handled like Natal's. A clock
that is **ahead** is worse. Its sales claim to come from the future, and anything in the pipeline
that tracks "how far has time got" by the latest event time seen, which lesson 11's watermark
does, jumps forward with them. Every honest sale after that looks late by comparison. One till an
hour fast can make the whole chain's results wrong for an hour.

## The guard Kafka has

Kafka checks the record's timestamp against the broker's own clock, and since Kafka 4.0 it refuses
by default **any record stamped more than an hour in the future**. The topic setting is
`message.timestamp.after.max.ms`, 3,600,000 milliseconds unless changed. Its partner,
`message.timestamp.before.max.ms`, would refuse records too far in the past, and by default it
allows any age at all, which is why the March timestamps of the last sections were accepted.

To see the guard, this program sends one sale from a till whose clock is a given number of hours
ahead of the real one. Save it as `~/work/clock_ahead.py`:

```python
"""clock_ahead.py: one sale from a till whose clock is HOURS ahead of the broker's."""
import json
import sys
import time

from confluent_kafka import Producer

hours, topic = float(sys.argv[1]), sys.argv[2]
stamp = int((time.time() + hours * 3600) * 1000)

def report(err, msg):
    print(f"{hours:+} h: " + (f"refused, {err.str()}" if err else
          f"stored at offset {msg.offset()}, timestamp {msg.timestamp()}"))

producer = Producer({"bootstrap.servers": "localhost:9092"})
producer.produce(topic, key="caruaru", value=json.dumps({"shop": "caruaru"}),
                 timestamp=stamp, on_delivery=report)
producer.flush()
```

Two hours ahead and half an hour ahead, to the `clocks` topic, which keeps `CreateTime`:

```
ubuntu@stream:~/work$ python clock_ahead.py 2 clocks
+2.0 h: refused, Broker: Invalid timestamp
ubuntu@stream:~/work$ python clock_ahead.py 0.5 clocks
+0.5 h: stored at offset 2, timestamp (1, 1791621242883)
```

The two-hour clock is refused, and the producer is told why. The half-hour one is stored, inside
the hour of tolerance, with the timestamp the till claimed. On the `appended` topic the same
two-hour clock gets through:

```
ubuntu@stream:~/work$ python clock_ahead.py 2 appended
+2.0 h: stored at offset 2, timestamp (2, 1791619443040)
```

**`LogAppendTime` skips the check because it discards the producer's timestamp anyway**; the
pair printed says type 2, log-append, and the number is the broker's present. Neither topic looked
inside the message. Kafka never reads the sale's `at`, and a till could write any date there at
all.

## What a pipeline can do

**Synchronise the devices.** Every till runs NTP, which keeps a clock within milliseconds of a
time server; on Ubuntu, `timedatectl` shows whether it is on and synchronised. That command was not
run for this course: the machine it was recorded on is a container that takes its clock from the
host and has no clock of its own to set. On your virtual machine, run it once and read the line
about synchronisation.

**Keep both clocks.** A record whose `at` is the till's clock and whose timestamp is the broker's
carries its own evidence. A sale whose event time is later than its arrival is impossible: nothing
arrives before it happens. The difference between the two is the skew of the last sections, and
the same subtraction catches a lying clock.

**Bound what you believe.** A processor can refuse to let an event time run ahead of the arrival
by more than a tolerance, and clamp it there:

```python
def believed(at, arrived, tolerance=timedelta(minutes=1)):
    return min(at, arrived + tolerance)
```

Those two lines are a sketch, not a program you run. Clamping keeps one bad till from moving
everybody's clock forward, at the price of filing its sales under the wrong minute. The other
choice is to set such events aside, on a topic of their own, for somebody to look at; lesson 11
does that with events that arrive too late, and the same mechanism serves for events that claim
to be too early.
