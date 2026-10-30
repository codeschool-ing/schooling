---
title: Reading a partition, by sequence number and offset
version: 1
---

**A reader of an event hub does not take events out of it.** It reads a partition from a position it
chooses, and the events stay where they were, for every other reader and for itself the next time.
They leave the partition when they are older than the hub's **retention**, a period of time set on
the hub, and for no other reason. Whoever has used a queue expects a read to remove a message; the
first thing to unlearn here is that reading an event hub changes nothing in it.

## A reader

This program reads every partition of `clicks` from the beginning, for five seconds, and prints what
it found. Save it as `read_clicks.py`:

```schooling-example
{"language": "python", "file": "read_clicks.py", "parts": [
{"code": "import json\nimport os\nimport sys\nimport threading\nimport time\n\nfrom azure.eventhub import EventHubConsumerClient\n\n", "note": "The same library as the sender, and its other half: `EventHubConsumerClient` reads."},
{"code": "group = sys.argv[1] if len(sys.argv) > 1 else \"$Default\"\nstart = sys.argv[2] if len(sys.argv) > 2 else \"-1\"\nclient = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=group, eventhub_name=\"clicks\")\nseen = []\n\n", "note": "**A reader always reads as a member of a consumer group**, and every hub has one called `$Default`. The next section is about groups. The second argument is where to start in each partition: `-1` means the oldest event the partition still keeps."},
{"code": "def on_event(partition, event):\n    click = json.loads(event.body_as_str())\n    seen.append((partition.partition_id, event.sequence_number, event.offset,\n                 event.partition_key.decode(), click[\"n\"], click[\"page\"]))\n\ndef on_error(partition, error):\n    print(\"error:\", type(error).__name__, error)\n\n", "note": "The library calls `on_event` once per event, and tells it which partition the event came from. Every event carries its **sequence number**, its **offset** and the partition key it was sent with. `on_error` prints anything that goes wrong; without it, the library would only write it to a log nobody reads."},
{"code": "listener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"on_error\": on_error, \"starting_position\": start})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\n", "note": "`receive` never returns on its own: a real reader listens for as long as it runs. This one listens in a thread for five seconds and then closes the client, so that it can be run and read."},
{"code": "for pid, seq, offset, key, n, page in sorted(seen):\n    print(f\"partition {pid}  seq {seq:>2}  offset {offset:>4}  {key}  #{n:<2} {page}\")\n", "note": "The events arrive partition by partition, interleaved differently on every run, so the program sorts them before printing."}
]}
```

```
ana@laptop:~/azure$ python read_clicks.py
partition 0  seq  0  offset    0  c-05  #4  /bakery
partition 0  seq  1  offset  144  c-05  #8  /cart
partition 1  seq  0  offset    0  c-02  #2  /search?q=banana
partition 1  seq  1  offset  152  c-02  #5  /cart
partition 3  seq  0  offset    0  c-17  #1  /fruit
partition 3  seq  1  offset  144  c-17  #3  /fruit/banana
partition 3  seq  2  offset  296  c-17  #6  /cart
partition 3  seq  3  offset  440  c-03  #7  /dairy
partition 3  seq  4  offset  584  c-17  #9  /checkout
partition 3  seq  5  offset  728  c-03  #10 /cart
```

**Within each partition the order is exactly the order of sending.** On partition 3, `c-17` opens
`/fruit`, then `/fruit/banana`, then `/cart`, then `/checkout`, clicks 1, 3, 6 and 9, and `c-03`'s two
clicks sit between them where they were sent. Read one customer's clicks and they make sense.

**Across partitions the order is gone.** Click 2 was sent second, and it is printed fifth, because
the program sorted by partition; a reader that printed events as they arrived would interleave the
partitions some other way on every run. Nothing in the events says which of click 4 and click 5 came
first, apart from the time the service received each one, its **enqueued time**, which belongs to
the service and not to the app. A question about the order of clicks across customers needs a
timestamp the app puts in the event itself, and lesson 23 is about reading by that time when some
events arrive late.

## Two names for one position

**A sequence number counts events; an offset locates them.** Each partition numbers its events from
0, one by one, so on partition 3 the six clicks are 0 to 5, and the next one will be 6 whatever its
size. The offset is a position in the partition's storage, and in this emulator it grows with the
size of each event: 0, 144, 296, 440. Partition 1's second event is at 152 rather than 144 because
`"/search?q=banana"` is a longer page than `"/bakery"`.

Treat both as belonging to one partition only. **Sequence number 1 on partition 0 and sequence
number 1 on partition 3 have nothing to do with each other**, and a reader that stores "the last
sequence number I read" for a whole hub has stored a number that means nothing. And treat the offset as
an opaque string the service gave you, which is how the library hands it over: the safe use of it
is to store it and give it back, never to compute with it.

## Where to start

`starting_position` takes four kinds of value, and each is a different question:

| value | starts at | for |
|---|---|---|
| `"-1"` | the oldest event still kept | reprocessing everything the retention allows |
| `"@latest"` | the end, so only events sent from now on | a dashboard that only cares about now |
| a sequence number | that event, or the one after it | resuming exactly where a reader stopped |
| a `datetime` | the first event enqueued at or after it | replaying since 09:00, after a bug was fixed |

A sequence number is per partition, so a program passes a dictionary with one per partition, and
`starting_position_inclusive` says whether the event itself is read again. Reading from the end
looks like this; nothing was sent during the five seconds, so it prints nothing:

```
ana@laptop:~/azure$ python read_clicks.py '$Default' @latest
```

**A reader that starts at `@latest` and then crashes loses whatever was sent while it was down**,
because on restart it starts at the end again. That is the problem the checkpoints of the next but
one section solve.

## Retention, which is the only deletion

**An event hub keeps events for its retention period and then drops them, read or not.** The
period is set per hub, in hours or days, and the tier decides how long it may be: Microsoft's
documentation gives one day on Basic, up to seven days on Standard, and up to ninety on Premium and
Dedicated. The emulator's configuration file sets none, and nothing in this lesson waits long enough
to see an event expire, so expiry was not run.

Two consequences decide designs. A reader that falls further behind than the retention loses events
for good, with no error, because the events it would have asked for no longer exist; the oldest
sequence number a partition reports moves forward as old events expire, and a reader comparing it
with its own checkpoint is the one that notices. And **an event hub is not a store**: seven days is
long enough to recover from a bad weekend and too short to be anybody's history. History goes into
storage, which is what Capture, three sections on, is for.
