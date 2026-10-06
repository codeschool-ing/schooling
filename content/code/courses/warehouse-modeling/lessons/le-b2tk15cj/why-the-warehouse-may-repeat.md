---
title: What the reader pays for a normalised model
version: 1
---

Lesson 1's report asked the operational database for revenue by year and department. It needed six
tables: orders, order lines, books, and the category table three times over, one alias per level of the
tree. Against the star the same question needed three.

Every join a model makes a reader write has three costs, and only one of them is speed:

- **Knowledge.** Somebody has to know that the department is two parents up from a book's category,
  that the category table joins to itself, and that some branches are only two deep. Each of those is a
  fact about the schema that lives in a person's head or in a document nobody reads.
- **Correctness.** Every join is a place to get the condition wrong. Joining `categories` once instead
  of twice gives the subcategory where the department was meant, and the totals look perfectly
  reasonable.
- **Time.** A join is work for the database: a hash table built, a probe for every row. On small
  dimension tables in a columnar engine that work is small; section 06 measures how small.

**Denormalising moves those costs from every query to the load.** The load works out the department of
each book once, correctly, and writes it on the book's row. Every query after that reads a column.

That is the whole case for the star's dimensions, and it is a case about who pays. In the operational
database, the writers are many and the readers are few, so the writers' safety wins. In the warehouse,
the writer is one program and the readers are everybody, so the readers' convenience wins.
