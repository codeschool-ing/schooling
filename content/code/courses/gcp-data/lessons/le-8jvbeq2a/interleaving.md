---
title: Interleaved tables, an order stored with its customer
version: 1
---

**An interleaved table stores each child row beside its parent row, in the parent's part of the key
range.** `Orders` is declared `INTERLEAVE IN PARENT Customers`, so the orders of `c-17` are stored
physically after the row of `c-17`, sorted by their own key, before the next customer begins. A read
of one customer with all their orders is then one contiguous run of rows, in one split, on one server.
In a database spread over many machines, that is the difference between a join that reads one place
and a join that asks several.

**The wrong idea is that interleaving is a foreign key.** It enforces what a foreign key enforces, and
more, but what it is for is placement. A foreign key in `sql-databases` says that a row must refer to a
parent that exists; it says nothing about where either is stored, because on one server everything is
stored in one place. Interleaving is a statement about the key range, and Spanner can make it only
because the child's key begins with the parent's.

## The key has to begin with the parent's key

**A child's primary key repeats the parent's key as its first columns**, and that is the rule that
makes the placement possible. `Orders` is keyed by `(CustomerId, OrderId)`, which begins with
`Customers`' `(CustomerId)`. A table that tries to interleave without it is refused when the schema
changes:

```
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE TABLE OrderNotes (OrderId INT64 NOT NULL, Note STRING(MAX)) PRIMARY KEY (OrderId), INTERLEAVE IN PARENT Customers'
ERROR: (gcloud.spanner.databases.ddl.update) HTTPError 400: {"code":9,"message":"Table OrderNotes does not reference parent key column CustomerId."}
```

**The refusal names the column it wanted.** A note per order would be interleaved in `Orders`, with a
key of `(CustomerId, OrderId, NoteId)`: three levels, each beginning with the one above, and every
row of all three stored together under the customer.

## One customer, read in one place

A second customer with two orders, written with the command line. `OrderId` is left out, so its
`DEFAULT` takes the next value of the bit-reversed sequence:

```
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Customers --data=CustomerId=c-18,Name=Bruno,District=Mooca
commitTimestamp: '2026-10-30T18:46:57.337764Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Orders --data=CustomerId=c-18,Day=2026-10-29,TotalCents=4590
commitTimestamp: '2026-10-30T18:46:58.063079Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Orders --data=CustomerId=c-18,Day=2026-10-30,TotalCents=1380
commitTimestamp: '2026-10-30T18:46:58.790722Z'
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT c.Name, o.OrderId, o.Day, o.TotalCents FROM Customers c JOIN Orders o ON o.CustomerId = c.CustomerId WHERE c.CustomerId = 'c-18'"
Name   OrderId              Day         TotalCents
Bruno  3161526938414088192  2026-10-30  1380
Bruno  5467369947627782144  2026-10-29  4590
```

**The join reads one customer's part of the key range**, `c-18` and the orders stored after it. On a
real instance that is one split and one server; the emulator returns the same rows from its one
process, and cannot show the difference in where they were read from.

## An index is a table with a key of its own

**A secondary index is a second table that Spanner keeps sorted by the index's key**, updated in the
same transaction as every write to the table. The analysts want orders by day, which `Orders`' key,
starting with the customer, cannot give them, so the day gets an index, and `STORING` copies the total
into it so that the query never has to go back to the table:

```
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE INDEX OrdersByDay ON Orders(Day) STORING (TotalCents)'
Schema updating...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT Day, CustomerId, TotalCents FROM Orders@{FORCE_INDEX=OrdersByDay} WHERE Day = '2026-10-29'"
Day         CustomerId  TotalCents
2026-10-29  c-18        4590
```

**`@{FORCE_INDEX=OrdersByDay}` names the index to read**, which is how a query states it rather than
leaving the choice to the planner; `CustomerId` and `OrderId` come with every index entry, because
they are the key of the row it points at. And this index is the previous section's problem again: its
key starts with `Day`, so every order written today lands at the end of the index's key range, on one
split. **An index can be interleaved too**, when it begins with the parent's key:

```
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE INDEX OrdersByCustomerDay ON Orders(CustomerId, Day), INTERLEAVE IN Customers'
Schema updating...
.....done.
```

**`OrdersByCustomerDay` is stored inside each customer's part of the key range**, beside the orders
it indexes, so "Ana's orders in October" is one place to read and new orders spread with the
customers. It answers a different question from `OrdersByDay`, which is the trade: an index that
spreads its writes is an index by customer first, and "every order of one day" is then a query that
asks every customer's part.

## What the parent rule refuses, and what it deletes

**A child row cannot exist without its parent.** An order for a customer nobody created is refused,
with a sentence that names both tables; the next section's program meets it inside a transaction.
And `ON DELETE CASCADE`, in the schema, decides what happens to the children when the parent goes:

```
ana@laptop:~/gcp$ gcloud spanner rows delete --instance=quitanda --database=shop --table=Customers --keys=c-18
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT COUNT(*) AS orders FROM Orders WHERE CustomerId = 'c-18'"
orders
0
```

**Deleting `c-18` deleted its two orders in the same write.** Without `ON DELETE CASCADE` the delete
would be refused while the customer had orders, which is the other choice and sometimes the safer
one: an orders table is a record of sales, and Quitanda's accountants would rather the delete of a
customer failed than took the sales with it.

## When not to interleave

**Interleave what is read together, and only that.** A customer's orders are read with the customer
on every visit to the app, so they belong together. The stock of a product has nothing to do with any
customer, and `Stock` is a table of its own. And a parent with an enormous number of children is a
warning sign: every child of one parent sits in that parent's part of the key range, so a parent that
takes most of the writes is a hotspot by another route, the one a counter made in the previous section.
