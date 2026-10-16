---
title: Schema drift, or the shape that changed overnight
version: 1
---

**Schema drift is the shape of incoming data changing without anybody downstream being told: a field
appears, disappears, or starts carrying a different type.** With structured data it cannot happen
quietly, because the table refuses the first row that does not fit. With semi-structured data it is
the normal state of affairs, because every record is free to be a little different and nothing at
the door objects.

Nobody at Roda Livre did anything wrong on 16 September. The app team released version 4.2. It
records whether the rider took a helmet, and it sends the battery level the way the app's screen
shows it, as `"58%"` rather than `58`. Both changes were sensible from where the app team sat. Neither
reached the data team's ears.

## Inferring a schema, and comparing two

Since the events do not declare their schema, a program can work it out by reading them: every field,
by its dotted name, with the types it was seen with and how many records had it. Do that for two
batches and compare, and the drift prints itself. Save this as `drift.py`:

```python
# shapes/drift.py
import json
import sys


def paths(obj, prefix=''):
    for key, value in obj.items():
        if isinstance(value, dict):
            yield from paths(value, prefix + key + '.')
        else:
            yield prefix + key, type(value).__name__


def infer(path):
    seen, rows = {}, 0
    for line in open(path):
        rows += 1
        for name, kind in paths(json.loads(line)):
            seen.setdefault(name, {}).setdefault(kind, 0)
            seen[name][kind] += 1
    return seen, rows


old, n_old = infer(sys.argv[1])
new, n_new = infer(sys.argv[2])
print('schema of', sys.argv[1])
for name, kinds in sorted(old.items()):
    present = sum(kinds.values())
    print(f'  {name:14} {"/".join(sorted(kinds)):5} in {present} of {n_old}')
print('changes in', sys.argv[2])
for name in sorted(old.keys() | new.keys()):
    a, b = sorted(old.get(name, {})), sorted(new.get(name, {}))
    if not a:
        print(f'  new field    {name} ({"/".join(b)})')
    elif not b:
        print(f'  gone         {name}')
    elif a != b:
        print(f'  type changed {name}: {"/".join(a)} -> {"/".join(b)}')
```

`paths` walks one event and yields each field's dotted name with the name of its Python type. `infer`
does that for every line of a file and counts. The last loop compares the two sets of names and types.
Run it on the two days:

```
ana@lab:~/roda/shapes$ python drift.py rides-2025-09-15.jsonl rides-2025-09-16.jsonl
schema of rides-2025-09-15.jsonl
  app            str   in 6 of 6
  bike.battery   int   in 6 of 6
  bike.id        str   in 6 of 6
  charges        list  in 6 of 6
  coupon         str   in 1 of 6
  end.minutes    int   in 5 of 6
  end.station    str   in 5 of 6
  ride_id        str   in 6 of 6
  start.at       str   in 6 of 6
  start.station  str   in 6 of 6
changes in rides-2025-09-16.jsonl
  type changed bike.battery: int -> str
  new field    helmet (bool)
```

The first block is the schema of 15 September, inferred: ten fields, the types they held, and how
often they were there. It says what the previous section showed by hand, now for every field at once:
`coupon` was in 1 event of 6, and `end.minutes` and `end.station` in 5 of 6. It also shows `start.at`
as `str`, because JSON had no other way to send it.

The second block is the drift. **A new field is mostly harmless**: `helmet` is simply not read by
anything yet, and it goes unused until somebody asks for it. **A changed
type is the dangerous one.** Anything that adds up `bike.battery` or averages it now meets `"58%"`.
In Python that is a `TypeError` today, which is the loud kind. Loaded into a column that takes text,
it would load cleanly and sort `"100%"` before `"58%"`, because text is compared one character at a
time, and every chart ordered by battery would be wrong without an error anywhere.

## What the data team does about it

Drift cannot be prevented from the data team's side; the app belongs to somebody else and will change
again. What can be decided is **where it is noticed**:

- at the door, by a check like `drift.py` run on every batch before it is used, which stops or
  warns while the batch is still small and the cause is one release old;
- in the reader, when a report breaks, by which time three weeks of events may hold both shapes;
- never, when the new shape is quietly converted into something wrong, which is the case worth
  designing against.

The other half is the conversation. A **data contract**, which lesson 4 introduced, is the agreement
with the app team about what an event contains, so that changing a type becomes something they warn
about before the release instead of something the data team discovers after it. Lesson 6 shows how
some formats carry a schema inside the file and let it change by rules, and lesson 7 builds checks
that run on arrival. Both are answers to this section's question.
