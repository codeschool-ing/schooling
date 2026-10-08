---
title: Measure before you change anything
version: 1
---

Every load in this course has taken seconds, because the shop is small: about thirty thousand lines
of sales in three months. Real warehouses are not, and the same code that is instant on a laptop can
take the whole night on a table a hundred times larger — or cost, in a warehouse rented by the
query, more than the report it feeds is worth.

The first rule of making a pipeline faster or cheaper is the same as the first rule of fixing it:
**find out where the time goes before changing anything.** Guesses about performance are wrong
often enough that a change made on a guess is as likely to cost time as to save it. PostgreSQL gives
two instruments, and this lesson uses both:

- **`\timing on`** in `psql`, which prints how long each statement took, as the client saw it;
- **`EXPLAIN ANALYZE`**, which runs a statement and reports how the database did it — which rows it
  read, by which route, and how many of them it threw away. With `BUFFERS` it also counts the pages
  of the table it touched, which is the number a warehouse priced by the data it scans would bill.

The lesson measures four decisions that come up in every pipeline: how rows are written, how a day
is found, how much is rebuilt each night, and how much is read. The times are this machine's and
will be different on another. What does not change from run to run is the size of the gaps between
the methods, and that is what each section is about.
