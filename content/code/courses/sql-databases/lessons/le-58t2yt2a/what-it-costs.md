---
title: What every index costs, on every write
version: 1
---

The sentence people learn is *"an index makes queries faster"*. The sentence they do not learn is
the other half:

> **Every index is maintained on every insert, every update that touches its columns, and every
> delete — for as long as it exists.**

A table with six indexes turns one `INSERT` into seven pieces of work: the row, and six sorted
structures that each need a new entry put in the right place. Nobody sees that in a query plan,
because it is not a query.

## The three costs

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"One INSERT on the left, with seven arrows fanning out to the right: the row itself, highlighted, and six indexes — on email, status, created_at, customer_id, total, and a composite on status and total. A note beside them reads seven pieces of work, not one, and that none of it appears in a query plan because it is not a query.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">An index is a second structure, kept in step inside the same transaction as the row.</text><rect x=\"14\" y=\"48\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"65\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">INSERT</text><text x=\"74\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">one statement</text><path d=\"M140 65 L234 55\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M234 55 L228 51 L228 59 Z\" fill=\"var(--phosphor)\"></path><rect x=\"238\" y=\"44\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the row</text><path d=\"M140 65 L234 81\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M234 81 L228 77 L228 85 Z\" fill=\"var(--wire)\"></path><rect x=\"238\" y=\"70\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"248\" y=\"81\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">idx (email)</text><path d=\"M140 65 L234 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M234 107 L228 103 L228 111 Z\" fill=\"var(--wire)\"></path><rect x=\"238\" y=\"96\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"248\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">idx (status)</text><path d=\"M140 65 L234 133\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M234 133 L228 129 L228 137 Z\" fill=\"var(--wire)\"></path><rect x=\"238\" y=\"122\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"248\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">idx (created_at)</text><path d=\"M140 65 L234 159\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M234 159 L228 155 L228 163 Z\" fill=\"var(--wire)\"></path><rect x=\"238\" y=\"148\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"248\" y=\"159\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">idx (customer_id)</text><path d=\"M140 65 L234 185\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M234 185 L228 181 L228 189 Z\" fill=\"var(--wire)\"></path><rect x=\"238\" y=\"174\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"248\" y=\"185\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">idx (total)</text><path d=\"M140 65 L234 211\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M234 211 L228 207 L228 215 Z\" fill=\"var(--wire)\"></path><rect x=\"238\" y=\"200\" width=\"200\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"248\" y=\"211\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">idx (status, total)</text><text x=\"452\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">seven pieces of work, not one</text><text x=\"452\" y=\"126\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and none of it appears in a query plan,</text><text x=\"452\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">because it is not a query</text><text x=\"14\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">It is per index and per row, and it adds up in exactly the tables that matter — the ones with the most traffic.</text></svg>", "caption": "Six indexes are not six small conveniences. They are six structures that every write has to keep true, for as long as they exist."}
```

**Writes.** Each index adds work to every write. It is not catastrophic — a B-tree insert is a few
block reads and a write — but it is per index and per row, and it adds up in exactly the tables
that matter, which are the ones with the most traffic.

**Disk.** An index on a `text` column can easily be a third of the size of the table. Six of them
can be larger than the table. That is disk, and it is memory: the working set your database keeps
in cache now includes every index, so an index nobody uses is evicting pages somebody does.

**The planner's time and its choices.** More indexes mean more plans to consider. Worse, an index
that is nearly right invites the planner to choose it and then follow half a million pointers, when
reading the table would have been faster.

## An update is worse than it looks

```sql
UPDATE customers SET last_seen = now() WHERE id = 7;
```

Only one column changed, so only an index on `last_seen` should need work. In PostgreSQL that is
often not what happens: an update writes a **new version of the whole row** somewhere else, so
every index has to be given an entry pointing at the new location. There is an optimisation for
this — a heap-only tuple update, which skips the index work when no indexed column changed and
there is room on the same page — and it is a best-effort thing rather than a guarantee.

Which gives a specific and useful piece of advice: **a column written on every request, like
`last_seen`, is an expensive column to index**, and the cost lands on the writes rather than
anywhere you would look.

## Sometimes reading everything is right

An index is not automatically better. Two cases where a scan wins, and they are common:

**A small table.** A few hundred rows fit in a page or two. Reading them all is one or two reads;
using an index is a read of the index plus a read of the table. The planner knows this and reads
the table, and it is correct.

**A query that matches a lot of rows.** Suppose `WHERE active` matches 60% of a million rows. Using
the index means six hundred thousand index entries and six hundred thousand random fetches, each
landing on a page that is probably not where the last one landed. Reading the table straight
through is sequential, which storage is much better at, and it is the faster plan by a wide margin.

The rule of thumb varies by engine and by how the rows are laid out, and the shape is always the
same: **an index pays when it eliminates most of the table, and stops paying when it does not.** A
column with two possible values — a boolean, a status with `active` and `inactive` — is the classic
case where an ordinary index earns nothing, and the section on partial indexes is what you want
instead.

## The ones that are pure loss

**An index nobody queries.** Added for a report that was deleted, or for a `WHERE` somebody was
planning to write. It costs writes and disk and returns nothing, and it will sit there for years
because removing it feels risky. The `maintaining-them` section has the query that finds them.

**A duplicate.** An index on `(customer_id)` beside one on `(customer_id, created_at)` is redundant:
the second serves every query the first does, for the reason the `composite-indexes` section gives.
People create both because two different tickets asked for two different queries.

**One that duplicates a constraint.** A `PRIMARY KEY` or a `UNIQUE` constraint is implemented as an
index. Adding your own index on the same column gives you two structures doing one job.

## The rule

> **Do not add an index because it seems likely to help. Add it because you measured, and remove it
> when the measurement no longer holds.**

Every index is a small permanent tax on writes, paid in exchange for a specific query being fast.
That is a good trade when the query is real and a bad one when it is hypothetical, and the only way
to tell them apart is to look — which is the whole of lesson 10.
