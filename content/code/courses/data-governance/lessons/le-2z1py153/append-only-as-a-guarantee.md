---
title: Append-only, as a guarantee
version: 1
---

The platform you are studying on keeps an audit log of every administrative action, an event stream
and a practice log, and all three are **append-only**. Its schema says why in a comment worth
quoting: append-only as an arrangement is a comment; append-only as a trigger is a guarantee. The
function it uses:

```sql
-- Raising rather than returning NULL: a BEFORE trigger that returns NULL
-- silently discards the row, and "the delete did nothing and said nothing" is
-- the failure mode this is here to prevent, not a milder version of it.
CREATE FUNCTION refuse_to_change_history() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION
        '% is append-only: % is refused. A correction is a new row, never an edit to an old one.',
        TG_TABLE_NAME, TG_OP
        USING ERRCODE = 'restrict_violation';
END;
$$;
```

Two details are the same as the lab's, for the same reasons. It **raises** rather than returning
`NULL` — a `BEFORE` trigger that returns `NULL` silently discards the operation, and "the delete did
nothing and said nothing" is the failure this exists to prevent. And it gives the reason in the
message: **a correction is a new row**, never an edit to an old one.

## The hole, and how it was found

The platform's first version had the row trigger and not the `TRUNCATE` one. A later migration
explains how that was found:

```sql
-- POSTGRES DOES NOT FIRE ROW TRIGGERS ON `TRUNCATE`. It is a separate event,
-- with its own trigger kind, and a statement that empties an append-only table
-- entirely was therefore the one edit the guard allowed. The strongest possible
-- change to history went through the gap left for the weakest.
--
-- It was found while writing `cmd/reset`, which needed to empty exactly these
-- tables — and could have done so without the schema noticing. A tool that gets
-- its way by walking through a hole in a guarantee teaches the next reader that
-- the guarantee is decorative.
```

It was found while writing a tool to empty the development database, which needed to clear exactly
those tables — and could have done it without the schema noticing. The fix was the statement-level
trigger the lab's audit log has. The tool now **disables the trigger by name**, inside its
transaction, in code anybody can read: emptying history is legitimate exactly once, before there are
any users, and doing it through a gap would be the same act with nothing written down.

## What to take from it

- **every append-only table gets both triggers.** One per row for `UPDATE` and `DELETE`, one per
  statement for `TRUNCATE`;
- **a correction is a new row** that points at what it corrects — the ledger of the platform does
  exactly this for refunds;
- **the way around a guarantee is written down.** When something legitimately has to bypass it, it does
  so by name, in reviewed code, and leaves a record — never by finding the hole.
