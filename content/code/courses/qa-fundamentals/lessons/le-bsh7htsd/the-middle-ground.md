---
title: The middle ground
version: 1
---

**Grey-box testing tests through the outside with some knowledge of the inside.** The tester does not
read every line of the code, as in lesson 7, but does not pretend to know nothing either, as in lesson 6.
They know how the system is built: which parts it has, where it keeps its data, what it writes to its
logs, how one part calls another. They use that knowledge to choose tests and, above all, to **check
results in places the user never sees**.

It is the approach most testers actually use, most of the time. A tester who has never opened the code
still knows the shop has a database, still knows a price comes from one module and an order from another,
and still looks at the database after placing an order. That is grey box, whether or not anybody calls it
that.

## What counts as partial knowledge

The knowledge grey box uses is the kind found in a diagram on a whiteboard, not in the source:

- **the architecture**: which programs, services or modules exist, and which calls which;
- **the data**: which tables exist, what each column means, which values it allows;
- **the interfaces between parts**: what one part sends another, in what format;
- **the side effects**: what a system writes besides its answer, such as a log line, a file or an email.

None of that needs the ability to program. A data model, a table of what each column means, or ten
minutes with a developer drawing boxes gives a tester most of what grey box needs.

## Why the middle

Each of the other two approaches has a blind spot the middle one partly covers.

**Black box sees only the answer.** If the program prints the right thing and quietly writes the wrong
thing somewhere else, the black-box tester is satisfied. A grey-box tester checks the database too, and
sees the wrong thing.

**White box sees the code but not the system.** Reading `orders.py` line by line tells you what each line
does. It does not tell you that the nightly report counts seats by adding up a column of the `orders`
table, which is the fact that turns a harmless-looking row into a defect.

Grey box combines the two in the cheapest way: **act like a user, check like an insider.** The next two
sections do exactly that with the program that places orders.

## What it is not

Grey box is not a licence to test the implementation instead of the behaviour. A test that checks that the
database contains exactly one row with exactly these columns will break when a developer renames a column,
even if the shop works perfectly. The checks worth making in the inside are the ones that matter to
somebody outside: a seat sold that was not paid for, a total that does not match the receipt, a record
the nightly report will read. **Look inside to see consequences, not to pin down details.**
