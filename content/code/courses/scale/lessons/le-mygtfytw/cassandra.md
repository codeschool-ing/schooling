---
title: Cassandra, the scans at the door
version: 1
---

Cassandra is the wide-column store of lesson 4, and the table of that lesson's section 07 is the one
created here. A Cassandra cluster is usually several machines, each owning stretches of a hash ring;
the lab runs a single node, which is enough to see the data model and the ring's numbers, and not
enough to see replication.

The file, saved as `scans.cql`: a **keyspace**, Cassandra's name for a database, which also sets how
many copies of each row to keep; the table; and six scans, five of show 1 and one of show 7:

```
-- scans.cql
CREATE KEYSPACE IF NOT EXISTS tickets
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS tickets.scans (
  show_id    text,
  scanned_at timestamp,
  ticket     text,
  gate       text,
  PRIMARY KEY ((show_id), scanned_at, ticket)
) WITH CLUSTERING ORDER BY (scanned_at DESC);

INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:03:51-0300', 'T-128', 'A');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:03:58-0300', 'T-121', 'B');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:04:02-0300', 'T-114', 'A');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:04:07-0300', 'T-107', 'B');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:04:09-0300', 'T-100', 'A');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-7', '2026-11-15 20:31:12-0300', 'T-900', 'A');
```

`replication_factor: 1` keeps one copy, which is all one node can hold; a real cluster uses 3. The
timestamps carry São Paulo's offset, `-0300`.

## Starting it

Cassandra takes about a minute to start, and it refuses connections until it has. The second
command below waits for it, asking every five seconds:

```
ana@lab:~/tickets$ docker run -d --name cassandra --memory 1536m -e MAX_HEAP_SIZE=512M -e HEAP_NEWSIZE=128M cassandra:5.0.9
7651c264e50cfc586a767c877f0f1942df1c6850d72e358329fa36f5c11a62d3
ana@lab:~/tickets$ until docker exec cassandra cqlsh -e 'DESCRIBE KEYSPACES' >/dev/null 2>&1; do sleep 5; done
ana@lab:~/tickets$ docker cp scans.cql cassandra:/tmp/scans.cql
ana@lab:~/tickets$ docker exec cassandra cqlsh -f /tmp/scans.cql
ana@lab:~/tickets$ docker exec cassandra cqlsh -e "SELECT scanned_at, ticket, gate FROM tickets.scans WHERE show_id = 'show-1' LIMIT 3"

 scanned_at                      | ticket | gate
---------------------------------+--------+------
 2026-11-16 00:04:09.000000+0000 |  T-100 |    A
 2026-11-16 00:04:07.000000+0000 |  T-107 |    B
 2026-11-16 00:04:02.000000+0000 |  T-114 |    A

(3 rows)
```

`MAX_HEAP_SIZE` and `HEAP_NEWSIZE` bound the Java heap, and `--memory` bounds the container; without
them Cassandra sizes itself from the machine and takes far more. `cqlsh`, the shell, runs the file,
which prints nothing when it succeeds.

The query names one partition, `show_id = 'show-1'`, and Cassandra returns its rows **already in
the clustering order**, newest first, stopping after three: one read, from one node, no sort. The
times are printed in UTC, so 21:04 in São Paulo appears as 00:04 the next day.

## Where the partitions live

Cassandra places each partition on its ring by hashing the partition key into a **token**, a number
between −2⁶³ and 2⁶³ − 1. The ring of lesson 2's section 11, at its real size:

```
ana@lab:~/tickets$ docker exec cassandra cqlsh -e 'SELECT show_id, token(show_id) FROM tickets.scans PER PARTITION LIMIT 1'

 show_id | system.token(show_id)
---------+-----------------------
  show-7 |  -9054864109681963144
  show-1 |   5471948530961257742

(2 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"The token range of Cassandra drawn as a line from minus two to the sixty-third to two to the sixty-third. Show 7's token, about minus 9.05 times ten to the eighteenth, is near the left end; show 1's, about 5.47 times ten to the eighteenth, is in the right half.\"><path d=\"M60 80 L660 80\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"60\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">−2⁶³</text><text x=\"660\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2⁶³−1</text><text x=\"360\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M360 74 L360 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"65.5\" cy=\"80\" r=\"7\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"65.5\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show-7</text><text x=\"65.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">-9.05e18</text><circle cx=\"538.0\" cy=\"80\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"538.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1</text><text x=\"538.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5.47e18</text></svg>", "caption": "Each partition key hashed to a token. A node owns stretches of this line, closed into a ring."}
```

Show 7's token is near the bottom of the range and show 1's in the upper half. In a cluster of
three nodes each owning many stretches of the ring, these two would very likely live on different
machines, and adding a fourth node would move only the stretches it takes over.
