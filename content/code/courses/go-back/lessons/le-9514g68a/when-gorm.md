---
title: When GORM is the right tool
version: 1
---

The sections before this one could read as a case against GORM, and that would be the wrong lesson to
take from them. **Every pitfall was a rule, applied consistently**, and a team that knows the rules uses
GORM productively for years. The question is which services repay learning them.

## Where it fits

- **Many tables, mostly plain create, read, update and delete.** An internal tool or an admin back end
  with thirty tables and a form for each is exactly what an ORM was invented for. The SQL for those
  operations is boring, and GORM writes it correctly.
- **A team arriving from Rails, Django or Hibernate**, for whom models and associations are the natural
  way to think about data.
- **Prototypes**, where `AutoMigrate` turning a struct into a table in one call is worth more than a
  migration history nobody needs yet.
- **Several databases**, if a product must really run on PostgreSQL and on MySQL, and the SQL must stay
  portable.

## Where it gets in the way

- **When the queries are the product.** Reports, aggregations, anything with a `GROUP BY` or a window
  function: section 06's sum was one `SELECT` in SQL and awkward through the ORM.
- **When performance is watched query by query.** Every statement is generated, so finding the slow one
  means reading the log rather than the code, and N+1 is one loop away.
- **When the database's own rules matter.** Section 03's table lacked the check that `sold` stays within
  `seats`; boxoffice depends on that rule more than on any line of Go.
- **When other programs share the database.** Soft deletes and GORM's other conventions live in GORM.

## And boxoffice

boxoffice stays on lesson 6's pgx code. It has one table so far, a second one coming in lesson 9, and
its most important operation is one carefully written `UPDATE` whose `WHERE` clause is the whole point.
**An ORM would hide exactly the line that matters most.** That is not a verdict on GORM; it is the shape
of this particular service.

There is a third way, between writing every scan by hand and letting the ORM write the SQL: write the
SQL yourself, and let a tool write the Go. That is lesson 8.
