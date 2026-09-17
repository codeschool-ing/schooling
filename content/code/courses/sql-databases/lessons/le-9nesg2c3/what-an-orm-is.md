---
title: What an ORM is, and what it is not
version: 1
---

Every lesson so far has been written at a `psql` prompt. Almost no application is. An application
is written in a programming language, and the language has objects, lists and methods where the
database has tables, rows and statements. An **object-relational mapper** is the layer that
translates between the two.

```
customer = Customer.find(42)          -- SELECT … FROM customers WHERE id = 42
customer.name = 'Ana'
customer.save()                       -- UPDATE customers SET name = 'Ana' WHERE id = 42
```

That is the whole idea. A class stands for a table, an instance stands for a row, and a method call
becomes a statement. The block above is not any particular ORM — every one has its own spelling —
and the shape is the same in Django, Rails, Hibernate, SQLAlchemy, Entity Framework and Prisma.

## What it buys you

Four things, and they are worth having:

**Parameters, by default.** The ORM never glues a value into the text of a statement; it sends the
statement and the value separately. The section on parameters says why that is the most important
line in this lesson.

**Types that match.** A `timestamptz` arrives as the language's date type, a `numeric` as a
decimal rather than a float, a `boolean` as a boolean. Lesson 3's care over types is preserved on
the way out rather than lost at the boundary.

**The obvious statements written once.** Fetch by primary key, insert a row, update the columns
that changed, delete. Nobody should write those by hand five hundred times, and an application has
five hundred of them.

**Migrations.** A way to change the schema that is versioned, repeatable and tied to the code that
needs it, which is its own section and is the second half of this lesson.

## What it is not

An ORM is not a way to avoid knowing SQL, and this is the sentence the lesson is built on:

> **The ORM emits SQL. Whether you wrote it or not, the database runs a statement, plans it,
> and charges you for it — and everything in lessons 4 to 10 applies to that statement exactly as
> if you had typed it.**

An `ORDER BY` that is missing is missing whether a method left it out or you did. A join with no
index is a scan whether the loop is in your code or in a library's. The N+1 problem, which is the
next section but one, is the clearest case: a page that looks like ten lines of ordinary code runs
fifty-one statements, and nothing in those ten lines says so.

So the skill this lesson teaches is not the ORM's API, which every ORM documents. It is the habit
of **knowing what it emitted**, and the three or four places where what it emits is not what a
reader of the code would guess.

## Two shapes of ORM

They differ in where the mapping lives, and the difference decides how the rest of this lesson
reads.

**Active Record.** The object is the row. `customer.save()` writes it; `Customer.find(42)` reads
one. Rails named the pattern and Django's ORM, Laravel's Eloquent and most dynamic-language ORMs
follow it. Short to write, and the object knows about the database.

**Data Mapper.** The object is plain, and a separate thing — a session, a unit of work, a
repository — knows how to move it to and from a table. Hibernate, SQLAlchemy's ORM layer, Doctrine
and Entity Framework are this shape. More to set up, and the object does not know it is stored.

Below both sits the **query builder**, which is not a mapper at all: it composes SQL from method
calls — `select('id').from('orders').where('total > ?', 100)` — and hands back rows. Knex, jOOQ,
SQLAlchemy Core, Django's raw querysets. It is the honest middle: the statement is still yours,
and it is still parameterised, indented and composable. The last section says when each of the
three is the right layer.

## The frame for the rest

Two halves. Sections two to six are about **reading** what the ORM does — seeing its SQL, the
N+1, loading in one go, parameters, and the things it hides. Sections seven to nine are about
**writing** the schema through it — migrations, who owns the schema, and where the ORM belongs at
all. Both halves rest on the same rule, and lesson 10 is where to look when the rule is broken:
measure what it emitted.
