---
title: Delivery guarantees, and a crash in the wrong place
version: 1
---

**A consumer does two things for every batch of events: it does the work, and it commits the offset.
Which of the two comes first decides what a crash between them costs.** The guarantee a system offers
is the name for that cost.

- *At most once*: commit the offset first, then do the work. A crash in between loses the batch: on
  restart the offset says it was read, so nobody reads it again. Nothing is counted twice, and some
  things are never counted.
- *At least once*: do the work first, then commit. A crash in between repeats the batch: on restart
  the offset still points before it, so it is read and processed again. Nothing is lost, and some things
  are counted twice.
- *Exactly once* is what everybody wants and what no network can promise about *delivery*, because a
  sender that hears nothing back cannot tell a lost message from a lost reply. What a system can promise
  is that the *effect* happens once, and that is usually called **effectively once**.

`consumer.py` from section 04 is an at-least-once consumer: it writes `rides.json` first and
commits `offset.txt` second. The `--crash` flag stops it between the two, which is where a power cut, a
deployment or an out-of-memory kill can land at any moment. Start from an empty state and crash the
second run:

```
ana@lab:~/roda/stream$ rm offset.txt rides.json
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 0 to 299; rides so far: 156
ana@lab:~/roda/stream$ python consumer.py 300 --crash
crashed before committing the offset
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 300 to 599; rides so far: 466
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 600 to 719; rides so far: 515
```

The crashed run had already written its count, 311, and never recorded that it had read offsets 300 to
599. The restart read them again and added their 155 rides a second time. The consumer finished with 515
rides on mornings that had 360, and **every run after the crash printed an ordinary line**. This is lesson
1's ride counted twice again, at the scale of a stream.

## Effectively once: make the repeat harmless

Two ways out exist, and both change the write rather than the delivery. One is to make the result and the
offset a single write, so a crash leaves both or neither: a database transaction can hold both, and some
stream processors store their offsets inside the same snapshot as their state for this reason. The other
is to make the work **idempotent**, so that doing it twice leaves the same result as doing it once.

The rides are easy to make idempotent, because every event has an id. Instead of adding one to a counter,
the consumer records *which* events it has counted, and an event processed twice is the same key written
twice. Save `stream/keyed.py`, which differs from `consumer.py` in the state it keeps and in its own two
files:

```python
# stream/keyed.py
import json
import sys

how_many = int(sys.argv[1])
crash = '--crash' in sys.argv


def load(path, empty):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return empty


offset = load('keyed-offset.txt', 0)
rides = load('keyed-rides.json', {})             # event id -> station
with open('docks.jsonl') as f:
    batch = f.readlines()[offset:offset + how_many]
for line in batch:
    e = json.loads(line)
    if e['kind'] == 'undock':
        rides[e['id']] = e['station']            # the same event twice is one key
with open('keyed-rides.json', 'w') as f:
    json.dump(rides, f)
if crash:
    sys.exit('crashed before committing the offset')
with open('keyed-offset.txt', 'w') as f:
    json.dump(offset + len(batch), f)
if batch:
    print(f'read offsets {offset} to {offset + len(batch) - 1};', 'rides so far:', len(rides))
else:
    print(f'nothing new at offset {offset}')
```

The same crash in the same place:

```
ana@lab:~/roda/stream$ python keyed.py 300
read offsets 0 to 299; rides so far: 156
ana@lab:~/roda/stream$ python keyed.py 300 --crash
crashed before committing the offset
ana@lab:~/roda/stream$ python keyed.py 300
read offsets 300 to 599; rides so far: 311
ana@lab:~/roda/stream$ python keyed.py 300
read offsets 600 to 719; rides so far: 360
```

The batch was still delivered twice, because the consumer is still at least once. The second delivery
changed nothing, and the count ends at 360.

**Idempotence is paid for in memory.** `keyed-rides.json` holds every ride id it has ever seen, and on a
stream that never ends it would never stop growing. A real deduplication keeps ids only for as long as a
duplicate can still arrive, which is the allowed lateness of the last section asked again about a
different thing. Lesson 9 meets the same idea where it costs most, in a request retried across a network.
