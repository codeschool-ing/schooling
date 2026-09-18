---
title: SQLite is not a server
version: 1
---

The common picture of SQLite is "the small one" — a database for toys, to be swapped for a real
one when the project grows up. That picture is wrong twice, and replacing it is the point of this
section.

It is not a smaller version of the other three. It is **a different kind of thing**, and the
difference is not size. PostgreSQL, MySQL and MariaDB are programs that run on their own,
listening on a socket; your application connects to one and sends it statements. SQLite is a
library your program links against, and the "connection" is a function call inside your own
process. The database is a file.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two arrangements side by side. On the left, labelled a server, three separate application boxes each hold a driver, and an arrow from each crosses a dashed vertical boundary marked socket into one box for the database server, which is its own process; an arrow points down from the server to a box marked data files. A note says many writers at once and that the server serialises them. On the right, labelled a library, there is one application box with the SQLite library drawn inside it, no boundary crossed, and an arrow straight down from it to one box marked shop.db. A note says one writer at a time, a function call rather than a socket, with nothing to start and nothing to connect to.\"><text x=\"14\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a server: PostgreSQL, MySQL, MariaDB</text>\n<rect x=\"14\" y=\"44\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"69\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 1</text>\n<text x=\"69\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">driver</text>\n<rect x=\"14\" y=\"100\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"69\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 2</text>\n<text x=\"69\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">driver</text>\n<rect x=\"14\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"69\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 3</text>\n<text x=\"69\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">driver</text>\n<line x1=\"210\" y1=\"34\" x2=\"210\" y2=\"248\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line>\n<text x=\"210\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a socket, and a process boundary</text>\n<path d=\"M124 64 L190 64 L190 100 L250 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M240 94 L250 100 L240 106\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M124 120 L250 120\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M240 114 L250 120 L240 126\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M124 176 L190 176 L190 140 L250 140\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M240 134 L250 140 L240 146\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<rect x=\"250\" y=\"88\" width=\"130\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n<text x=\"315\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">the server</text>\n<text x=\"315\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own process</text>\n<path d=\"M315 153 L315 190\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M309 180 L315 190 L321 180\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<rect x=\"250\" y=\"190\" width=\"130\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"315\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">data files</text>\n<text x=\"14\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">many writers at once;</text>\n<text x=\"14\" y=\"240\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the server serialises them</text>\n<line x1=\"410\" y1=\"12\" x2=\"410\" y2=\"288\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"436\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">a library: SQLite</text>\n<rect x=\"436\" y=\"60\" width=\"254\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"563\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 1</text>\n<rect x=\"466\" y=\"100\" width=\"194\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect>\n<text x=\"563\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the SQLite library</text>\n<path d=\"M563 153 L563 190\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M557 180 L563 190 L569 180\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<rect x=\"498\" y=\"190\" width=\"130\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"563\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop.db</text>\n<text x=\"436\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one writer at a time; a function call,</text>\n<text x=\"436\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">not a socket. Nothing to start,</text>\n<text x=\"436\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing to connect to.</text></svg>", "caption": "The structural difference, and everything else in this section follows from it. On the left a statement crosses a process boundary; on the right it does not cross anything."}
```

## What that buys

**Nothing to run.** No daemon, no port, no user, no password, no configuration file. The database
is `shop.db` and opening it is opening a file. A test suite creates one per test and deletes it;
lesson 11's migration tooling has nothing to wait for.

**No network in the path.** Reading a row is a function call and a page read, not a round trip.
For a single-process application that reads a lot, SQLite is routinely faster than a server on the
same machine, because the fastest network call is the one that does not happen.

**One file to move.** Backup is `cp`. Shipping a read-only dataset with your application is
shipping a file. This is why it is inside every phone.

**It is fully relational and fully transactional.** Foreign keys, `CHECK`, window functions,
CTEs, `BEGIN`/`COMMIT`, crash recovery. Lesson 8's guarantees hold; it is not a key-value store
with SQL painted on.

## What that costs, and it is one thing

**One writer at a time, for the whole file.** Not one per table, not one per row — one per
database. Here is what a second writer meets while the first still has a transaction open:

```
sqlite> UPDATE products SET price = 199.00 WHERE sku = 'MS-204';
Error: stepping, database is locked (5)
```

Readers are not blocked by that writer, and they see the committed value rather than the
uncommitted one:

```
sqlite> SELECT sku, price FROM products WHERE sku = 'KB-101';
sku     price
------  -----
KB-101  349.9
```

The usual mitigation is **write-ahead logging**, which is one statement and is worth turning on
every time:

```
sqlite> PRAGMA journal_mode;
journal_mode
------------
delete      
sqlite> PRAGMA journal_mode = WAL;
journal_mode
------------
wal         
sqlite> PRAGMA journal_mode;
journal_mode
------------
wal         
```

Setting it prints the mode it ended in, which is the answer and not an echo: the switch can fail,
and a `PRAGMA` that came back `delete` is a switch that did not happen.

In WAL mode readers and the single writer proceed together, which removes most of the contention
people meet. It does not remove the limit: there is still **one** writer. A busy timeout — the
driver waits rather than failing immediately — turns "database is locked" into a queue, and a
queue is fine until the arrival rate passes what one writer can drain.

The second cost follows from the first and is usually the decisive one: **the file has to be on
the machine the code runs on.** Three application servers behind a load balancer cannot share a
SQLite file. A network filesystem is explicitly not supported either: SQLite's locking depends on
file locks that NFS and friends implement unreliably. The moment the answer to "where
does this run" is "on several machines", SQLite is out, and no amount of tuning changes it.

## So where it belongs

| it fits | because |
|---|---|
| a desktop or mobile application | one process, local file, no server to install |
| a test suite | create, use, delete, in milliseconds |
| a command-line tool with state | the state is a file the user can copy |
| an embedded or edge device | there is nowhere to run a server |
| a read-heavy site on one machine | reads do not contend, and there is no round trip |
| shipping a dataset | the dataset is the database |

| it does not fit | because |
|---|---|
| several machines writing | one file, local locks |
| a write-heavy workload | one writer, whatever the hardware |
| many concurrent clients you do not control | connections are your own process's, not a server's |
| anything needing users and permissions | there are none; file permissions are the whole model |

The honest summary is that the question is not *how big is the data*. SQLite handles a database
larger than most companies have. The question is **how many processes write to it**, and the
answer that rules it out is "more than one machine".
