---
title: The other shapes legacy integration takes
version: 1
---

**SOAP is the friendly case.** It has a contract a program can read, it answers questions when they
are asked, and it says when something went wrong. Plenty of old systems offer less, and an
integration takes whatever shape the other side can manage. Five of them are common enough that
you will meet each one:

| shape | how it works | what you get | what it costs |
|---|---|---|---|
| **file drop** | the partner writes a file, CSV or fixed-width columns, to a directory you both reach, often over SFTP, and you pick it up | the simplest thing a very old system can do | hours of delay, and every file format question: encoding, decimal comma, a header row or not |
| **nightly batch** | a job exports or imports everything once a day, at an agreed hour | one moment a day when the two systems agree | data up to a day stale, and a failed night means two days of changes arriving together |
| **polling** | you ask "anything new since this point?" every few minutes | changes within minutes, from a system that cannot tell you about them | most of the questions come back empty, and the "since this point" has to be a cursor that never skips a change |
| **message queue** | the system publishes a message for each change to a queue, IBM MQ or a JMS broker in older shops, and you consume them | changes as they happen, and neither side waits for the other | messages arrive at least once, so the same change can arrive twice, and the consumer must be ready for that |
| **shared database** | you read, or worse, write, the old system's tables directly | the fastest start of all | everything below |

Every row has its own failure that looks like success. A file drop read while the partner is still
writing it is a 40 MB file processed as 12 MB, its last line cut in half, and no error anywhere.
The usual defence is that the partner writes to a temporary name and renames the file when it is
complete, because a rename on the same disk is instant. A poll that asks for rows newer than the last timestamp it
saw misses a row written in that same second, after it looked. A queue consumer that is not
idempotent books the same payment twice the first time the broker redelivers.

## Why the shared database is the worst

It feels like the cheapest: no service, no file, one query. What it does is make **the
other system's internal schema your contract, without its owners knowing they signed one.** Their
next release renames a column, splits a table or changes what a status letter means, and your
integration breaks on a Tuesday with nobody on their side aware it existed. Writing is worse than
reading: your rows skip every rule their application enforces, so the database ends up holding
states their own code never produces and cannot handle.

The same rule holds inside one codebase. A module that reads another module's tables has made the
same unsigned contract, and it breaks the same way.

**Whatever the shape, the adapter from the previous section still applies.** A file drop gets a
module that reads the file and hands the shop rows in its own terms; a queue gets a consumer that
translates each message. Only that module knows the shape exists, so replacing a nightly file with
a SOAP service, or a SOAP service with a REST API, changes one module and nothing else.
