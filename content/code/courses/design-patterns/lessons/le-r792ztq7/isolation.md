---
title: "Isolation: two desks, one copy"
version: 1
---

**Isolation is the letter about two transactions running at the same time, and the failure it
exists to prevent has a name: the lost update.** Two people read the same value, each decides
something from it, and each writes back a result. The second write quietly replaces the first, and
neither person did anything wrong on their own.

The wrong idea here is that atomicity covers it. Each desk's work in the program below is short
and each statement succeeds. The library still ends up with two loans for one copy, because the
problem is not a statement that fails halfway. It is two correct pieces of work that overlap.

The library has one copy of *Vidas Secas* left. Bia is at desk A and Caio at desk B, and both ask
for it in the same moment. The program plays the two desks three times, with no transaction, with
a plain `BEGIN` and with `BEGIN IMMEDIATE`:

```schooling-example
{"language": "python", "file": "desks.py", "parts": [
 {"code": "# desks.py\nimport os\nimport sqlite3\n\nPATH = \"desks.db\"\n\n\ndef fresh_library() -> None:\n    if os.path.exists(PATH):\n        os.remove(PATH)\n    db = sqlite3.connect(PATH, isolation_level=None)\n    db.executescript(\"\"\"\n        CREATE TABLE items (title TEXT PRIMARY KEY, available INTEGER NOT NULL);\n        CREATE TABLE loans (title TEXT NOT NULL, member TEXT NOT NULL);\n        INSERT INTO items VALUES ('Vidas Secas', 1);\n    \"\"\")\n    db.close()", "note": "A file this time, because two desks need two connections to the same database. Every run starts from one copy of *Vidas Secas* and no loans."},
 {"code": "\n\ndef desk() -> sqlite3.Connection:\n    return sqlite3.connect(PATH, isolation_level=None, timeout=0.1)", "note": "Each desk is its own connection. `timeout=0.1` makes a desk that finds the database locked give up after a tenth of a second instead of the default five."},
 {"code": "\n\ndef copies(db) -> int:\n    return db.execute(\"SELECT available FROM items WHERE title = 'Vidas Secas'\").fetchone()[0]\n\n\ndef lend(db, member: str, seen: int) -> None:\n    db.execute(\"UPDATE items SET available = ? WHERE title = 'Vidas Secas'\", (seen - 1,))\n    db.execute(\"INSERT INTO loans VALUES ('Vidas Secas', ?)\", (member,))", "note": "This is the shape of the bug: read a number, decide in Python, write back the number you computed. `lend` writes `seen - 1` whatever the row says by then."},
 {"code": "\n\ndef report(label: str) -> None:\n    db = desk()\n    n = db.execute(\"SELECT count(*) FROM loans\").fetchone()[0]\n    print(f\"{label}: available={copies(db)}, loans={n}\")\n    db.close()"},
 {"code": "\n\ndef no_transaction() -> None:\n    a, b = desk(), desk()\n    seen_a = copies(a)\n    seen_b = copies(b)\n    if seen_a > 0:\n        lend(a, \"Bia\", seen_a)\n    if seen_b > 0:\n        lend(b, \"Caio\", seen_b)", "note": "No transaction. The two desks are interleaved by hand, in one thread, so the run prints the same thing every time: both read, then both write."},
 {"code": "\n\ndef plain_begin() -> None:\n    a, b = desk(), desk()\n    a.execute(\"BEGIN\")\n    seen_a = copies(a)\n    b.execute(\"BEGIN\")\n    seen_b = copies(b)\n    lend(a, \"Bia\", seen_a)\n    try:\n        lend(b, \"Caio\", seen_b)\n    except sqlite3.OperationalError as err:\n        print(\"  desk B writes:\", err)\n    try:\n        a.execute(\"COMMIT\")\n    except sqlite3.OperationalError as err:\n        print(\"  desk A commits:\", err)\n    b.execute(\"ROLLBACK\")\n    a.execute(\"COMMIT\")", "note": "A plain `BEGIN` takes no lock until the first write. Both desks read inside their transactions, desk A writes, and then each one is waiting for the other."},
 {"code": "\n\ndef begin_immediate() -> None:\n    a, b = desk(), desk()\n    a.execute(\"BEGIN IMMEDIATE\")\n    seen_a = copies(a)\n    try:\n        b.execute(\"BEGIN IMMEDIATE\")\n    except sqlite3.OperationalError as err:\n        print(\"  desk B begins:\", err)\n    lend(a, \"Bia\", seen_a)\n    a.execute(\"COMMIT\")\n    b.execute(\"BEGIN IMMEDIATE\")\n    if copies(b) > 0:\n        lend(b, \"Caio\", copies(b))\n    else:\n        print(\"  desk B: no copy left for Caio\")\n    b.execute(\"COMMIT\")", "note": "`BEGIN IMMEDIATE` takes the write lock before the read. Desk B cannot even start until desk A has finished, and when it does start, it reads the number desk A left."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for run in (no_transaction, plain_begin, begin_immediate):\n        fresh_library()\n        print(run.__name__)\n        run()\n        report(\"  result\")"}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 desks.py
no_transaction
  result: available=0, loans=2
plain_begin
  desk B writes: database is locked
  desk A commits: database is locked
  result: available=0, loans=1
begin_immediate
  desk B begins: database is locked
  desk B: no copy left for Caio
  result: available=0, loans=1
```

**The first run is the lost update, and nothing in it raised an error.** Both desks saw one copy,
both lent it, and the count says 0 while the loans table says 2. Desk A's write of 0 was replaced
by desk B's write of 0, which was computed from a number that had stopped being true. A report
that counted loans against stock would find it weeks later.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" data-fig=\"l10-lost-update\" aria-label=\"A timeline of the lost update in desks.py, read from top to bottom. Desk A on the left, the items row in the middle, desk B on the right. First desk A reads available 1. Then desk B reads available 1. Then desk A writes 0 and records a loan for Bia. Then desk B writes 0, computed from the 1 it read earlier, and records a loan for Caio. The row ends at available 0 with two loans for one copy, and no step raised an error.\"><defs><marker id=\"l10-lost-update-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l10-lost-update-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"55.0\" y=\"15.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desk A (Bia)</text><rect x=\"265.0\" y=\"15.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">items row</text><rect x=\"495.0\" y=\"15.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desk B (Caio)</text><path d=\"M130.0 47.0 L130.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 98.0 L130.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 208.0 L130.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570.0 47.0 L570.0 127.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570.0 153.0 L570.0 237.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570.0 263.0 L570.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 47.0 L350.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 98.0 L350.0 127.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 153.0 L350.0 176.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 214.0 L350.0 231.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 269.0 L350.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M28.0 66.0 L28.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-paper-dim)\"></path><text x=\"28.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><path d=\"M278.0 85.0 L200.0 85.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-paper-dim)\"></path><text x=\"239.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads 1</text><rect x=\"280.0\" y=\"74.0\" width=\"140.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 1</text><rect x=\"62.0\" y=\"74.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT</text><path d=\"M422.0 140.0 L500.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-paper-dim)\"></path><text x=\"461.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads 1</text><rect x=\"280.0\" y=\"129.0\" width=\"140.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 1</text><rect x=\"502.0\" y=\"129.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT</text><path d=\"M200.0 195.0 L278.0 195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-phosphor)\"></path><text x=\"239.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">writes 1 - 1</text><rect x=\"280.0\" y=\"178.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"189.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 0</text><text x=\"350.0\" y=\"200.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">loans: 1</text><rect x=\"62.0\" y=\"184.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">UPDATE + INSERT</text><path d=\"M500.0 250.0 L422.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-phosphor)\"></path><text x=\"461.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">writes 1 - 1</text><rect x=\"280.0\" y=\"233.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"244.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 0</text><text x=\"350.0\" y=\"255.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">loans: 2</text><rect x=\"502.0\" y=\"239.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">UPDATE + INSERT</text><text x=\"350.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">one copy, two loans, no error</text></svg>", "caption": "The lost update. Desk B writes a number it computed from a value that desk A had already changed."}
```

The second run is SQLite refusing to lose the update, and paying for it. Desk A holds the right to
write and wants to commit; desk B holds a read it has not let go of. SQLite, in its default
journal mode, will not let A commit over B's read, and will not let B write while A is writing, so
each desk got `database is locked` until desk B rolled back. **Correct, and nobody got served until one side gave up.** A real program
would have to catch that error and retry the whole transaction, reading again.

The third run takes the write lock before reading. Desk B's `BEGIN IMMEDIATE` is refused at once,
before it has read anything. When it tries again after desk A has committed, it reads 0 and tells
Caio there is no copy. That is the behaviour the library wanted from the start: one loan, and a
refusal that is true.

## Isolation levels, and why SQLite looks strict

The SQL standard names four levels, from the weakest: *read uncommitted*, *read committed*,
*repeatable read* and *serializable*. Each one forbids more of the ways two transactions can see
each other's work. SQLite has only one writer at a time, so its transactions behave as
serializable, which is why the second run refused rather than lost anything.

Servers mostly default to something weaker, and the difference matters for exactly this program:

| database | default level | what the read-then-write of `lend` does inside one transaction |
|---|---|---|
| SQLite | serializable | refused with `database is locked`, as in the second run |
| PostgreSQL | read committed | **loses the update**, as in the first run, unless the read says `FOR UPDATE` |
| MySQL (InnoDB) | repeatable read | loses the update too: the second `UPDATE` waits for the first and then overwrites it |

So "I put it in a transaction" protects you on SQLite and does not on a PostgreSQL left at its
default. On PostgreSQL, `SELECT available FROM items WHERE title = $1 FOR UPDATE` locks the row
when it is read, which is what `BEGIN IMMEDIATE` did for the whole file here. Raising the level to
`REPEATABLE READ` makes PostgreSQL abort the second transaction with a serialization error instead,
which, like the second run, your code then has to retry.

## The fix that holds no lock across Python

The bug lives in the round trip: the number travels to Python, gets decided on, and comes back. Put
the decision in the statement and the round trip disappears:

```sql
UPDATE items SET available = available - 1
 WHERE title = 'Vidas Secas' AND available > 0;
```

The database checks and changes the row in one step. If the copy is gone, the statement changes
zero rows, and the program reads that from the cursor's `rowcount` and refuses. It works the same
way at every isolation level of every database above, which makes it the first thing to reach for
when the rule fits in a `WHERE`. The next section's unit of work uses it.
