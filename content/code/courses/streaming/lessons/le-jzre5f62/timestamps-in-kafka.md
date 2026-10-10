---
title: The timestamp inside Kafka, and what uses it
version: 1
---

**The record's timestamp is not decoration: Kafka uses it to find records by time and to decide
when to delete them.** Both uses read that one field and nothing else, so what the producer puts
there decides how they behave.

## Who sets it

With `CreateTime`, the default, the producer sets it. Leave it out and the client writes its own
clock's present at the moment of `produce`, as `tills.py` did. Pass `timestamp=` in milliseconds and
it writes that, as `late_tills.py` does: the moment of sending by default, the moment of the sale
with `--stamp sold`. Either is a defensible design. **A producer that stamps the event time makes
the record's timestamp mean event time**, which lets every tool that reads timestamps work in event
time; a producer that stamps the send time keeps the timestamp close to the order of the log. A
topic with `LogAppendTime` takes the choice away from the producer altogether.

## Finding a place by time

Each segment of a partition has a `.timeindex` file beside its `.log`, which lesson 3 shows on
disk: a sparse map from timestamps to offsets. The client asks it with `offsets_for_times`, which
lesson 4 uses from Python. From the shell, `kafka-get-offsets.sh --time` asks the same question:
the earliest offset whose timestamp is at or after a moment, given in milliseconds.

Where did the `late` topic stand at one in the afternoon of 2 March?

```
ubuntu@stream:~/work$ date -d '2026-03-02 13:00 -03:00' +%s%3N
```

The answer is the first record **stamped** at or after 13:00, and in `late` the stamp is the time
of sending. Replaying from that offset reads everything that arrived after 13:00, and that is not
the same as every sale after 13:00: Natal's sales from the morning are all after it, because they
arrived at 14:00. Now the same day sent again, with the time of sale as the stamp:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic late-sold --partitions 1 --config retention.ms=-1
```

The same question gets the same offset, and that is not a coincidence. Every sale that arrived
before 13:00 also happened before 13:00, so whichever the stamp means, the first record at or
after 13:00 is the same one. What differs is what comes after it. Ask `late-sold` where its
Natal sales from eleven o'clock are:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic late-sold --from-beginning --max-messages 360 --formatter-property print.offset=true --formatter-property print.timestamp=true | grep -m 2 'natal.*T11:'
```

Stamped with eleven o'clock, sitting at offsets well past the one the search returned for one in
the afternoon. **In a topic stamped with event time, the timestamps go backwards wherever a late
event arrives**, and a search by time finds a position in the log, not a set of events: replaying
from the 13:00 offset reads Natal's morning, and starting a little earlier misses none of it only by
luck. Kafka's index copes with timestamps that go backwards, and the answer it gives is still "the
first record stamped at or after this moment", which is exactly as useful as the order of the log
allows. The search is the right tool for "replay what came in since the incident at 13:00", which
is the question lesson 16 asks it.

## Deleting by time

Lesson 3's retention, `retention.ms`, seven days by default, is also measured with the record's
timestamp: a segment is deleted when its **newest** timestamp is older than the limit. A topic of
records stamped with 2 March would lose them at the first retention check, a few minutes after
they were written, and the topic would look as if somebody had emptied it. That is why `late` and
`late-sold` were made with `retention.ms=-1`, which keeps everything. Kafka checks retention every
five minutes by default, and that wait is not in the transcripts. It was tried once on a separate
broker set to check every ten seconds: the 360 sales of a topic with the default retention were
gone at the first check, the active segment included, and its earliest offset became 360.

Two lessons follow from that. **A producer that stamps event time has to expect events older than
the retention**, and those vanish quickly, from the newest segment as well as the old ones. And a
broker whose own clock is wrong deletes on its own idea of the present, which is one more reason
the brokers, too, keep their clocks with NTP.
