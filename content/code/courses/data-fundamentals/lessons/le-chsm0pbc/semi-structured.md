---
title: Semi-structured data, where every record carries its own names
version: 1
---

**Semi-structured data has a structure, but nobody declared it in advance: each record carries the
names of its fields beside the values, and two records may not agree.** JSON is the format you will
meet most, followed by XML and YAML. A JSON document is not a mess. It is shaped, sometimes deeply.
What it lacks is a rule, enforced before it is stored, that says every document must have that shape.

Roda Livre's app sends one JSON event each time a ride ends, and the data team keeps them as they
arrive, one per line. That layout, a JSON document per line, is called **JSON Lines**, and lesson 6
compares it with the other formats. This program writes two days of such events. Save it as
`events.py`:

```python
# shapes/events.py
import json
import random

random.seed(5)
STATIONS = [f'ST{n:02d}' for n in range(1, 13)]


def ride(n, day, version):
    start = random.choice(STATIONS)
    hour, minute, length = random.randint(6, 21), random.randint(0, 59), random.randint(4, 50)
    battery = random.randint(20, 100)
    event = {'ride_id': f'R{n:06d}', 'app': version,
             'bike': {'id': f'B{random.randint(1, 90):03d}',
                      'battery': battery if version == '4.1' else f'{battery}%'},
             'start': {'station': start, 'at': f'{day}T{hour:02d}:{minute:02d}:00-03:00'},
             'charges': [{'kind': 'unlock', 'cents': 100}]}
    if n % 4 != 0:  # every fourth ride is still going: no end, no bill yet
        event['end'] = {'station': random.choice(STATIONS), 'minutes': length}
        event['charges'].append({'kind': 'minutes', 'cents': 25 * length})
        if length > 30:
            event['charges'].append({'kind': 'overtime', 'cents': 300})
    if random.random() < 0.3:
        event['coupon'] = 'PRIMEIRA'
    if version == '4.2':
        event['helmet'] = random.random() < 0.5
    return event


for day, version, first in (('2025-09-15', '4.1', 101), ('2025-09-16', '4.2', 201)):
    with open(f'rides-{day}.jsonl', 'w') as f:
        for n in range(first, first + 6):
            f.write(json.dumps(ride(n, day, version)) + '\n')
    print('wrote', f'rides-{day}.jsonl', 'app', version)
```

The program makes up the rides, from a fixed seed, so your files match the ones below. Two details
in it come back later in the lesson: the second day is written by version 4.2 of the app, and that
version sends the battery level differently and adds a field. Run it, and look at the first event
of the first day:

```
ana@lab:~/roda/shapes$ python events.py
wrote rides-2025-09-15.jsonl app 4.1
wrote rides-2025-09-16.jsonl app 4.2
ana@lab:~/roda/shapes$ head -1 rides-2025-09-15.jsonl | python -m json.tool
{
    "ride_id": "R000101",
    "app": "4.1",
    "bike": {
        "id": "B004",
        "battery": 87
    },
    "start": {
        "station": "ST10",
        "at": "2025-09-15T14:47:00-03:00"
    },
    "charges": [
        {
            "kind": "unlock",
            "cents": 100
        },
        {
            "kind": "minutes",
            "cents": 650
        }
    ],
    "end": {
        "station": "ST08",
        "minutes": 26
    }
}
```

## Three things a table does not have

**Nesting.** `bike` is not a value; it is an object holding two values of its own. So is `start`.
The event groups what belongs together, and the bicycle's id is reached as `bike.id`, two names
deep. JSON has no limit on depth.

**Arrays.** `charges` is a list, and the number of items in it changes from ride to ride: an
unlock fee, then the minutes, and an overtime fee when a ride runs past half an hour. A table cell
holds one value. A list of a varying length has no single column to go into.

**Optional fields.** A ride still under way when the event was sent has no `end`. A ride without a
coupon has no `coupon` key at all, rather than an empty one. Count the events that have an `end`, and the ones that have a coupon:

```
ana@lab:~/roda/shapes$ grep -c '"end"' rides-2025-09-15.jsonl
5
ana@lab:~/roda/shapes$ grep -c coupon rides-2025-09-15.jsonl
1
```

Five of the six have an `end`, and one has a coupon. Nothing is wrong with the sixth. It is ride `R000104`, which had not ended yet, and
that is exactly what a missing `end` means. A reader that assumed every event has one would fail on
it, or, worse, fill in a default and report a ride that never finished as one that did.

## Schema on read

With no schema declared at the door, the schema is decided by **whoever reads**. The reader says which
fields it expects, what it does when one is missing, and what type it wants each value to be. The
jargon is **schema on read**, and it is the mirror image of the last section: writing never fails,
and every reader has to make, and keep, its own decisions.

Two of those decisions JSON forces on every reader. **JSON has no date or time type**: its types are
string, number, true or false, null, object and array. The `at` field above is a string that looks
like a time, and turning it into one is the reader's job. And JSON does not distinguish an integer
from a decimal, so whether `battery` is `82` or `82.0` is a matter of what the sender wrote.

That freedom is why semi-structured data is everywhere. The app team can add a field on a Tuesday
without asking anybody, and every event since then carries it. The next two sections are what the
data team does with the other side of that freedom: turning the nesting into rows, and noticing when
the shape changed.
