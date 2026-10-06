---
title: Changing the database without stopping
version: 1
---

Code can be swapped in a second. Data cannot. A release that changes the shape of the database meets
a hard fact of continuous delivery: **for a while, the old code and the new code run against the same
database**, during the deploy, during a canary in lesson 10, and after a rollback in lesson 11. A
migration that only the new code understands breaks the old code during that while.

## A change in one step, and why it breaks

Suppose `shipquote` renames the `cents` column of the quotes table to `price_cents`, in the same
release as the code that uses the new name. The moment the migration runs, every process still on the
old release fails on every query that names `cents`. And if the release must be rolled back, the old
code comes back to a column that no longer exists. **The rollback is broken by the migration**, which
lesson 11 calls the part of a release that cannot be undone.

## Expand, then contract

The safe pattern splits one incompatible change into several compatible ones, each a release of its
own:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Five releases, each a column, with the state of the old column cents and the new column price_cents. 1 expand: cents read and written, price_cents added. 2 write both: cents read and written, price_cents written. 3 backfill: same, old rows copied. 4 read the new: cents written, price_cents read and written. 5 contract: cents dropped, price_cents read and written.\"><text x=\"80\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1. expand</text><rect x=\"20\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"80\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"80\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read and written</text><rect x=\"20\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"80\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"80\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">added, unused</text><text x=\"220\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2. write both</text><rect x=\"160\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"220\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"220\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read and written</text><rect x=\"160\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"220\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"220\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3. backfill</text><rect x=\"300\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"360\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"360\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read and written</text><rect x=\"300\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"360\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"360\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written</text><text x=\"500\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4. read the new</text><rect x=\"440\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"500\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"500\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written</text><rect x=\"440\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"500\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"500\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read and written</text><text x=\"640\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">5. contract</text><rect x=\"580\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"640\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dropped</text><rect x=\"580\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"640\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"640\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read and written</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">any two neighbouring releases can run side by side, so each step can be rolled back</text></svg>", "caption": "Renaming a column as five compatible releases. The price is time; what it buys is that no step depends on every server changing at once."}
```

1. **Expand.** Add the new column, `price_cents`, next to the old one. Old code ignores it; nothing
   breaks.
2. **Write both.** Release code that writes `cents` and `price_cents` and still reads `cents`. Old and
   new releases can now run side by side.
3. **Backfill.** Copy the old values into the new column for the rows written before step 2.
4. **Read the new.** Release code that reads `price_cents`. Rolling back to step 2's code is still
   safe, because both columns are kept up to date.
5. **Contract.** Once no running release reads `cents`, stop writing it, and in a later release drop
   it.

It is more releases and more patience. In exchange, **every step can be deployed and rolled back on
its own**, at any time of day, which is the property everything else in this course depends on.

## In the pipeline

A migration is part of the release, so it goes through the pipeline like code: it runs in staging
first, against data shaped like production, and its smoke test includes a query on the changed table.
The repository that publishes this course runs its migrations as a separate job **before** moving the
service to the new revision, and waits for it to finish, so a migration that fails stops the release
before any new code serves a request.
