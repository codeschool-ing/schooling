---
title: When a stream is worth it, and when it is not
version: 1
---

**A stream is worth what it costs when somebody acts on the answer within the time the batch would
have taken to produce it.** Not when the answer is merely nicer fresh: a dashboard that the
manager opens on Monday morning is just as good fed by a nightly job, and costs a fraction of the
effort.

Four kinds of question pass that test:

- **Something must be stopped while it is happening.** A card used in Recife and in Lisbon within
  ten minutes; a login from a thousand addresses in an hour. A fraud check that answers tomorrow
  answers after the money has gone.
- **A promise depends on the current state.** The stock count on the website, the seat on the bus,
  the slot in the delivery van. Selling the last copy twice is the Saturday in Recife from two
  sections ago.
- **A machine reacts to another machine.** A price that follows demand, a recommendation that
  follows the last click, a sensor that stops a production line. Nobody is reading these; a program
  is, and it reads in milliseconds.
- **Many systems need to hear about the same thing.** One sale has to reach the stock, the loyalty
  points, the warehouse and the accountant. Writing it once to a log that all four read is often
  the main reason a company adopts Kafka, even when none of the four is in a hurry.

The last one is worth stopping on, because it is not about speed at all. Lesson 2 calls it the log
as an integration point, and it explains why so many companies run Kafka for data that is
processed in hourly batches anyway.

## When it is not worth it

| the request | why a batch serves it |
|---|---|
| a daily or weekly report | the period closes; a complete, checkable number beats a fresh one |
| training a model on last year's data | the input is finite and fixed |
| a figure checked by an auditor | the auditor wants it reproducible from a file, not from a moment |
| "it would be nice to see it live" | nobody acts on the difference |

The cost side is lesson 17's subject, but its shape belongs here: a stream processor is a program
that runs **all the time**, so it costs money and attention all the time, including the hours when
nothing is sold. A batch that runs for twenty minutes costs twenty minutes.

## Most platforms do both

The usual answer is not one or the other. Events go into a log as they happen; the processes that
need them now read them now; and a batch job reads the same log at night to build the complete,
checked version. **The stream is the source and the batch is one of its readers.** That arrangement
is what this course builds towards for Ponto Final: the tills writing to Kafka, processors reading
the sales as they happen, and the warehouse still loaded once a night, from the same events.
