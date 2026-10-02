---
title: Exceptions: one error, one record
version: 1
---

`crash.py` reads a malformed order and lets the exception escape, the way an unhandled error in a
service does. Python prints the traceback to the standard error stream as plain text:

```python
import json


def load(text):
    return json.loads(text)


load("{not json")
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python crash.py 2>&1 | grep -v Container | wc -l
17
ana@obs:~/shop$ docker compose run --rm sandbox python crash.py 2>&1 | grep -v Container | head -4
Traceback (most recent call last):
  File "/scratch/crash.py", line 8, in <module>
    load("{not json")
  File "/scratch/crash.py", line 5, in load
```

**Seventeen lines**, and a log pipeline that collects standard output one line at a time stores
seventeen records. The first says *Traceback*, the last says what went wrong, and the ones between
are the code path. In a busy service, other requests' lines arrive between them; a search for the
error's type finds the last line on its own, without the code that raised it; and none of the
seventeen carries the trace id of the request that failed.

`caught.py` catches the same exception and logs it through the shop's formatter with
`log.exception`, which records the message at `ERROR` and attaches the traceback:

```python
import json

from common import logs

log = logs.setup()
try:
    json.loads("{not json")
except ValueError:
    log.exception("could not read the order")
```

```
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python caught.py 2>/dev/null | wc -l
1
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python caught.py 2>/dev/null | jq -r '.message, .exception'
could not read the order
Traceback (most recent call last):
  File "/scratch/caught.py", line 7, in <module>
    json.loads("{not json")
  File "/usr/local/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/json/decoder.py", line 338, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/json/decoder.py", line 354, in raw_decode
    obj, end = self.scan_once(s, idx)
               ^^^^^^^^^^^^^^^^^^^^^^
json.decoder.JSONDecodeError: Expecting property name enclosed in double quotes: line 1 column 2 (char 1)
```

**One line.** The whole traceback is inside the `exception` field, with its line breaks escaped by
JSON, and `jq -r` prints it back as it was. It travels with the message, the level and, in a
service, the trace id, and it is never split.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One exception, two ways. On the left, the uncaught traceback printed as text: 17 lines, and the log pipeline stores each as a separate record, so a search for the error type finds the last line without the code that raised it, and lines from other requests can fall between them. On the right, the same exception logged through the JSON formatter: 1 record, with the message, the trace id and the whole traceback inside one field.\"><defs><marker id=\"exc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">printed as text: 17 records</text><rect x=\"60\" y=\"44\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"57\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"70\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"83\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"96\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"109\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"122\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"135\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"148\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"161\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"174\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"187\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"200\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"213\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"226\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"239\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"252\" width=\"240\" height=\"10\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">the error type, alone</text><text x=\"540\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">logged as JSON: 1 record</text><rect x=\"430\" y=\"110\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one record</text><text x=\"540.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">message, level, trace_id</text><text x=\"540.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exception: the whole traceback</text><text x=\"540\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">searchable by any field, never split</text></svg>", "caption": "Seventeen records against one, for the same error. The traceback is still all there on the right; it is just inside a field, where it cannot be separated from the event it belongs to."}
```

The rule that goes with it: **log an exception once, where it is handled**, not at every level it
passes through on the way up. A traceback logged by the database layer, again by the service layer
and again by the request handler is three errors in the count and one in reality.
