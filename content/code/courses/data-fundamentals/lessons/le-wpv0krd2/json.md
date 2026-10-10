---
title: "JSON: six types and every name, every time"
version: 1
---

**JSON brings a few types with it, and it pays for them by writing every field's name in every
record.** Lesson 5 met JSON as a shape, with nesting and optional fields. Here the question is the
file: what survives a trip through it, and what it costs on disk.

JSON has exactly six kinds of value: a string, a number, `true` or `false`, `null`, an object and an
array. That is already more than CSV, which has one. A reader can tell `5` from `"5"`, and a missing
value can be `null` instead of an empty string. Everything else has to be spelt as one of those six.
There is no date and no timestamp, no binary data, and no difference in the format between an
integer and a decimal: a number is a number, and whether `4.5` arrives as a float or an exact
decimal depends on the reader.

## What survives the trip

Save this as `formats/as_json.py`. It takes the first ride from `rides.py`, tries to write it as
JSON, and reads it back:

```python
# formats/as_json.py
import json
from rides import make

ride = make(1)[0]
try:
    json.dumps(ride)
except TypeError as e:
    print("TypeError:", e)

line = json.dumps(ride, default=str)
print(line)
back = json.loads(line)
for key in ["started_at", "minutes", "member"]:
    print(f"  {key}: {type(ride[key]).__name__} -> {type(back[key]).__name__}")

names = sum(len(json.dumps(key)) for key in ride)
print(len(line), "bytes, of which", names, "are field names in quotes")
```

```
ana@lab:~/roda/formats$ python as_json.py
TypeError: Object of type datetime is not JSON serializable
{"ride_id": "R000001", "bike_id": "B011", "start_station": "ST08", "end_station": "ST05", "started_at": "2025-09-01 06:01:23-03:00", "minutes": 5, "member": true}
  started_at: datetime -> str
  minutes: int -> int
  member: bool -> bool
162 bytes, of which 75 are field names in quotes
```

The first attempt fails, loudly, because a `datetime` is not one of the six. `default=str` tells
`json` to turn anything it does not know into a string, and the second attempt works. Reading it
back shows the cost: `minutes` and `member` came back as the types they left as, and `started_at`
came back as text. Every reader of this file now has to know that the string is a timestamp, and in
which format, exactly as with CSV.

The last line is the other cost. Of the 162 bytes in that one ride, 75 are the names of its fields,
with their quotes, and they will be written again for the next ride and the one after it. Section
"the-same-data-five-ways" shows what that adds up to over a month.

## One array, or one object per line

A JSON file can hold its records in two ways, and they behave very differently.

**One array** is a single value: `[` then every ride separated by commas, then `]`. It is valid JSON
only when the last bracket is there, so a reader using Python's `json.load` has to read the whole
file before it has any ride at all. A file cut off halfway is not a shorter file; it is an invalid
one. An API usually answers like this, because each answer is small.

**JSON Lines** puts one object on each line, and nothing around them: the line printed above, once
per ride. It is not a different syntax, only a convention, and it changes everything a pipeline
cares about. A writer appends one line when a ride ends. A reader takes one line at a time, so a
file of any size needs only one ride's worth of memory. A file can be split at any line break and
the pieces read by different workers. And a damaged line costs one record, not the file. Logs and
raw event files are written this way; you will also see it called NDJSON, newline-delimited JSON.

Both are row formats, and both are text, so a person can open them and read them. Where the data is
read by people, or arrives from an API, JSON is the right file. Where it is read by a program a
million rows at a time, the names and the text start to cost more than they give.
