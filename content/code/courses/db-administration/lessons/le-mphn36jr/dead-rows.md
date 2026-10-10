---
title: An UPDATE leaves the old row behind
version: 1
---

The picture most people carry is that an `UPDATE` finds the row and changes it where it lies.
**PostgreSQL never does that.** It writes a complete new version of the row somewhere else and
leaves the old one where it was, marked with the transaction that replaced it. sql-databases
lesson 8 showed the reason from the reader's side: a transaction at `REPEATABLE READ` keeps seeing
the data as it was when it began, and the only way to show somebody the old value is to still have
it. This section looks at the same thing from the storage side.

Everything in this lesson happens on a copy of `orders`, so `shop` stays as lesson 4 left it and
the lessons after this one start from the same tables you have. The copy gets a primary key, and a
`VACUUM ANALYZE` so it starts tidy. `pageinspect` is an extension that ships with PostgreSQL and
reads a table's pages raw; the last section drops it again.

<<<dead-rows 1-10>>>

Three hidden columns tell the story, and every table has them. **`ctid` is where a version lives**:
page 0, item 7, at first. **`xmin` is the transaction that wrote the version**, here the one that
loaded the copy, and **`xmax` is the transaction that deleted or replaced it**, 0 while nobody has.

After the `UPDATE`, row 7 answers from `(8333,41)`, the last page of the table, written by
transaction 786. Page 0 was full, so the new version went where there was room. `heap_page_items`
shows what is still on page 0: item 7 is the old version, intact, with `t_xmax` set to 786 and
`t_ctid` pointing at the new one. Any transaction that started before 786 committed still reads
`paid` from it.

Once 786 commits and no running transaction is old enough to need the old version, **it is dead**:
it takes the same space as a live row and nothing will ever read it. A `DELETE` leaves a dead
version the same way, with no new one beside it. A `ROLLBACK` leaves one too, the other way round:
the new version it wrote is the one nobody will see.

<<<dead-rows 11-14>>>

**`n_dead_tup` is the server's count of dead versions**, kept per table in `pg_stat_user_tables`:
one from the committed `UPDATE` of row 7 and one from the `UPDATE` that rolled back. A session sends
its counts when it has been idle for a moment, so a query typed straight after a change can show
the number from before it.

Two dead versions in a million rows cost nothing. An application that updates every order's status
three times on its way to `shipped` leaves three dead versions per order, and **a table whose rows
change often holds as much dead space as live data** unless something comes along and reclaims it.
That something is `VACUUM`.
