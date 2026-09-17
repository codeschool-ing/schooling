---
title: The model is a picture of the schema, not the schema
version: 1
---

Most ORMs let you declare the table in the language — a class with typed fields — and generate
the migration from the declaration. It is convenient, and it invites a belief that costs: that
the class **is** the table, and that a rule written on the class is a rule the data obeys.

## The database enforces; the model describes

```
class Order:
    customer = ForeignKey(Customer)
    total    = Decimal(10, 2)
    status   = Choice('pending', 'paid', 'shipped', 'cancelled')
```

Three rules, and where each one is enforced decides whether it holds:

**The foreign key** becomes `REFERENCES customers (id)` in the generated DDL, and the database
refuses an order for a customer that does not exist — from every connection, including the
reporting script and the `psql` session that bypasses the model entirely.

**The decimal** becomes `numeric(10,2)`, and lesson 3's argument for the type is preserved.

**The choice** is the one to watch. Some mappers turn it into a `CHECK` constraint; many keep it
only in the class, as validation that runs when *this code* saves *this object*. A row inserted by
anything else — a bulk load, another service, a migration, a hand-written `UPDATE` — carries
whatever status it likes. Lesson 1's point about constraints arrives: **a rule the database
does not know is a rule some rows do not follow.**

The same goes for `NOT NULL` that lives only as a required field, uniqueness that lives only as
a validation — lesson 8 showed that one is a write skew waiting for two requests — and lengths and
ranges checked in the form and nowhere else. Put them on the table. The model's validation is
still worth having, for the error message, and it is the second line of defence rather than the
first.

## What generated DDL leaves out

A migration generated from a model is a translation, and every translation has defaults. Three to
check on any schema an ORM wrote:

**The index on the foreign key.** Lesson 9's most valuable sentence: PostgreSQL does not create
one. Some mappers add it when they generate the column and some do not, and the ones that do not
produce the four-minute delete lesson 9 described, on a schema that looks complete. Run lesson 9's
query for unindexed foreign keys against any database an ORM built.

**The types.** A string field with no length becomes `varchar(255)` in some tools and `text` in
others; a datetime becomes `timestamp` without a zone in some and `timestamptz` in others. Lesson 3
said which of those is right and why, and the generated migration is where to check that the tool
agreed.

**The constraints that need a scan.** A unique index the model asked for is built with a lock by
default, because the generator does not know the table is large. Lesson 9's `CONCURRENTLY` and the
migration section's note about transactions are yours to add, not the generator's.

The habit is simple: **read the generated migration before running it**. It is SQL; lesson 3
covers everything in it; and a generator that produced something surprising is a generator that
will produce it again.

## Two directions

Model to schema — declare the class, generate the DDL — is the direction most tutorials show, and
it suits a new application whose database has one client. Schema to model — write the DDL, and
generate or introspect the classes from it — is the other, and it suits a database that outlives
its applications, has several, or is shared with people who write SQL.

Neither is wrong. The mistake is forgetting which one you chose. A team that generates the schema
from the model and then edits the schema by hand has two sources of truth, and the next generated
migration will try to undo the edit. Pick one, and let the other be derived.

## The schema is the contract

An application is replaced; a database is migrated. The rows in `orders` will be read by code
that has not been written yet, in a language nobody on the team has chosen, and the only thing
that code will be able to rely on is what the database enforced. A constraint in the class is a
promise to this application. A constraint in the table is a promise to every application that
will ever open it — which is why lesson 1 put them there, and why the class is a picture of that
and not a substitute for it.
