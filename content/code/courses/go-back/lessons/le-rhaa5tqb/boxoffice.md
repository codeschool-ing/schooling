---
title: What boxoffice is now
version: 1
---

This lesson changed boxoffice in more places than any before it, and every change was shown whole where
it was made. Here is where each one landed, and what the service can do now that it could not before.

| file | changed in | what it does now |
|---|---|---|
| `migrations/00001_events.sql` | section 03 | lesson 6's table and its two events, as version 1 |
| `migrations/00002_tickets.sql` | section 03 | the record of every sale, as version 2 |
| `sqlc.yaml`, `queries.sql` | section 03 | the schema read from the migrations; one query more, `InsertTicket` |
| `migrate.go` | section 04 | applies the embedded migrations at start, under a lock |
| `main.go` | section 04 | migrates, then builds a pool of at most 10 connections |
| `store.go` | section 05 | `Sell` takes the buyer's e-mail and returns a `Sale` |
| `events.go` | section 05 | the receipt carries the ticket's id |
| `pgstore.go` | section 07 | the sale and the ticket in one transaction, every query through it |
| `schema.sql` | section 03 | deleted |

**Three guarantees hold now that did not at the end of lesson 8.** Any copy of the database, empty or
behind, reaches the same schema by the same numbered steps, applied by the binary itself. No sale exists
without its ticket, nor a ticket without its sale. And twenty buyers at once get exactly as many tickets
as there are seats, with the rest told so, and the server still answering everyone else.

What boxoffice still says about all of this is the lines of `log.Printf` from lesson 2, which a person can
read and a program cannot easily search. **Lesson 12 makes its logs structured.** Before that, lessons 10
and 11 give it a second way to be called, by other services rather than by browsers.
