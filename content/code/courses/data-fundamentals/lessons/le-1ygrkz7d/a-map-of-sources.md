---
title: A map of sources, and who owns each one
version: 1
---

**A source is a system somebody else built for another job, and a data engineer reads it as a
guest.** The common picture is a shelf: the data sits somewhere, finished, waiting to be collected.
Nothing at Roda Livre looks like that. The app's database was built to charge customers, the dock
sensors to show a map, the payments provider to move money. Each of them is busy doing its job when
Davi comes to read it, and each of them changes when its owners decide, not when he does.

So the first thing to know about a source is not its format. It is who owns it, how you may read it
without getting in the way, and what it does on the day it changes.

## Six kinds, and what each one does wrong first

This lesson walks through six kinds of source, in the order ana meets them in her first month. The
table is the whole lesson in one place; each row is a section of its own.

| kind | at Roda Livre | who owns it | how you read it | what goes wrong first |
|---|---|---|---|---|
| **database** | rides, customers, bicycles | the app team | a query, a copy, or its change log | reading it slows the app; deletes vanish from a copy |
| **API** | charges and refunds | the payments provider, another company | HTTP requests, page by page | rate limits, expired tokens, a field that changes meaning |
| **file** | the repairs contractor's daily export | a partner | wait for it in a directory or a bucket | it is read before it has finished arriving |
| **log** | the API server's access log | the platform team | parse lines of text | the format changes; it is full of personal data |
| **application events** | taps and screens in the app | the product team | a stream or a bucket of JSON | the same event arrives twice; the phone's clock is wrong |
| **IoT** | a sensor in every dock | operations and the vendor | readings sent every minute | gaps, drifting clocks, readings out of order |

Two columns matter more than the others. **Who owns it** decides who you ask before you start and
who tells you before something changes; for half of this table the answer is a different company.
**What goes wrong first** is the failure each kind is famous for, and none of them stops a program.
A copy that misses a delete, a file read halfway, a reading counted twice: each produces a table that
looks complete.

## Asking and being told

The six also differ in who moves first. A database, an API and a file wait to be asked: Davi's
program decides when to read, and the source does not know or care. Events and sensor readings are
sent: the app and the docks decide when to speak, and something on Roda Livre's side has to be
listening when they do. Lesson 3 called these pull and push. The difference decides what a failure
looks like. When a pull fails, the reader knows, because its request failed. When a push fails, the
data simply never arrives, and the only way to notice is to know what should have come.

That last idea runs through every section that follows: **a source is checked against what it
should have produced, not against what arrived.**
