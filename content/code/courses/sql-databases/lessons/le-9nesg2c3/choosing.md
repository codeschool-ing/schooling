---
title: Where the mapper belongs, and where SQL does
version: 1
---

The argument about whether to use an ORM has been going on for as long as ORMs have, and it is
mostly an argument between people solving different problems. The useful version is not *whether*
but *for which statements*, and the answer sorts by the shape of the statement.

## The write path: the mapper's home

Create a customer. Update the address. Record an order with its lines. Delete a note. These are
the statements an application runs most, they are the ones with the most repetition, and they are
the ones where a mapper's four gifts — parameters, matching types, the obvious statements written
once, migrations — pay every time.

They are also the statements where lesson 8 matters most, and a mapper's unit of work is a good
shape for it: the order and its lines are one transaction because the session commits them
together. The two things to hold on to from the section on what it hides — the transaction's
length, and which columns are sent — are the price, and it is a small one.

## Reads on the write path: the mapper, with the eager instruction

A screen that shows a customer and their last ten orders is the N+1 shape, and the mapper's own
eager-loading fix is the right tool: one instruction at the query, two statements to the server,
and the objects that the screen is going to render. The rule is the second section's — read the
log once per screen — and nothing else is needed.

## Reports: SQL

Revenue by city by month with a running total. The customers who ordered in March and not in
April. The top product in each category. Lessons 6 and 7 built these — `GROUP BY`, window
functions, `HAVING`, CTEs, `EXISTS` — and a mapper expresses them badly or not at all. What comes
out of the attempt is one of two things. Several queries and a loop in the application doing the
aggregation the database would have done in one pass; or an expression so far from the SQL it
emits that nobody can read the plan against the code.

Write the SQL. Run it through the mapper's raw-query escape hatch with parameters, or through a
query builder, and read the result into plain records rather than model objects. The statement is
then a statement — reviewable, `EXPLAIN`-able, indexable by lesson 9's rules — and it is still
parameterised.

## The query builder in the middle

Most of what is neither a plain save nor a report is a `SELECT` with a `WHERE` that varies: a
search screen with optional filters, a list with sorting the user chooses. This is where string concatenation is born, because the SQL has to change shape with the input. It
is exactly what a query builder is for: each filter adds a clause, each clause takes a parameter,
and the result is one statement that the server plans as a whole.

A mapper's query interface is usually a query builder underneath — Django's chained filters,
ActiveRecord's scopes, SQLAlchemy Core — and using it as one, with the columns named and the
SQL logged, gets most of the benefit of both.

## The one rule under all three

Whatever emits the statement, the statement is what runs, and lesson 10's tools read it. So:

- **a query that is slow is a plan to read**, whether the mapper wrote it or you did;
- **a query that runs many times is a count to check** in `pg_stat_statements`, whichever layer
  put it in the loop;
- **a rule the data has to follow is a constraint** in the table, whatever the class says;
- **a value goes in a parameter**, through every one of the three layers.

None of those is about the ORM. They were true in lesson 1 and lesson 10, and the mapper is one
more place to apply them — the place where the SQL is furthest from view, which is why this lesson
spent most of its length on how to see it.

## What this lesson did not decide

Which ORM. The differences between them are real and are the kind that a team decides once for
its language, and the habits above are the same in each. Lesson 12 makes the same point about
engines: the tools change, the questions do not.
