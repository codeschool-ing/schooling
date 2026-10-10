---
title: Wide column, rows sorted inside a partition
version: 1
---

The name **wide column** is misleading, because the useful idea is not the width. A table in this
family has a **partition key**, which decides which server holds a row, as in lesson 2's sharding,
and a **clustering key**, which keeps the rows inside a partition **sorted on disk**. A query names
one partition and reads a slice of it in order, from one server, without sorting anything.

The third access pattern of section 03 is the classic fit: tickets scanned at the door, thousands
a minute on a show night, read back per show in time order. The table is designed around that read:

```
CREATE TABLE scans (
  show_id    text,
  scanned_at timestamp,
  ticket     text,
  gate       text,
  PRIMARY KEY ((show_id), scanned_at, ticket)
) WITH CLUSTERING ORDER BY (scanned_at DESC);
```

The double parentheses mark the partition key, `show_id`; what follows, `scanned_at` and `ticket`,
is the clustering key. Every scan of show 1 is in one partition, newest first, so "the last 50
scans of show 1" is one read from one server that stops after 50 rows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three servers. The partition key show_id decides the server: show 1 on the first, show 2 on the second, show 3 on the third. Inside show 1's partition, the scans are stored sorted by time, newest first, and a query for the last three reads the top of that list.\"><rect x=\"20\" y=\"20\" width=\"210\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">server 1</text><text x=\"125\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show_id = 1</text><rect x=\"40\" y=\"74\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">21:04:09  T-100</text><rect x=\"40\" y=\"101\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">21:04:07  T-107</text><rect x=\"40\" y=\"128\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">21:04:02  T-114</text><rect x=\"40\" y=\"155\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:58  T-121</text><rect x=\"40\" y=\"182\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:51  T-128</text><rect x=\"255\" y=\"20\" width=\"210\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">server 2</text><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show_id = 2</text><rect x=\"275\" y=\"74\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:09  T-101</text><rect x=\"275\" y=\"101\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:07  T-108</text><rect x=\"275\" y=\"128\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:02  T-115</text><rect x=\"275\" y=\"155\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:58  T-122</text><rect x=\"275\" y=\"182\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:51  T-129</text><rect x=\"490\" y=\"20\" width=\"210\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">server 3</text><text x=\"595\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show_id = 3</text><rect x=\"510\" y=\"74\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:09  T-102</text><rect x=\"510\" y=\"101\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:07  T-109</text><rect x=\"510\" y=\"128\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:04:02  T-116</text><rect x=\"510\" y=\"155\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:58  T-123</text><rect x=\"510\" y=\"182\" width=\"170\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21:03:51  T-130</text><text x=\"125\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">LIMIT 3: the top of one partition</text></svg>", "caption": "The partition key picks the server; the clustering key keeps the rows in order inside it."}
```

## Why it writes fast

A scan is an append. Stores in this family, Cassandra being the best known, write to an in-memory
table and a commit log, and flush to disk in large sorted files that are never modified, only
merged in the background. **No write reads anything first**, so writes stay fast as the data grows,
and a cluster of many servers absorbs a flood of them. It is designed for the opposite of the
box office's sale: many writes, few kinds of read.

## What it asks of you

- **One table per query.** "Every scan at gate B tonight" is not answered by this table, because
  `gate` is not in the key, and the store refuses a query that would read every partition unless
  told explicitly to allow it. The answer is a second table, `scans_by_gate`, written alongside.
- **Partitions of a bounded size.** A partition lives on one server. Every scan of a show in one
  partition is fine; every scan of every show ever, under a key like `'all'`, makes one server hold
  everything, which is lesson 2's hot shard again.
- **The consistency of lesson 3, chosen per query.** Cassandra lets each read and write name its
  quorum: `ONE`, `QUORUM`, `ALL`. The arithmetic of W + R > N is how to read those words.

Lesson 5 creates this table in Cassandra and runs the query.
