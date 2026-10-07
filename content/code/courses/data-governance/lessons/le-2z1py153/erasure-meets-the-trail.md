---
title: When erasure meets an append-only trail
version: 1
---

Two obligations of this course appear to collide. Lesson 7: a person may ask for their data to be
deleted. This lesson: the audit trail must never be changed. If the trail holds personal data about
customer 112, and customer 112 asks for erasure, one of the two promises has to break.

It does not, if the trail is designed for it — and the lab's already is.

## Identifiers, not values

`gov.audit_log` records `row_key = 112` and `columns = {cep,city}`. It does not record the old
address or the new one. On its own, `112` means nothing; it is personal data only because
`sales.customers` says who 112 is. When that row loses its name and contact details — lesson 7's
erasure — the trail still says that somebody connected as ana changed two columns of customer 112,
and nobody can say any more who customer 112 was.

The platform you are studying on is built on exactly this. Its event stream and its practice log
hold identifiers, never names. Erasing a person deletes the rows that give those identifiers a
meaning, which leaves the history pointing at nobody: **the statistics survive and the person is not in
them**. It is also why those tables have no foreign key to the accounts table — a key with `ON DELETE
SET NULL` would try to update an append-only row, and the two obligations really would collide.

## The rule that makes it work

**An append-only table may hold identifiers and may not hold what they identify.** Every column that
would carry a name, an e-mail, a free-text value or a copy of a changed field turns an immutable table
into one that can never honour an erasure. The check is the same as lesson 6's classification: the
trail's columns are classed, and anything above `personal` in an append-only table is a design
mistake to fix before it ships.

## And the trail has a retention period too

The audit log is personal data — who did what — and lives under the same rule as everything else:
kept as long as needed, and no longer. Five years is a common choice for administrative records. It
belongs in `gov.retention`, and purging it is the one case where rows leave an append-only table:
by a named, reviewed job that disables the guard for that statement and logs that it did — the same
pattern as the platform's reset tool.
