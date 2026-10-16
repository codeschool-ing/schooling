---
title: Logs, written for a person and read by a program
version: 1
---

**A log is a source nobody designed as a source: lines written for a person reading them at night,
which a program then has to take apart.** Every request to Roda Livre's API passes through a web
server, and the server writes one line about it to an access log: who asked, when, for what, and how
it went. Nobody meant those lines for analytics. They are there so that whoever is on call can read
what happened. They are also the only record of every request the API ever answered, including the ones
that failed and left no row in any database.

That is what makes a log worth reading. A database knows the ride that was ended. The log also knows
that the first attempt to end it failed with an error and the app tried again two seconds later.

## Taking a line apart

A web server like nginx writes, by default, in a layout called the combined log format. One line of it,
from Roda Livre's API:

```
203.0.113.7 - - [15/Sep/2025:08:03:11 -0300] "GET /v1/stations/ST02 HTTP/1.1" 200 512 "-" "RodaApp/3.4 (Android 14)"
```

The address the request came from, two fields that are almost always `-`, the time with its offset
from UTC, the request itself, the status code, the size of the answer in bytes, the page it came from,
and the program that asked. Nothing marks where one field ends except spaces, brackets and quotes, so
a program reads it with a **regular expression**: a pattern that names each field and says what it
looks like.

This program holds eight lines of a Monday morning, one of them broken, and parses them:

```python
# sources/parse_log.py
import re
from collections import Counter

LOG = """\
203.0.113.7 - - [15/Sep/2025:08:03:11 -0300] "GET /v1/stations/ST02 HTTP/1.1" 200 512 "-" "RodaApp/3.4 (Android 14)"
198.51.100.23 - - [15/Sep/2025:08:03:12 -0300] "POST /v1/rides HTTP/1.1" 201 88 "-" "RodaApp/3.4 (iOS 18)"
203.0.113.7 - - [15/Sep/2025:08:03:15 -0300] "GET /v1/stations/ST05 HTTP/1.1" 200 498 "-" "RodaApp/3.4 (Android 14)"
192.0.2.140 - - [15/Sep/2025:08:03:15 -0300] "GET /v1/stations HTTP/1.1" 200 6120 "-" "Mozilla/5.0"
198.51.100.23 - - [15/Sep/2025:08:03:19 -0300] "POST /v1/rides/R000301/end HTTP/1.1" 500 41 "-" "RodaApp/3.4 (iOS 18)"
198.51.100.23 - - [15/Sep/2025:08:03:21 -0300] "POST /v1/rides/R000301/end HTTP/1.1" 200 64 "-" "RodaApp/3.4 (iOS 18)"
203.0.113.9 - - [15/Sep/2025:08:03:2
192.0.2.140 - - [15/Sep/2025:08:03:24 -0300] "GET /v1/stations/ST11 HTTP/1.1" 404 30 "-" "Mozilla/5.0"
"""
LINE = re.compile(r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] '
                  r'"(?P<method>\S+) (?P<path>\S+) \S+" (?P<status>\d{3}) (?P<bytes>\d+) '
                  r'"[^"]*" "(?P<agent>[^"]*)"')

parsed, rejected = [], []
for number, line in enumerate(LOG.splitlines(), start=1):
    match = LINE.fullmatch(line)
    if match:
        parsed.append(match.groupdict())
    else:
        rejected.append(number)

print(parsed[0])
print(len(parsed), "lines parsed; rejected line numbers:", rejected)
print("by status:", dict(sorted(Counter(p["status"] for p in parsed).items())))
```

```
ana@lab:~/roda/sources$ python parse_log.py
{'ip': '203.0.113.7', 'time': '15/Sep/2025:08:03:11 -0300', 'method': 'GET', 'path': '/v1/stations/ST02', 'status': '200', 'bytes': '512', 'agent': 'RodaApp/3.4 (Android 14)'}
7 lines parsed; rejected line numbers: [7]
by status: {'200': 4, '201': 1, '404': 1, '500': 1}
```

Every field is a string, including the status and the size, because a regular expression finds text
and nothing more; turning `"512"` into a number and the time into a time is the next step, and a
separate one. Line 7 was cut off in the middle of its time, the way a line ends when a server is
stopped while writing it. **The program names the line it could not read instead of dropping it.** A
parser that skipped what did not match would report seven requests as though seven had been made, and
the day the server's log format changes, it would skip every line just as quietly.

The two requests to `/v1/rides/R000301/end` are the retry: a `500` at 08:03:19 and a `200` two seconds
later. Counted naively, that is one failure in seven requests. Counted by what the customer
experienced, it is one ride that ended, two seconds late.

## Two things to ask for

**Logs that are already fields.** Many applications can write each line as a JSON object instead of a
sentence, a habit called structured logging. The fields then arrive named and the regular expression
goes away, along with its way of failing.

**Less of what is in them.** The first field of every line is an IP address, and an address can be
traced to a person. The LGPD treats information that can identify a person as personal data, whether
or not a name is attached. A log copied whole into the data platform carries that data with it, kept
for as long as the copy is. Lesson 7 is about collecting only what the question needs.
