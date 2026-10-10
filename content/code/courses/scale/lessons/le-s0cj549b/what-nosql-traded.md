---
title: What "NoSQL" gave up, and what it bought
version: 1
---

"NoSQL" is a poor name. It says what these databases are not, and several of them now speak a
language that looks a great deal like SQL. **What they have in common is a trade made on purpose**:
each gave up some of what a relational database promises in exchange for something lessons 1 to 3
showed is hard to get from one.

A relational database like PostgreSQL promises four things together:

- **any query**: data is stored in normalised tables and a join answers questions nobody planned
  for when the tables were designed;
- **transactions across any rows**: a sale updates a show and inserts a ticket, atomically;
- **a schema** that the database enforces, so a row that breaks it is refused;
- **one place where all of that is true**, which lesson 2 showed is hard to divide.

The databases of this lesson and the next keep some of those and drop others, and what they get
back is mostly what lesson 2 found expensive:

- **Partitioning built in.** Data is spread across servers by a key from the first row, with no
  router to write, and adding a server moves data automatically, usually on a hash ring like the
  one in lesson 2.
- **Replication built in**, often with the quorums of lesson 3 and a choice of consistency per
  query.
- **A data model shaped like the access**, so the common read is one lookup on one server instead
  of a join across several tables.

The price is the first two promises. **Queries you did not plan for become expensive or impossible**,
because the data is laid out for the ones you did. **Transactions are limited**, usually to one
item or one partition. And a flexible schema moves the job of checking the data's shape into every
program that reads it.

That is why this lesson starts from access patterns rather than from products. Each family below
is a different answer to the question **"what is the one thing this data must be good at?"**, and
picking one is deciding which questions you are willing to make expensive.
