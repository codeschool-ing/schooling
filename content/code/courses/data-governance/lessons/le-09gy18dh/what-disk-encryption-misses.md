---
title: Where disk encryption ends
version: 1
---

Volume encryption ends at the operating system. The moment PostgreSQL reads a block, it reads
plaintext; every query, every replica, every export and every backup taken through the database
gets plaintext too. The quickest way to see it is the backup:

```
ana@lab:~/gov$ sudo -u postgres pg_dump -d ipe -t sales.customers | grep -m 1 "paula.cavalcanti"
1	Paula Cavalcanti Silva	paula.cavalcanti@example.com	372.874.168-09	1998-03-27	F	01589-076	São Paulo	SP	2025-01-07 12:04:18-03	t	2025-01-07 20:54:32-03
```

`pg_dump` is how most PostgreSQL backups are made, and it produced Paula's row in clear — name,
e-mail, CPF, date of birth — **on a machine whose disk could have been fully encrypted**. The dump
is a new file, outside the encrypted volume, and it goes wherever backups go: another server, an
object store, a laptop for a restore test. It typically lives longer than the database it came
from and is read by fewer controls.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l3-where-it-ends\" aria-label=\"The database in the middle, on an encrypted volume. Arrows leave it to four copies that are plaintext unless encrypted separately: a pg_dump backup, a replica, a CSV export for another team, and the server log. Only the copies inside the volume boundary are covered by the volume's encryption.\"><defs><marker id=\"dg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"250.0\" y=\"60.0\" width=\"220.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">encrypted volume</text><rect x=\"285.0\" y=\"100.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"360.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ipe</text><rect x=\"20.0\" y=\"30.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pg_dump backup</text><text x=\"100.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plaintext</text><rect x=\"20.0\" y=\"170.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a replica</text><text x=\"100.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plaintext</text><rect x=\"540.0\" y=\"30.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a CSV export</text><text x=\"620.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plaintext</text><rect x=\"540.0\" y=\"170.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the server log</text><text x=\"620.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plaintext</text><path d=\"M285.0 115.0 L182.0 64.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><path d=\"M285.0 155.0 L182.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><path d=\"M435.0 115.0 L538.0 64.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><path d=\"M435.0 155.0 L538.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path></svg>", "caption": "An encrypted disk covers one copy. Every copy made through the database starts in clear."}
```

So the inventory of plaintext copies is longer than the inventory of databases:

- **backups and dumps**, which need encrypting as files, with a key that is not stored beside
  them — lesson 4 does it with a key from a key-management service;
- **replicas**, which need the same volume encryption and the same TLS as the primary;
- **exports**: the CSV a pipeline writes for another team, the spreadsheet an analyst saves,
  the result set of a BI tool's cache;
- **logs**, which can carry values, as the next section shows;
- **temporary files**, which PostgreSQL writes when a sort does not fit in memory, inside the
  data directory and therefore on the encrypted volume — the one item on this list the volume
  does cover.

None of these is a reason not to encrypt the disk. Each is a reason not to stop there, and to
treat "encrypted at rest" as a claim about one copy, which has to be repeated for every other.

## And the people inside

The threat the volume does nothing about is the one with a login. A role with `SELECT` on a
column reads it in clear, encrypted disk or not; so does a superuser, and so does anybody who can
read the server's memory or its log files. Lessons 1 and 2 were about narrowing who has `SELECT`.
The next section asks what it would take for even the database itself to hold a column it cannot
read.
