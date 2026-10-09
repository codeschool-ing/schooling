---
title: Chain of custody
version: 1
---

A hash shows that a file has not changed since it was hashed. It does not say **who** hashed it, who held
it afterwards, or whether both the file and its hash were replaced along the way. That is what a **chain
of custody** records: an unbroken list, from collection to the final report or to a court, of everybody
who had the evidence and what they did with it.

In Brazil this has a precise legal shape. The Code of Criminal Procedure, since Law 13.964/2019, defines
the chain of custody in articles 158-A to 158-F, stage by stage, from recognising a piece of evidence to
discarding it. Logs a company collects may end up in a police investigation or a civil case, and a gap in
their history weakens them. The international reference for handling digital evidence is **ISO/IEC 27037**,
and lesson 16 applies the same discipline to disk images.

A custody record for one log file needs these fields, filled in at collection and extended at every
transfer:

| field | for the file of this lesson |
|---|---|
| item | `gw.log-20261007`, the SSH log of `gw` as received on `soc` |
| hash and algorithm | SHA-256, the value printed when it was sealed |
| collected by | the analyst's name and role |
| when | date and time, with the time zone |
| from where | `soc:/var/log/remote/`, and how it got there (rsyslog over TCP from `gw`) |
| how | the command used to copy it, and the tool's version |
| where it is kept | the location and who can open it |
| each transfer | from whom, to whom, when, why, and both signatures |

Three habits keep the chain intact in practice. **Work on copies**, never on the collected file, and check
the hash of each copy against the record before using it. **Record transfers at the moment they happen**,
not at the end of the week from memory. And **keep the record somewhere the evidence is not**: a custody
log stored inside the folder it describes is exposed to everything that folder is.

None of this changes what the log says. It decides whether anybody else is obliged to believe it.
