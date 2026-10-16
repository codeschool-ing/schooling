---
title: Change data capture, or reading what the database wrote down
version: 1
---

**A database writes every change to a log before it changes the table, and change data capture
reads that log instead of the table.** The log is not there for anybody's analytics. PostgreSQL calls
it the write-ahead log and MySQL the binary log, and each keeps one for its own sake: to recover after
a crash, and to keep its replicas up to date. Because it records changes rather than state, it holds
exactly what the previous section's copy could not see. A delete is a change, so the log has it. Two
updates to one ride are two entries, in the order they happened, where a table only ever shows the
second.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 264\" role=\"img\" aria-label=\"The app writes to the database. Inside it, the log holds three numbered changes: an update of R000103, an insert of R000105 and a delete of R000104; the rides table holds the result, four rides without R000104. A copy by updated_at reads the table and finds R000103 and R000105 but cannot see the delete. A CDC reader reads the log and gets all three changes in order.\" data-fig=\"cdc\"><defs><marker id=\"cdc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"152\" y=\"14\" width=\"286\" height=\"240\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"295\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">the database</text><rect x=\"14\" y=\"181\" width=\"116\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the app</text><line x1=\"130\" y1=\"204\" x2=\"168\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><rect x=\"170\" y=\"44\" width=\"250\" height=\"102\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the rides table</text><text x=\"295.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000101  finished</text><text x=\"295.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000102  finished</text><text x=\"295.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000103  finished</text><text x=\"295.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000105  open</text><rect x=\"170\" y=\"166\" width=\"250\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">its log, written first</text><text x=\"295.0\" y=\"196.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1  update  R000103</text><text x=\"295.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2  insert  R000105</text><text x=\"295.0\" y=\"226.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3  delete  R000104</text><line x1=\"295\" y1=\"166\" x2=\"295\" y2=\"148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><line x1=\"420\" y1=\"94\" x2=\"474\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><rect x=\"476\" y=\"54\" width=\"230\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"591.0\" y=\"78.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">a copy by updated_at</text><text x=\"591.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finds R000103 and R000105</text><text x=\"591.0\" y=\"109.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">R000104 is simply gone</text><line x1=\"420\" y1=\"204\" x2=\"474\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#cdc-ah)\"></line><rect x=\"476\" y=\"166\" width=\"230\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"591.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">a CDC reader</text><text x=\"591.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reads changes 1, 2 and 3</text><text x=\"591.0\" y=\"219.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the delete included</text></svg>", "caption": "The database writes each change to its log, then applies it to the table. A copy that reads the table finds the rows that are there; a reader that follows the log also finds the one that was deleted."}
```

A program that follows the log turns the database into a stream of changes: insert this ride, update
that one, delete the other. That is **change data capture**, usually shortened to CDC. Each change
arrives seconds after it happened, and nothing reads the rides table at all, so the app does not feel
it.

## A log you can watch

SQLite keeps its own log too, but not one meant to be followed by another program. A trigger can
stand in for it: a few lines of SQL that the database runs on every insert, update and delete,
writing a row to a table of changes. This program installs three, one per kind of change:

```python
# sources/triggers.py
import sqlite3

db = sqlite3.connect("app.db")
db.executescript("""
DROP TABLE IF EXISTS changes;
CREATE TABLE changes (seq INTEGER PRIMARY KEY, op TEXT, ride_id TEXT, status TEXT);
CREATE TRIGGER on_insert AFTER INSERT ON rides BEGIN
    INSERT INTO changes (op, ride_id, status) VALUES ('insert', NEW.ride_id, NEW.status);
END;
CREATE TRIGGER on_update AFTER UPDATE ON rides BEGIN
    INSERT INTO changes (op, ride_id, status) VALUES ('update', NEW.ride_id, NEW.status);
END;
CREATE TRIGGER on_delete AFTER DELETE ON rides BEGIN
    INSERT INTO changes (op, ride_id, status) VALUES ('delete', OLD.ride_id, OLD.status);
END;
""")
print("every change to rides is now written to changes as well")
```

And this one reads the changes in order:

```python
# sources/changes.py
import sqlite3

db = sqlite3.connect("app.db")
for seq, op, ride_id, status in db.execute("SELECT * FROM changes ORDER BY seq"):
    print(seq, op, ride_id, status)
```

Start the app again from 09:00, install the triggers, let the same quarter of an hour happen, and read
what was recorded. `app.py` and `later.py` are the programs from the previous section, unchanged:

```
ana@lab:~/roda/sources$ python app.py
app.db holds 4 rides
ana@lab:~/roda/sources$ python triggers.py
every change to rides is now written to changes as well
ana@lab:~/roda/sources$ python later.py
one ride finished, one started, one cancelled and deleted
ana@lab:~/roda/sources$ python changes.py
1 update R000103 finished
2 insert R000105 open
3 delete R000104 open
```

The cancelled ride is there, as change number 3, with the status it had when it was deleted. A reader
that applies these three entries to its copy, in order, ends with the same four rides as the app.

Triggers are a real way of doing CDC, and an old one, but they have a price the log does not. Every
trigger is an extra write inside the app's own transaction, so the app pays for the data team's copy
on every ride it starts. **Reading the log costs the app far less, because the database writes the log
anyway.** That is why log-based CDC is the usual choice where the database offers it.

## What it asks of the database's owners

At Roda Livre the tool for this would be something like Debezium, an open-source program that reads
the logs of PostgreSQL, MySQL and several other databases and publishes each change as a message.
This course names it and goes no further; reading a log in production is the work of `pipelines-etl`.
Three things are worth knowing before anybody proposes it, because each one is a conversation with
the app team:

- **It needs permission to read the log**, which is a privilege the database's owners grant, close to
  the one a replica has.
- **The database keeps the log until the reader has taken it.** In PostgreSQL, a CDC reader that
  stops for a weekend leaves the log growing on the primary's disk until it comes back. A copy that
  breaks is the data team's problem; this one can become the app's.
- **The log only starts now.** It holds recent changes, not the history of every row, so a CDC
  pipeline begins with one full copy and follows the log from the moment that copy was taken.

What comes out is a stream: changes arriving one at a time, for as long as the app runs. Lesson 8 is
about processing data that never finishes arriving.
