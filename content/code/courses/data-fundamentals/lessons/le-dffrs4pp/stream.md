---
title: Stream, a consumer that remembers its offset
version: 1
---

**A stream processor reads an append-only log, one event after another, and keeps a note of how far it
has read.** That note, the **offset**, is most of what makes it a stream processor rather than a program
that reads a file.

The log is the structure underneath. Events are written to its end in the order they arrive and are
never changed afterwards, so every event has a fixed position: the first is at offset 0, the next at 1,
and so on. A reader does not take events out. It reads from a position, and a different reader can read
the same events from a different position, because nothing is removed by being read. `docks.jsonl` has
that shape already: one event per line, in order of arrival, so a line's number is its offset.

**Apache Kafka is the best-known log of this kind**, and its readers are called consumers. `streaming`
is the course that builds with it. Here a short program does the same job on the file. Save it as
`stream/consumer.py`:

```schooling-example
{"language": "python", "file": "stream/consumer.py", "parts": [
{"code": "# stream/consumer.py\nimport json\nimport sys\nfrom collections import Counter\n\nhow_many = int(sys.argv[1])                      # events to read on this run\ncrash = '--crash' in sys.argv\n", "note": "How many events to read on this run, and `--crash`, which the section on delivery guarantees uses. Leave it out for now."},
{"code": "\n\ndef load(path, empty):\n    try:\n        with open(path) as f:\n            return json.load(f)\n    except FileNotFoundError:\n        return empty\n", "note": "`load` reads a JSON file, or gives back `empty` when the file is not there yet, which is the case on the very first run."},
{"code": "\n\noffset = load('offset.txt', 0)                   # where the last run stopped\nrides = Counter(load('rides.json', {}))\nwith open('docks.jsonl') as f:\n    batch = f.readlines()[offset:offset + how_many]\n", "note": "The two things that survive between runs: the offset, where to start reading, and the count so far. `readlines()[offset:offset + how_many]` reads from that position. A real log jumps straight to a position without reading everything before it."},
{"code": "for line in batch:\n    e = json.loads(line)\n    if e['kind'] == 'undock':\n        rides[e['station']] += 1\n", "note": "The work: one more ride for the station of every undock."},
{"code": "with open('rides.json', 'w') as f:               # 1. write the result\n    json.dump(rides, f)\nif crash:\n    sys.exit('crashed before committing the offset')\nwith open('offset.txt', 'w') as f:               # 2. commit the offset\n    json.dump(offset + len(batch), f)\n", "note": "Then two writes, in this order: the result first, the offset second. The offset written is the position of the next event to read. Between the two writes is where `--crash` stops the program."},
{"code": "if batch:\n    print(f'read offsets {offset} to {offset + len(batch) - 1};', 'rides so far:', sum(rides.values()))\nelse:\n    print(f'nothing new at offset {offset}')\n", "note": "What the run read, and the count so far."}
]}
```

The program reads a number of events, three hundred at a time here, and stops. A real consumer never
stops: when it reaches the end of the log it waits, and reads the next event the moment one is appended.
Stopping after each run is what lets you look at the offset between runs:

```
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 0 to 299; rides so far: 156
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 300 to 599; rides so far: 311
ana@lab:~/roda/stream$ cat offset.txt
600
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 600 to 719; rides so far: 360
ana@lab:~/roda/stream$ python consumer.py 300
nothing new at offset 720
```

After two runs the offset is 600, which is the position of the next event to read rather than the last
one read. The third run reads the remaining 120 and the fourth finds nothing new. By then the count is
360, three mornings of 120 rides, the same total the batch job found.

## Restarting is reading from the offset

Every run of that program is a restart. It begins with nothing in memory, reads the offset and the
running count from disk, and carries on from exactly where the previous run stopped. A consumer in
production is restarted all the time, to deploy a new version or because the machine it runs on went
away, and **the committed offset is what turns a restart into a pause rather than a start from the
beginning**.

The same position lets a consumer do two other things. It can go **back**: set the offset to 0 and every
event is read again, which is how a stream is reprocessed after a bug is fixed. And a second consumer
with its own offset can read the same log for a different purpose: the live dock map, and the alert that
sends a van to an empty station, each at its own pace and neither knowing about the other.

The answer is different from a batch job's in one way that matters. **After each run, the count is the
count so far.** It is never "Monday's rides", because the consumer has no way of knowing whether Monday
is over. The next section shows why that question is harder than it looks.
