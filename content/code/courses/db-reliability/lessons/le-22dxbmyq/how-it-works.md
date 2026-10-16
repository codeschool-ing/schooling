---
title: A restore that never stops
version: 1
---

Lesson 8 ended where restores run out of road: when the promise is minutes, no restore, however
rehearsed, fits inside it. What fits is a server that is **already restored** and is kept current
second by second, so that taking over is a matter of telling it to stop following. That server is a
**standby**, and keeping it current is **streaming replication**.

The mechanism is the one this course has used since lesson 4, made continuous. A standby is a base
backup that never finishes recovering: instead of fetching archived segments and stopping at a
target, it connects to the primary and receives the write-ahead log **as it is written**, and replays
it, for as long as it runs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two servers. On the primary, a commit is written to pg_wal and a WAL sender sends the new log at once. On the standby, a WAL receiver writes and flushes it to the standby's own pg_wal, and the startup process replays it into the data files, where queries on the standby can see it. The four steps are numbered.\"><defs><marker id=\"l11s-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"l11s-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">primary</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 commit, written to pg_wal</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 WAL sender</text><path d=\"M150 100 L150 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11s-pa)\"></path><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby</text><rect x=\"460\" y=\"60\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 WAL receiver:</text><text x=\"570\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">write, then flush</text><rect x=\"460\" y=\"130\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 replay into the data</text><text x=\"570\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">queries see it here</text><path d=\"M570 106 L570 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11s-pa)\"></path><path d=\"M282 150 L360 150 L360 83 L438 83\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11s-am)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the log, as it is written</text></svg>", "caption": "Streaming replication in four steps. Each one can fall behind the one before it, and the primary's view of the standby reports a position for each."}
```

Four steps for every change, each a point where the standby can fall behind, and each with its own
column in the view the next sections read:

1. The primary writes the change to its own log, and commits.
2. A **WAL sender** process on the primary sends the new log to the standby as soon as it exists.
3. A **WAL receiver** on the standby **writes** it to the standby's own `pg_wal`, then **flushes** it
   to disk.
4. The standby's startup process **replays** it into the data files, and only then can a query on
   the standby see it.

The standby is **read-only**: it applies the primary's history and makes none of its own. It can
answer queries (in PostgreSQL that is called a **hot standby**), and it can be **promoted** into a
primary in seconds, which lesson 15 does.

## What a standby is not

A standby is a copy of the database **as it is now**, not as it was. Lesson 8 put it plainly: a
`DELETE` with the wrong `WHERE` reaches the standby a fraction of a second after the primary, and
then both have lost the rows. **Replication protects against losing a server; backups protect against
losing data.** A setup with a standby and no backups has the second half of this course and not the
first.
