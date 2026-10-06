---
title: What a table format adds
version: 1
---

An **open table format** keeps the data as ordinary Parquet files and adds one thing beside them: a
**transaction log**, a list of commits in order, each one saying which files it added to the table and which
it removed. A reader does not list the folder. It reads the log, works out which files make up the latest
version, and reads those.

That one addition answers most of the previous section:

- **Atomic commits.** A writer writes its data files first, where no reader is looking for them, and then
  adds one entry to the log. Until the entry exists, the new files are not part of the table; after it
  exists, all of them are. A job that dies halfway leaves files nobody reads, not a partial table.
- **Updates and deletes.** A change rewrites the affected files and commits "remove these, add those".
  Readers see the old table or the new one, never a mixture.
- **Schema enforcement.** The log records the table's schema, and a writer whose data does not match is
  refused before it commits.
- **History.** Old commits stay in the log and old files stay on disk until somebody cleans them up, so any
  earlier version can be read again. This is called **time travel**.
- **Statistics.** Each entry for an added file carries its row count and each column's minimum and maximum,
  so a reader can skip files without opening them: lesson 8's zone maps, one level up.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"On the right, a folder of Parquet data files: three of them, one crossed out because a later commit removed it. On the left, the transaction log: commit 0 adds the 2024 file, commit 1 adds the 2025 file, commit 2 removes the old 2024 file and adds a corrected one. A reader reads the log, not the folder, and the current table is the two files the log still lists.\"><defs><marker id=\"ah-table-format\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">_delta_log: the table</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">data files: ordinary Parquet</text><rect x=\"30\" y=\"45\" width=\"240\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00000.json</text><text x=\"45\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">add 2024 (a)</text><rect x=\"30\" y=\"107\" width=\"240\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00001.json</text><text x=\"45\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">add 2025 (b)</text><rect x=\"30\" y=\"169\" width=\"240\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00002.json</text><text x=\"45\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">remove a, add c</text><rect x=\"430\" y=\"45\" width=\"220\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">a: 2024.parquet</text><line x1=\"445\" y1=\"69\" x2=\"635\" y2=\"69\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"430\" y=\"107\" width=\"220\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b: 2025.parquet</text><rect x=\"430\" y=\"169\" width=\"220\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c: 2024.parquet</text><line x1=\"270\" y1=\"69\" x2=\"430\" y2=\"69\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-table-format)\"></line><line x1=\"270\" y1=\"131\" x2=\"430\" y2=\"131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-table-format)\"></line><line x1=\"270\" y1=\"193\" x2=\"430\" y2=\"193\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-table-format)\"></line><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a reader replays the log: the current table is b and c</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a stays on disk until a vacuum, so version 1 can still be read</text></svg>", "caption": "A table format: the log says which files make up each version."}
```

Three formats implement the idea, and they are more alike than different: **Delta Lake**, from Databricks;
**Apache Iceberg**, from Netflix; and **Apache Hudi**, from Uber. Ana's lab has the Python library
`deltalake`, delta-rs, so the next four sections are Delta; section 11 says where the other two differ.

A lake whose important tables are in one of these formats is what is now called a **lakehouse**: the lake's
open files and cheap storage, with the warehouse's transactions, schema and history.
