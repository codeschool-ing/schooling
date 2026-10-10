---
title: "The event store: a table that only grows"
version: 1
---

**An event store is an append-only list of events, grouped into streams, one stream per thing whose
history you keep, with a version number per stream that makes concurrent writers find out about
each other.** That is the whole of it. Products such as EventStoreDB add subscriptions, clustering
and tooling, and plenty of systems keep their events in an ordinary PostgreSQL table; underneath,
both are the table below.

The mistake to avoid is treating the store as a message queue. A queue forgets a message once it is
delivered. A store keeps every event for as long as the system lives, because the events are the
data: delete one and some member's balance changes silently.

```schooling-example
{"language": "python", "file": "store.py", "parts": [
 {"code": "# store.py\nimport json\nimport sqlite3\n\n\nclass ConcurrencyError(Exception):\n    pass", "note": "SQLite and JSON, both in the standard library. The one exception the store raises is its own, so callers can tell a conflict from any other database error."},
 {"code": "\n\nclass EventStore:\n    def __init__(self, path: str):\n        self.db = sqlite3.connect(path)\n        self.db.executescript(\"\"\"\n            CREATE TABLE IF NOT EXISTS events (\n                position INTEGER PRIMARY KEY AUTOINCREMENT,\n                stream TEXT NOT NULL,\n                version INTEGER NOT NULL,\n                type TEXT NOT NULL,\n                data TEXT NOT NULL,\n                UNIQUE (stream, version));", "note": "One table. `position` orders every event in the store; `stream` and `version` order the events of one thing, here one member. `UNIQUE (stream, version)` is the whole concurrency control, as the end of the program shows."},
 {"code": "            CREATE TRIGGER IF NOT EXISTS events_are_history\n                BEFORE UPDATE ON events\n                BEGIN SELECT RAISE(ABORT, 'events are append-only'); END;\n            CREATE TRIGGER IF NOT EXISTS events_stay\n                BEFORE DELETE ON events\n                BEGIN SELECT RAISE(ABORT, 'events are append-only'); END;\"\"\")", "note": "Append-only as a promise in the database, not a habit in the code: an `UPDATE` or a `DELETE` on this table is refused whoever sends it, a script at a prompt included."},
 {"code": "\n    def version(self, stream: str) -> int:\n        row = self.db.execute(\"SELECT max(version) FROM events WHERE stream = ?\", (stream,)).fetchone()\n        return row[0] or 0", "note": "A stream's version is the number of events in it."},
 {"code": "\n    def append(self, stream: str, expected: int, events: list[dict]) -> None:\n        try:\n            with self.db:\n                for i, event in enumerate(events, start=expected + 1):\n                    data = {k: v for k, v in event.items() if k != \"type\"}\n                    self.db.execute(\"INSERT INTO events (stream, version, type, data) VALUES (?, ?, ?, ?)\",\n                                    (stream, i, event[\"type\"], json.dumps(data)))\n        except sqlite3.IntegrityError:\n            raise ConcurrencyError(f\"{stream} is past version {expected}\") from None", "note": "Appending says which version the caller last saw. If somebody else appended in the meantime, the next version number is taken, the insert hits the unique constraint, and the whole batch is rolled back by `with self.db`. This is optimistic concurrency: nothing is locked, and the loser is told."},
 {"code": "\n    def read(self, stream: str, after: int = 0) -> list[dict]:\n        rows = self.db.execute(\"SELECT type, data FROM events WHERE stream = ? AND version > ?\"\n                               \" ORDER BY version\", (stream, after))\n        return [{\"type\": t, **json.loads(d)} for t, d in rows]", "note": "Reading one stream, optionally after a version, which the snapshot section uses."},
 {"code": "\n    def read_all(self, after: int = 0) -> list[tuple[int, dict]]:\n        rows = self.db.execute(\"SELECT position, stream, type, data FROM events\"\n                               \" WHERE position > ? ORDER BY position\", (after,))\n        return [(p, {\"type\": t, \"stream\": s, **json.loads(d)}) for p, s, t, d in rows]", "note": "Reading every stream in the order things happened, from a position onwards. Projections read this way."},
 {"code": "\n\nif __name__ == \"__main__\":\n    store = EventStore(\":memory:\")\n    store.append(\"member-bia\", 0, [\n        {\"type\": \"MemberJoined\", \"name\": \"Bia\", \"on\": \"2026-03-01\"},\n        {\"type\": \"CopyLent\", \"copy\": \"C3\", \"title\": \"T2\", \"due\": \"2026-03-16\"},\n    ])\n    store.append(\"member-bia\", 2, [\n        {\"type\": \"CopyReturned\", \"copy\": \"C3\", \"on\": \"2026-03-19\", \"fine\": 150},\n    ])\n    for event in store.read(\"member-bia\"):\n        print(event)\n    print(\"version:\", store.version(\"member-bia\"))\n    try:\n        store.append(\"member-bia\", 2, [{\"type\": \"FinePaid\", \"amount\": 150}])\n    except ConcurrencyError as err:\n        print(\"refused:\", err)\n    try:\n        store.db.execute(\"UPDATE events SET data = '{}' WHERE version = 3\")\n    except sqlite3.DatabaseError as err:\n        print(\"refused:\", err)", "note": "Two appends to Bia's stream, the read-back, then two things the store refuses: an append from somebody who saw version 2 after it became 3, and an edit to history. The store lives in memory, so the program can be run again and again; give it a file name and it keeps the events."}
]}
```

```
ana@laptop:~/patterns/events$ python3 store.py
placeholder
```

The three events come back in order, as dictionaries with their type. Bia's stream is at version 3.
Then the two refusals: an append that expected version 2 lost the race, and the `UPDATE` was stopped
by the trigger with the sentence it was given.

## A stream per thing

Which events belong together is a design decision. Here the stream is a member, `member-bia`,
because the rules this lesson checks are about one member: what she holds and what she owes. A
library might also keep a stream per copy, or per title's reservation queue. **The stream is the
boundary of a decision**: every rule that has to see a consistent set of facts reads one stream and
appends to it with one expected version. Lesson 12 calls that boundary an aggregate and argues where
to draw it; this lesson takes members as the boundary and moves on.

## Optimistic concurrency, by the unique constraint

Two desk clerks serve Bia at once. Both read her stream at version 2, both decide she may borrow,
both append. Without a check, she ends up with a loan the rules would have refused. With the check,
the first append writes version 3; the second tries to write version 3 too, the unique index
refuses it, and that clerk gets `ConcurrencyError`. **The loser re-reads the stream, which now
contains the other clerk's loan, and runs the rules again.** Nothing was locked while either clerk
was deciding.

This is the same compare-and-set that lesson 8 said a command may legitimately combine with an
answer: the check and the write happen in one statement, so nothing can slip between them.

## In your language

| | how the same store is usually written |
|---|---|
| Java | a JPA entity or plain JDBC over PostgreSQL, the unique constraint the same; or the EventStoreDB client, whose `appendToStream` takes an expected revision |
| Go | `database/sql` with the same table; a unique-violation error code mapped to a sentinel `ErrConcurrency` |
| TypeScript | a Node PostgreSQL client and the same `INSERT`; the error code `23505` is the unique violation |
| Python | the table above, or the same SQL against PostgreSQL with `psycopg` |

In every row the guarantee comes from the database's unique index, not from the language. That is
deliberate: a check in application code would be the read-then-write race of lesson 8's
command-query section.
