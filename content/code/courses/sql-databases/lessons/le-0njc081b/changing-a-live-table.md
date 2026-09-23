---
title: Changing a table nobody can stop using
version: 2
---

This is the section that separates somebody who knows SQL from somebody who can be trusted with a
database, and it is almost never taught.

The situation: `invoices` has eighty million rows, the application reads and writes it constantly,
and `status` needs to become `NOT NULL`. The one-liner is:

```sql
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
```

It takes an `ACCESS EXCLUSIVE` lock and scans eighty million rows. Everything stops for a minute
or two. Run that at ten in the morning and you have caused an outage with a correct statement.

## The general shape of the answer

Every safe schema change on a live table has the same structure:

> **Make the change in steps, each of which is fast, and each of which leaves the system working —
> for both the old code and the new.**

That last clause is the one people miss. During a deploy there are two versions of the application
running at once, for seconds or for minutes. Every intermediate state has to be one that both can
live with.

## Making a column `NOT NULL` without the scan

The trick is that PostgreSQL will trust a `CHECK` constraint it has already validated.

```sql
-- 1. add the rule, NOT VALID: instant, no scan, applies to new rows only
ALTER TABLE invoices
    ADD CONSTRAINT invoices_status_present CHECK (status IS NOT NULL) NOT VALID;

-- 2. backfill the existing nulls, in batches, at your own pace
UPDATE invoices SET status = 'draft' WHERE status IS NULL AND id BETWEEN 1 AND 100000;
-- … repeat

-- 3. validate: scans, but takes only a SHARE UPDATE EXCLUSIVE lock,
--    so reads and writes continue
ALTER TABLE invoices VALIDATE CONSTRAINT invoices_status_present;

-- 4. now SET NOT NULL is instant, because the proof already exists
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
ALTER TABLE invoices DROP CONSTRAINT invoices_status_present;
```

Four statements instead of one, and at no point is the table locked for more than a moment.

**`NOT VALID` is the key idea and it generalises.** It means *"apply this rule from now on, and do
not check what is already here"* — which is exactly what you want, because new rows are the ones
you can control, and the old ones you will fix at your own speed. Foreign keys take it too:

```sql
ALTER TABLE invoices ADD CONSTRAINT invoices_customer_fk
    FOREIGN KEY (customer_id) REFERENCES customers (id) NOT VALID;
ALTER TABLE invoices VALIDATE CONSTRAINT invoices_customer_fk;
```

## Renaming a column, which cannot be done in one step at all

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"Four stages left to right: before, expand, move and contract. Each shows what the application writes and what it reads. Before: writes notes, reads notes. Expand: writes notes and remarks, still reads notes. Move: writes both, now reads remarks. Contract: writes remarks only and reads remarks. Notes read that between any two stages both the old and the new code work, and that a plain RENAME COLUMN is instant and breaks every running copy that still selects the old name.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Renaming a column takes three deploys, because at every moment some copy of the old application is still running.</text><rect x=\"14\" y=\"44\" width=\"160\" height=\"132\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"94.0\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">before</text><text x=\"28\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the app writes</text><text x=\"28\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notes</text><text x=\"28\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and reads</text><text x=\"28\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">notes</text><path d=\"M176 110 L188 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M188 110 L182 106 L182 114 Z\" fill=\"var(--wire)\"></path><rect x=\"190\" y=\"44\" width=\"160\" height=\"132\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">1 · expand</text><text x=\"204\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the app writes</text><text x=\"204\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notes</text><text x=\"204\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remarks</text><text x=\"204\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and reads</text><text x=\"204\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">notes</text><path d=\"M352 110 L364 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M364 110 L358 106 L358 114 Z\" fill=\"var(--wire)\"></path><rect x=\"366\" y=\"44\" width=\"160\" height=\"132\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"446.0\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">2 · move</text><text x=\"380\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the app writes</text><text x=\"380\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notes</text><text x=\"380\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remarks</text><text x=\"380\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and reads</text><text x=\"380\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">remarks</text><path d=\"M528 110 L540 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M540 110 L534 106 L534 114 Z\" fill=\"var(--wire)\"></path><rect x=\"542\" y=\"44\" width=\"160\" height=\"132\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"622.0\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">3 · contract</text><text x=\"556\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the app writes</text><text x=\"556\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remarks</text><text x=\"556\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and reads</text><text x=\"556\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">remarks</text><text x=\"14\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Between any two columns above, both the old code and the new code work. That is what the middle step buys.</text><text x=\"14\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ALTER TABLE … RENAME COLUMN is instant and breaks every running copy that still selects the old name.</text></svg>", "caption": "The middle column is the one people skip, and it is the only one that makes the other two safe."}
```

```sql
ALTER TABLE invoices RENAME COLUMN notes TO remarks;
```

Instant, no lock worth the name, and it **breaks every running copy of the old application**, which
is still selecting `notes`. The statement is fast and the deploy is broken.

The safe shape is the expand-and-contract pattern, and it takes three deploys:

1. **Expand.** Add `remarks`. Change the application to write **both** columns and read `notes`.
   Deploy. Backfill `remarks` from `notes`.
2. **Move.** Change the application to read `remarks`, still writing both. Deploy. Now nothing
   depends on reading the old column.
3. **Contract.** Change the application to stop writing `notes`. Deploy. Then drop the column.

Slow, dull, and the only version that never has a moment where a running program is wrong. The
same shape covers changing a column's type, splitting one column into two, and moving a column to
another table.

## Adding an index without blocking writes

Lesson 9 is about which indexes to add. The mechanics belong here:

```sql
CREATE INDEX CONCURRENTLY invoices_customer_idx ON invoices (customer_id);
```

A plain `CREATE INDEX` blocks writes for as long as it takes. `CONCURRENTLY` does not — it takes
longer overall and lets the table carry on being written.

Two things about it that bite:

- **It cannot run inside a transaction**, so a migration tool that wraps everything in one has to
  be told to make an exception.
- **It can fail and leave an invalid index behind**, which is not used by queries and is not
  obvious. Check for it after any failure:

```sql
SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;
```

Drop and recreate any it finds.

## The checklist

Before any migration against a table that matters:

1. **Which of the three speeds is it?** Catalogue, scan, or rewrite.
2. **What lock does it take, and for how long?**
3. **Is there an intermediate state both the old and the new code can live with?** If not, it is
   three deploys, not one.
4. **Set `lock_timeout`.** So that a patient statement cannot queue the whole application behind
   it.
5. **Can it be undone?** `DROP COLUMN` cannot. Neither can `TRUNCATE`, once committed.

And the honest note about the last one: **a great many of these are answered for you by a
migration tool**, which is lesson 11. Tools know which operations are dangerous and refuse or
rewrite them. Knowing what they are protecting you from is what lets you read the warning and
decide, rather than adding the flag that turns it off.
