---
title: Extraneous fetching
version: 1
---

The catalogue list shows fifty products, each with a name and a price. Written with `SELECT *`, the
query also brings back each product's description, which the list never shows:

```
ana@vm:~/lab/perf$ $P catalogue-star
catalogue-star: 1 queries, 50 rows, 1,000,775 bytes, 33 ms
ana@vm:~/lab/perf$ $P catalogue-columns
catalogue-columns: 1 queries, 50 rows, 775 bytes, 4 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two bars for the same catalogue list of fifty products. SELECT star returns about one million bytes, almost all of it descriptions the list never shows. Selecting id, name and price returns 775 bytes, a bar too short to see beside the other.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">SELECT *</text><rect x=\"200\" y=\"36\" width=\"480\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1,000,775 bytes</text><text x=\"30\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">id, name, cents</text><rect x=\"200\" y=\"96\" width=\"4\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"214\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">775 bytes</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same fifty names and prices on the screen</text></svg>", "caption": "Extraneous fetching: the page shows the same thing either way; one query moves a thousand times as much data to show it."}
```

**A million bytes against 775**, for the same fifty names and prices on the screen, and 33 milliseconds
against 4. The database read the descriptions from disk, the network carried them, the driver turned
them into Python strings, and the page threw them away. On the lab's machine that is 29 milliseconds; in
production it is also bandwidth billed between zones, memory in every application instance, and a
database cache full of descriptions nobody asked for.

`SELECT *` is the common form. The others are worth knowing by sight:

| the habit | what it moves for nothing |
| --- | --- |
| `SELECT *` on a table with a large column | the large column |
| fetching every row and filtering in the application | every row that is then discarded |
| fetching all rows of a list nobody pages through | everything beyond the first page; use `LIMIT` and keyset pagination |
| an API that returns the whole object for every use | fields the caller ignores; lesson 3 of the `apis` course is about this problem |
| loading a whole aggregate to change one field | the aggregate |

The fix is always to ask for what the screen uses. It is also why some teams forbid `SELECT *` in
application code outright: a column added to the table next year, a large one, would silently join
every query that used it.
