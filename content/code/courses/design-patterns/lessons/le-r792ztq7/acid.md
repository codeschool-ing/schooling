---
title: "ACID: all of it or none of it"
version: 1
---

**A transaction is a promise about a group of changes: either every one of them happens, or none
of them does, and nobody sees the group half done.** ACID is the name for that promise, taken
apart into four letters by Theo Härder and Andreas Reuter in 1983. The letters are worth knowing.
The habit behind them is worth more, and it starts with a belief that is wrong.

The belief is that your code runs in a transaction because it talks to a database. Most drivers
start in *autocommit*: every statement is a transaction of its own, committed the moment it
finishes. Two statements that belong together are two transactions unless somebody says
otherwise, and the gap between them is where a crash, an error or a typo lands.

Every program in this lesson works in one directory:

```sh
mkdir -p ~/patterns/acid-cap
cd ~/patterns/acid-cap
```

## A hold that vanishes

The library keeps a queue of holds for each title. A member at the desk asks to pass her place in
the queue for *Dom Casmurro* to a friend. That is a delete and an insert, and the program below
does it twice: once as two loose statements, once inside a transaction. Both times the librarian
types the friend's card number wrong.

```schooling-example
{"language": "python", "file": "reserve.py", "parts": [
 {"code": "# reserve.py\nimport sqlite3\n\n\ndef open_library() -> sqlite3.Connection:\n    db = sqlite3.connect(\":memory:\", isolation_level=None)\n    db.execute(\"PRAGMA foreign_keys = ON\")", "note": "`isolation_level=None` switches off the module's habit of opening transactions on its own, so every `BEGIN` in this lesson is one you can see. Foreign keys are off by default in SQLite; the pragma turns them on for this connection."},
 {"code": "    db.executescript(\"\"\"\n        CREATE TABLE members (id TEXT PRIMARY KEY, name TEXT NOT NULL);\n        CREATE TABLE holds (\n            title  TEXT NOT NULL,\n            member TEXT NOT NULL REFERENCES members(id),\n            place  INTEGER NOT NULL CHECK (place > 0)\n        );\n        INSERT INTO members VALUES ('m-001', 'Bia'), ('m-002', 'Caio');\n        INSERT INTO holds VALUES ('Dom Casmurro', 'm-001', 1),\n                                 ('Dom Casmurro', 'm-002', 2);\n    \"\"\")\n    return db", "note": "Two members queue for *Dom Casmurro*: Bia first, Caio second. A hold must name a member who exists, and its place must be positive. Those two rules belong to the database, not to the Python."},
 {"code": "\n\ndef move_hold(db, title: str, src: str, dst: str) -> None:\n    place = db.execute(\"SELECT place FROM holds WHERE title = ? AND member = ?\",\n                       (title, src)).fetchone()[0]\n    db.execute(\"DELETE FROM holds WHERE title = ? AND member = ?\", (title, src))\n    db.execute(\"INSERT INTO holds VALUES (?, ?, ?)\", (title, dst, place))", "note": "Moving a hold to another member is two statements: take it away from one, give it to the other. Nothing here groups them, so each one is committed the moment it runs."},
 {"code": "\n\ndef move_hold_atomically(db, title: str, src: str, dst: str) -> None:\n    db.execute(\"BEGIN\")\n    try:\n        move_hold(db, title, src, dst)\n    except Exception:\n        db.execute(\"ROLLBACK\")\n        raise\n    db.execute(\"COMMIT\")", "note": "The same two statements inside `BEGIN` and `COMMIT`. If anything raises in between, `ROLLBACK` undoes whatever already ran, and the error goes on to the caller."},
 {"code": "\n\ndef queue(db) -> list[tuple]:\n    return db.execute(\"SELECT place, member FROM holds ORDER BY place\").fetchall()"},
 {"code": "\n\nif __name__ == \"__main__\":\n    for move in (move_hold, move_hold_atomically):\n        db = open_library()\n        try:\n            move(db, \"Dom Casmurro\", \"m-001\", \"m-009\")\n        except sqlite3.IntegrityError as err:\n            print(f\"{move.__name__}: {err}\")\n        print(\"  queue now:\", queue(db))", "note": "Each version gets a fresh library and the same mistake at the desk: the hold goes to `m-009`, a card number nobody has."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 reserve.py
move_hold: FOREIGN KEY constraint failed
  queue now: [(2, 'm-002')]
move_hold_atomically: FOREIGN KEY constraint failed
  queue now: [(1, 'm-001'), (2, 'm-002')]
```

Both versions hit the same error: the database refused a hold for a member who does not exist.
What differs is what the error left behind. **Without a transaction, Bia's place is gone and
nobody has it**: the delete had already been committed when the insert failed, so the queue holds
only Caio, at place 2, behind nobody. With the transaction, `ROLLBACK` put the delete back and the
queue is exactly what it was. Bia can try again with the right number.

Nothing in `move_hold` is wrong line by line. The defect is in what is missing around it, and no
test of either statement on its own would find it.

## The four letters, in this program

| letter | the promise | where it shows in `reserve.py` |
|---|---|---|
| **A**tomicity | the group happens whole or not at all | `ROLLBACK` undid the delete when the insert failed |
| **C**onsistency | a transaction moves the data from one valid state to another | the foreign key refused `m-009`; the `CHECK` would refuse a place of 0 |
| **I**solation | transactions running at once do not see each other's halves | not shown here; the next section is about it |
| **D**urability | once `COMMIT` returns, a crash does not undo it | absent: this database lives in memory and dies with the process |

**The C is the odd letter.** Atomicity, isolation and durability are things the database does for
you. Consistency is mostly yours: the database can hold the rules you wrote down as constraints,
like the foreign key above, and nothing else. A rule that lives only in Python, say "a member may
hold at most five titles", is kept only if every change that could break it runs inside a
transaction that checks it. Lesson 12 gives that kind of rule a home of its own, the aggregate.

Durability needs a file. A database on disk, written with SQLite's default settings, has made sure
the change is on the disk before `COMMIT` returns. The two sections after this one use a file for
that reason, and because two connections to one memory database are not possible without extra
work.

## Transactions in your language

Python's `sqlite3` module, left at its defaults, opens a transaction by itself before the first
`INSERT`, `UPDATE` or `DELETE`, and `with db:` commits at the end of the block or rolls back on an
exception. That is convenient and it hides the `BEGIN`, which is why this lesson turns it off.
Python 3.12 added an `autocommit` argument to `connect` that says the same thing more plainly.

| language | the usual way | the trap |
|---|---|---|
| Java (JDBC) | `conn.setAutoCommit(false)`, then `commit()` or `rollback()` | autocommit is on until you turn it off |
| Go (`database/sql`) | `tx, err := db.BeginTx(ctx, nil)`, then `tx.Commit()`, with `defer tx.Rollback()` | `db.Exec("BEGIN")` on the pool may run on one connection and the next statement on another |
| TypeScript (`pg`) | `const client = await pool.connect()`, then `BEGIN` and `COMMIT` on that client | `pool.query("BEGIN")` has the same problem as Go's: each query can get a different connection |

The trap in the last two rows is the same one. A transaction belongs to a **connection**, and a pool
hands out connections per call. Go's `Tx` and `pg`'s checked-out client exist to keep every
statement of a transaction on one of them.
