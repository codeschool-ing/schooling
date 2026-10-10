---
title: "Unit of work: one transaction per piece of business"
version: 1
---

**A unit of work is an object that collects the changes one piece of business makes and writes
them all in one transaction at the end.** The business code says *what* changed; the unit of work
decides *when* it reaches the database and makes sure it arrives whole. Martin Fowler named it in
*Patterns of Enterprise Application Architecture* in 2002, and every ORM you are likely to use is
built around one.

The habit it replaces is transactions opened wherever somebody needed one. A service function
starts a transaction, calls a helper, and the helper, written for another caller, commits. The
commit ends the outer transaction early, and everything after it runs loose. Picture a checkout of
three books built from a `lend_one` that commits after each book: when the third has no copy, the
first two are already lent, and the member walks away with a basket she did not ask for. **The
transaction boundary belongs to the use case, and only one piece of code should own it.**

Here is a unit of work small enough to read in one go. It knows one kind of change, a loan, and it
reuses the conditional `UPDATE` from the last section:

```schooling-example
{"language": "python", "file": "uow.py", "parts": [
 {"code": "# uow.py\nimport os\nimport sqlite3\n\nPATH = \"uow.db\"\n\n\nclass NoCopyLeft(Exception):\n    pass\n\n\nclass UnitOfWork:\n    def __init__(self, path: str):\n        self.path = path\n        self.loans: list[tuple[str, str]] = []\n\n    def __enter__(self) -> \"UnitOfWork\":\n        self.db = sqlite3.connect(self.path, isolation_level=None, timeout=1)\n        return self\n\n    def lend(self, title: str, member: str) -> None:\n        self.loans.append((title, member))", "note": "The unit of work keeps a list of what the business code asked for. Asking writes nothing yet."},
 {"code": "\n    def commit(self) -> None:\n        self.db.execute(\"BEGIN IMMEDIATE\")\n        try:\n            for title, member in self.loans:\n                cur = self.db.execute(\n                    \"UPDATE items SET available = available - 1\"\n                    \" WHERE title = ? AND available > 0\", (title,))\n                if cur.rowcount == 0:\n                    raise NoCopyLeft(title)\n                self.db.execute(\"INSERT INTO loans VALUES (?, ?)\", (title, member))\n        except Exception:\n            self.db.execute(\"ROLLBACK\")\n            raise\n        self.db.execute(\"COMMIT\")\n        self.loans.clear()", "note": "`commit` is the one place that knows about transactions. It takes the write lock, applies every change with the conditional `UPDATE` from the last section, and either commits all of them or rolls all of them back."},
 {"code": "\n    def __exit__(self, *exc) -> None:\n        self.loans.clear()\n        self.db.close()", "note": "Leaving the `with` block throws away anything not committed. Forgetting `commit` therefore writes nothing, which is the safe way round to forget."},
 {"code": "\n\ndef checkout(uow: UnitOfWork, member: str, titles: list[str]) -> None:\n    for title in titles:\n        uow.lend(title, member)\n    uow.commit()", "note": "The business code. It says what a checkout is, a member and some titles, and never mentions SQL, `BEGIN` or a connection."},
 {"code": "\n\ndef setup() -> None:\n    if os.path.exists(PATH):\n        os.remove(PATH)\n    db = sqlite3.connect(PATH)\n    db.executescript(\"\"\"\n        CREATE TABLE items (title TEXT PRIMARY KEY, available INTEGER NOT NULL);\n        CREATE TABLE loans (title TEXT NOT NULL, member TEXT NOT NULL);\n        INSERT INTO items VALUES ('Dom Casmurro', 2), ('Vidas Secas', 1), ('Iracema', 0);\n    \"\"\")\n    db.close()\n\n\ndef show(label: str) -> None:\n    db = sqlite3.connect(PATH)\n    loans = db.execute(\"SELECT title, member FROM loans\").fetchall()\n    stock = db.execute(\"SELECT title, available FROM items ORDER BY title\").fetchall()\n    print(f\"{label}\\n  loans: {loans}\\n  stock: {stock}\")\n    db.close()"},
 {"code": "\n\nif __name__ == \"__main__\":\n    setup()\n    with UnitOfWork(PATH) as uow:\n        try:\n            checkout(uow, \"Bia\", [\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\"])\n        except NoCopyLeft as err:\n            print(\"basket refused, no copy of\", err)\n    show(\"after Bia's basket\")\n\n    with UnitOfWork(PATH) as uow:\n        uow.lend(\"Dom Casmurro\", \"Caio\")\n    show(\"after Caio's, never committed\")\n\n    with UnitOfWork(PATH) as uow:\n        checkout(uow, \"Caio\", [\"Dom Casmurro\", \"Vidas Secas\"])\n    show(\"after Caio's, committed\")", "note": "Three checkouts: Bia's basket includes *Iracema*, which has no copy; Caio's first attempt registers a loan and never commits; his second is a basket that fits."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 uow.py
basket refused, no copy of Iracema
after Bia's basket
  loans: []
  stock: [('Dom Casmurro', 2), ('Iracema', 0), ('Vidas Secas', 1)]
after Caio's, never committed
  loans: []
  stock: [('Dom Casmurro', 2), ('Iracema', 0), ('Vidas Secas', 1)]
after Caio's, committed
  loans: [('Dom Casmurro', 'Caio'), ('Vidas Secas', 'Caio')]
  stock: [('Dom Casmurro', 1), ('Iracema', 0), ('Vidas Secas', 0)]
```

Bia's basket asked for three titles, and *Iracema* had none. The two loans before it were never
written: the stock still reads 2 for *Dom Casmurro* and 1 for *Vidas Secas*, and the loans table is
empty. Caio's first visit registered a loan and left the block without `commit`, and nothing was
written either. His second visit fits, and both changes land together: two loans, and both stock
counts down by one.

`checkout` is four lines and would read the same against PostgreSQL, a file of JSON or a fake in a
test. That is the design payoff. The rule *a basket is lent whole or not at all* is written once,
in `commit`, and no function that registers a loan can break it by committing early, because none
of them can commit.

## The ones you already use

Fowler's version tracks three lists, the new objects, the changed ones and the removed ones, and
works out the SQL at commit time. The tools below do that for you, under different names:

| language | the unit of work | the commit |
|---|---|---|
| Python | SQLAlchemy's `Session` | `session.commit()`; `session.add(obj)` registers |
| Java | JPA's `EntityManager` and its persistence context | the transaction's commit flushes every changed entity |
| C# | Entity Framework's `DbContext` | `SaveChanges()` |
| TypeScript | TypeORM's `EntityManager`, Prisma's `$transaction` | the end of the callback |
| Go | none in the standard library | you pass a `*sql.Tx`, or a small struct like the one above, down the call |

Go's row is the honest one. Without an ORM, a unit of work is a value you hand to the code that
needs it, and the code that created it calls `Commit`. Lesson 5's constructor injection is the
usual way to hand it over.

## Where one starts and stops

One unit of work per use case: one request, one command, one job. The code at the edge opens it,
the code in the middle registers changes, and the edge commits or lets it be thrown away. Lesson 8's
command handlers are the natural owners, since a command is already one piece of business. Two
consequences follow, and both come back in lesson 12:

- a unit of work that grows to cover several unrelated things is a transaction that holds locks
  for longer and fails for more reasons; keep it to the one thing the use case changes;
- the business code that registers changes can be tested against a fake that records them and
  commits nothing, the same move lesson 12 makes with an in-memory repository.
