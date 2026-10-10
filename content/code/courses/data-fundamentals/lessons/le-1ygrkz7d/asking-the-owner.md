---
title: Asking the owner, and writing the answers down
version: 1
---

**Every failure in this lesson was a question nobody asked the source's owner before the first copy.**
The deleted ride, the half-loaded file, the retried event, the fast clock: each one has an answer the
owner already knew, and each was found here by running into it. Asking first is cheaper, and the
questions are nearly the same for every kind of source.

| ask the owner | because of |
|---|---|
| What is one row, or one event? What identifies it? | duplicates can only be removed by an identifier |
| How is a delete recorded, if at all? | an incremental copy cannot see a row that is gone |
| Which column changes on every change, and who sets it? | `updated_at` is only as good as the code that writes it |
| How do I know a delivery is complete? | a file still being written looks finished |
| How may I read it: from where, how fast, at what hours? | the primary, the rate limit, the quiet hour |
| Can it send the same thing twice? | at-least-once delivery, from phones and from docks |
| Which clock is the time from, and in what time zone? | a phone's clock, a sensor's clock, a log's offset |
| Which fields are personal data? | an IP address is one, and so is a customer id |
| How will I hear about a change before it ships? | a renamed field fails nothing on the day it lands |

The last question is the one that matters most over a year. Every other answer is true on the day it
is given and stays true only until the owner changes something. **A source that changes without
warning is a source you are reading at your own risk**, however carefully you read it today.

## A data contract

When the answers are written down, agreed by both sides and checked by a program, they are called a
**data contract**. Lesson 2 counted contracts among the things a data engineer owns; this is what one
holds. It is not a legal document. It is the producer's promise about the shape and behaviour of the
data, with a named owner and a rule for changes. For the dock readings it might say:

```json
{
  "dataset": "dock_readings",
  "owner": "operations, with the sensor vendor",
  "key": ["sensor_id", "seq"],
  "fields": {
    "sensor_id": {"type": "string", "example": "ST02-D02"},
    "seq": {"type": "integer", "rule": "one more than the sensor's previous reading"},
    "stamped_at": {"type": "timestamp", "rule": "the sensor's clock, synchronised by NTP"},
    "received_at": {"type": "timestamp", "rule": "the vendor's server clock, in UTC"},
    "has_bike": {"type": "boolean"}
  },
  "delivery": "at least once; duplicates share sensor_id and seq",
  "expected": "one reading per sensor per minute",
  "personal_data": "none",
  "changes": "announced 30 days ahead; a removed or renamed field is a new version"
}
```

There is no single standard format for a contract, and teams write them in JSON, YAML or a page of a
wiki. What makes it a contract is that something checks it. The `key` line is the duplicate check, the
`expected` line is the gap count, and the `changes` line is the warning the last question asked for.
Lesson 7 runs checks like these on arrival, and `data-cleaning` takes them much further.

The owner can say no to some of it. The vendor may refuse to number its readings, or the app team may
keep deleting cancelled rides. Then the answer still goes in the contract, as a known gap, so that the
person who builds on the data next year finds it written down rather than discovering it the way this
lesson did.
