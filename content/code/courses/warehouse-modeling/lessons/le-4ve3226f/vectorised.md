---
title: Vectors, not rows
version: 1
---

Reading less explains part of the forty-fold difference in section 04. The rest is how the engine does its
arithmetic once the data is in memory.

A traditional row engine processes **one row at a time**: fetch a row, extract `net_cents`, add it to the
total, fetch the next. For every row, a chain of function calls, checks and branches, of which the addition
is the smallest part.

A columnar engine processes **a vector at a time**: a batch of values of one column, DuckDB's are 2,048
long, handed to a tight loop that adds them all. Three things make that fast on modern processors:

- **Less overhead per value.** The function calls and checks happen once per vector, not once per row.
- **The values are contiguous in memory**, so the processor's cache is full of the data it is about to use,
  rather than of the other columns of the row.
- **The processor can work on several values in one instruction.** Modern processors have instructions that
  add four or eight numbers at once, and a loop over a contiguous array of integers is exactly what they are
  for.

Two more techniques usually come with it:

- **Working on compressed data.** A filter on a dictionary-encoded column can compare the small codes rather
  than the strings, and a sum over a run-length-encoded column can multiply each value by its run length.
- **Late materialisation.** A query that filters on one column and returns another reads the filter column
  first, finds which rows survive, and only then fetches the other column for those rows.

None of this changes what a query means; it changes what a query costs, which is why lesson 6 could
measure a join and its absence at nearly the same speed.
