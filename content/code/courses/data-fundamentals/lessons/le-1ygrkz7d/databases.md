---
title: Databases, and the copy that cannot see a delete
version: 1
---

**The app's database is the most valuable source at Roda Livre and the one most easily hurt by
reading it.** It answers the app: start a ride, end a ride, charge a card. Thousands of small
operations a day, each touching a handful of rows and each expected back in milliseconds. A database
built for that is called **OLTP**, for online transaction processing, and nearly every application's
database is one.

An analytical question is the opposite shape. "Rides per station per hour since January" is one
query that reads every row of the rides table. The wrong picture is that reading is harmless because
it changes nothing. A query that reads every row takes disk, memory and processor time the app was
using, and the customer trying to unlock a bicycle at Rua XV waits while it runs. In PostgreSQL, which
is what Roda Livre's app runs on, a read that stays open for an hour also stops the database clearing
away old versions of rows, so its tables grow until the read ends.

So the first rule has no exceptions at Roda Livre: **analytics never queries the primary**, the copy
of the database the app writes to. There are two ways round it. A **read replica** is a second copy the
database keeps up to date for exactly this, a few seconds behind the primary; lesson 9 says why it is
behind. Or the copy is taken at a quiet hour. Either way the data team reads a copy and the app keeps
its database to itself.

## Full or incremental

A copy can be taken two ways, and the difference is what each one can see.

- A **full copy** reads every row, every time, and replaces what was copied before. It is simple and
  it is always right: whatever the source holds, the copy holds. It also costs a little more every
  day the table grows.
- An **incremental copy** reads only the rows that changed since the last one. It needs a column
  the app updates on every change, usually `updated_at`, and it remembers the latest value it has
  seen. It costs the same whether the table holds a thousand rides or ten million.

Incremental is what everybody switches to once the full copy gets slow, and it has a blind spot that
is easiest to see by building it.

## A copy that keeps a cancelled ride

In the lab, SQLite stands in for the app's database: it is a file, it comes inside Python, and it
speaks SQL. Make the directory for this lesson's programs and work in it:

```sh
mkdir -p ~/roda/sources
cd ~/roda/sources
```

The first program is the app at 09:00 on 15 September, with four rides, two of them still open:

```python
# sources/app.py
import sqlite3

db = sqlite3.connect("app.db")
db.execute("DROP TABLE IF EXISTS rides")
db.execute("""CREATE TABLE rides (
    ride_id TEXT PRIMARY KEY, bike_id TEXT, station TEXT,
    status TEXT, updated_at TEXT)""")
db.executemany("INSERT INTO rides VALUES (?, ?, ?, ?, ?)", [
    ("R000101", "B017", "ST02", "finished", "2025-09-15 08:10"),
    ("R000102", "B044", "ST05", "finished", "2025-09-15 08:25"),
    ("R000103", "B081", "ST06", "open", "2025-09-15 08:40"),
    ("R000104", "B032", "ST02", "open", "2025-09-15 08:55"),
])
db.commit()
print("app.db holds", db.execute("SELECT count(*) FROM rides").fetchone()[0], "rides")
```

The second is the next quarter of an hour. One open ride finishes, a new one starts, and a customer
cancels ride `R000104` because the bicycle had a flat tyre. The app deletes cancelled rides, which is
a decision its team made for its own reasons:

```python
# sources/later.py
import sqlite3

db = sqlite3.connect("app.db")
db.execute("""UPDATE rides SET status = 'finished', updated_at = '2025-09-15 09:05'
              WHERE ride_id = 'R000103'""")
db.execute("""INSERT INTO rides
              VALUES ('R000105', 'B060', 'ST10', 'open', '2025-09-15 09:12')""")
db.execute("DELETE FROM rides WHERE ride_id = 'R000104'")
db.commit()
print("one ride finished, one started, one cancelled and deleted")
```

The third is Davi's incremental copy, into a second database file standing in for the data team's:

```schooling-example
{"language": "python", "file": "sources/incremental.py", "parts": [
{"code": "# sources/incremental.py\nimport sqlite3\n\nsrc = sqlite3.connect(\"app.db\")\ndst = sqlite3.connect(\"copy.db\")\ndst.execute(\"\"\"CREATE TABLE IF NOT EXISTS rides (\n    ride_id TEXT PRIMARY KEY, bike_id TEXT, station TEXT,\n    status TEXT, updated_at TEXT)\"\"\")\n", "note": "Two connections: `app.db` is the source, `copy.db` the data team's copy. The table is created the first time and left alone after that."},
{"code": "mark = dst.execute(\"SELECT max(updated_at) FROM rides\").fetchone()[0] or \"\"\n", "note": "The watermark: the latest `updated_at` already in the copy. On the first run the copy is empty, `max` returns `None`, and the empty string stands for \"before everything\"."},
{"code": "rows = src.execute(\"SELECT * FROM rides WHERE updated_at > ?\", (mark,)).fetchall()\ndst.executemany(\"INSERT OR REPLACE INTO rides VALUES (?, ?, ?, ?, ?)\", rows)\ndst.commit()\n", "note": "Only the rows changed after the watermark, written over any older version of the same ride. `INSERT OR REPLACE` is SQLite's way of saying \"insert, or replace the row with this key\"."},
{"code": "print(f\"changed since '{mark}': {len(rows)} rows copied\")\n", "note": "What this run copied."},
{"code": "for name, db in ((\"app.db\", src), (\"copy.db\", dst)):\n    ids = [r[0] for r in db.execute(\"SELECT ride_id FROM rides ORDER BY ride_id\")]\n    print(f\"{name:7}  {len(ids)} rides  {' '.join(ids)}\")\n", "note": "Then the comparison the copy never makes on its own: the rides in each database, side by side."}
]}
```

Run the app, copy, let a quarter of an hour pass, and copy again:

```
ana@lab:~/roda/sources$ python app.py
app.db holds 4 rides
ana@lab:~/roda/sources$ python incremental.py
changed since '': 4 rows copied
app.db   4 rides  R000101 R000102 R000103 R000104
copy.db  4 rides  R000101 R000102 R000103 R000104
ana@lab:~/roda/sources$ python later.py
one ride finished, one started, one cancelled and deleted
ana@lab:~/roda/sources$ python incremental.py
changed since '2025-09-15 08:55': 2 rows copied
app.db   4 rides  R000101 R000102 R000103 R000105
copy.db  5 rides  R000101 R000102 R000103 R000104 R000105
```

The first copy took all four rides, because nothing had been seen before. The second asked for rows
changed after `08:55` and got two: the finished ride and the new one. Both are right.

Then the two counts. **The app holds four rides and the copy holds five.** Ride `R000104` was deleted
from the source, and a deleted row has no `updated_at` to be newer than anything: it is simply not
there to be found. The copy will keep it, open, for as long as the copy exists. Nothing failed, and
every open-rides number built on this table is now wrong by one.

There are three ways out, and each costs something. The app can stop deleting and mark a cancelled
ride instead, with a column like `deleted_at`. That is a **soft delete**: it turns the delete into an
update the copy can see, but it is the app team's change to make. The data team can take a full
copy once a week and compare it with the incremental one; lesson 7 counts a copy against its source.
Or the copy can stop reading the table and read the database's own record of every change, which is
the next section.

The same blind spot has a twin. An incremental copy trusts the app to set `updated_at` on every
change; a code path that forgets is a change the copy never sees, and nothing anywhere says so.
Lesson 7 deals with the other trap in this program, a change that commits late with an earlier
`updated_at`.
