---
title: What this course is, and what one machine can show
version: 1
---

**This course is about the moment one computer stops being enough, and what you do then.** The data
it uses is the clickstream of Ponto Final's website: every page a visitor opened, every search,
every book put in a basket and every purchase, for the whole of 2025. If you came through the data
track you know the shop already. Its tills fill a PostgreSQL database, a warehouse answers its
managers, and a pipeline moves one into the other every night. The website writes far more than
the tills ever did, and the tools that coped with the orders stop coping with this.

The course runs on **Apache Spark**, the engine most companies use when data outgrows one machine,
driven from Python. It goes through what Spark is built on as well, because a job is only tuned by
somebody who knows what it turned into: the cluster and its scheduler (lesson 2), a filesystem
spread over many disks (lesson 3), and MapReduce, the model Spark replaced (lesson 4). Then Spark
itself, from the API to the plan it makes of your code (lessons 5 and 6), what happens when a job
runs on many workers at once (lessons 7 to 9), and how the files underneath are laid out (lessons 10
and 11). The last three lessons are the systems around it and the bill.

## What one machine can show, and what it cannot

Be clear from the start about the one thing in this lab that is staged. **A cluster's whole subject
is what happens when the work is spread over several machines**, and your lab is one machine
pretending to be four. That is not as bad as it sounds, and it is worth knowing exactly where the
pretence stops.

What is real: the master, the workers and the processes they start are separate Java programs, and
each holds its own memory. When a job moves data from one worker to another, the data is cut into
blocks, serialised, written to disk and read back by the other process, exactly as on a cluster of
a hundred machines. The plans Spark makes, the stages it cuts a job into, the bytes each stage
moves, the memory a task spills and the retry after a worker dies are all the real thing, and the
lessons measure them.

What is not: the network between the workers is your machine's memory, so moving a gigabyte takes
a fraction of what it takes between two racks. **The data is small**: 24 million events, a quarter
of a gigabyte compressed, which a single laptop handles in about a minute. A real clickstream is
thousands of times larger. Where that changes the conclusion, the lesson says so and does the
arithmetic for the size that would hurt, rather than letting a fast run on small data teach the
wrong lesson.

So the course teaches the reasoning with measurements you take yourself, and scales them up on
paper where a real cluster is the only way to feel them. That is the honest version of what a lab
on one machine can do.
