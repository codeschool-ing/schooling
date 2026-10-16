---
title: The drill that fails for its own reasons
version: 1
---

The script compares the live database, read just after the restore point, with a copy restored to
the restore point. On a quiet database those are the same moment. Run it while something writes:

```
ana@vm:~$ (for i in $(seq 1 600); do psql -q bigshop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (1, 900, now())"; done) &
ana@vm:~$ ./restore-drill.sh
2c2
< orders|3000005|77a66ec5301cb1082a6322c490cf710f
---
> orders|3000001|bcb0f27f7cde0fa846ef5b667234b468
2026-10-10 16:50:34,20261010-164946F,3.2,2.5,6.7,17.9,DIFFERENT
ana@vm:~$ echo $?
1
ana@vm:~$ wait
```

**`DIFFERENT`, and an exit status of 1.** `diff` shows why: the live report counted 3000005 orders
in `bigshop`, the restored copy 3000001. Four orders were inserted in the instant between the restore
point and the live report reading the table. The backup is perfect, and the drill failed.

That is worse than it sounds. A drill that fails now and then for reasons that have nothing to do
with the backup teaches everybody who reads it to ignore its failures, and one day the failure it
ignores is real. **A drill has to be built so that a red result always means something.**

## Making the two sides one moment

The failure comes from reading the live side at a different instant from the one restored. There are
three ways to close the gap, from crude to exact:

- **Run the drill when nothing writes.** A maintenance window, or a database that is idle at night.
  Simple, and it depends on the database cooperating.
- **Compare only what cannot move.** Counts and fingerprints of tables that are never written to
  after the day closes, or rows older than the restore point. Weaker, and it keeps working on a busy
  system.
- **Read the live side inside one snapshot, and restore to exactly that snapshot's time.** Begin a
  `REPEATABLE READ` transaction, ask `now()` (which in PostgreSQL is the moment the transaction
  started), run the whole report inside it, and restore with `--type=time` to that moment. Every
  statement of the report sees the database as of one instant, and the restore stops at the same one.
  This is what the drill the platform runs does.

The third has one edge worth knowing, and the platform's drill names it in its own output rather than
hiding it: a row committed in the same instant as the snapshot can land on one side only, so a
difference of a row or two on one busy table, once, is not a fault. **A real fault repeats.**

The lab's drill keeps the first approach, because nothing writes to your shop unless you make it, and
because the version above is a few lines longer than this lesson needs. Whichever you use, write down
which, in the script, where the next person will read it.
