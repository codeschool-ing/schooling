---
title: Expand, migrate, contract
version: 1
---

Some changes cannot be made instant: a rename, a split of one column into two, a new required
column, a change of type. And there is a second problem the lock does not explain: **during a
deploy, old and new versions of the program run at the same time.** A rolling deploy replaces the
copies of lesson 1 one at a time, so for a few minutes some copies read the schema the old way and
some the new way. A rename that happens in one step breaks whichever version did not expect it.

The answer is to never make a change that one of the running versions cannot live with. Every
breaking change is split into **steps that are each safe on their own**, in this order:

1. **Expand.** Add the new thing alongside the old one: a new column, nullable or with a constant
   default, or a new table. Instant, and invisible to the program already running.
2. **Write both.** Deploy a version of the program that writes the new column as well as the old
   one, and still reads the old one.
3. **Backfill.** Fill the new column for the rows written before step 2, in small batches, as
   section 08 does.
4. **Read the new one.** Deploy a version that reads the new column. The old column is now only
   written, never read.
5. **Contract.** Deploy a version that stops writing the old column, and, once no running version
   mentions it, drop it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Five steps across three deploys for renaming a column. Expand: add the new column. Deploy 1: write both columns, read the old. Backfill old rows. Deploy 2: read the new column. Deploy 3: stop writing the old column, then drop it. Under each step, which versions of the program run, and that every one of them works with the schema at that moment.\"><path d=\"M30 130 L690 130\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"130\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"30\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">expand</text><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">add new column</text><circle cx=\"225\" cy=\"130\" r=\"7\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"165\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deploy 1</text><text x=\"225\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">write both</text><circle cx=\"360\" cy=\"130\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"300\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">backfill</text><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">old rows</text><circle cx=\"495\" cy=\"130\" r=\"7\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"435\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deploy 2</text><text x=\"495\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read new</text><circle cx=\"630\" cy=\"130\" r=\"7\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"570\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">contract</text><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deploy 3, then drop</text><path d=\"M90 160 L250 160\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"82\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><path d=\"M225 180 L520 180\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"217\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v2</text><path d=\"M495 200 L655 200\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"487\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v3</text><path d=\"M630 220 L690 220\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"622\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v4</text><text x=\"690\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">program versions running</text></svg>", "caption": "Expand, migrate, contract: every step is safe for every version running at that moment."}
```

Five steps and three deploys for what one `ALTER TABLE … RENAME` would have done, and each step can
be stopped or reversed without losing anything. **The cost is time and care; the saving is that no
step ever needs the system to stop.**

## The column this lesson adds

The box office is about to record which gate each ticket was scanned at, a new column `gate`. It is
a smaller case than a rename, and it uses three of the steps:

- **expand**: `ADD COLUMN gate text`, which section 03 already ran, nullable;
- **new rows get a value**: in a real deploy, the next version of the program writes `gate` on every
  sale. Here a default, `SET DEFAULT 'A'`, stands in for that version, which is also instant;
- **backfill** the two million old rows, section 08;
- and then make the column **required**, section 09, without a scan under the strongest lock.

The contract step does not arise, because nothing is being replaced. In a rename it is the step
people skip, and an old column that every version writes and none reads is the usual result.
