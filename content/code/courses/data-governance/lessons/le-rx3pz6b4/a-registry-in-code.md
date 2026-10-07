---
title: The same idea, in this platform
version: 1
---

The platform you are reading this on keeps its own classification, and it is worth looking at
because it is the same design as the last section, with one more step. It lives in the platform's
repository, in a package called `privacy`, and every table of the platform's database has an entry
in a list called `Registry`. The classes are declared first:

```go
// Holding is what a table has in it. Three values and no more — a fourth would
// be a judgement call, and a judgement call is what this is here to remove.
type Holding string

const (
	// Nothing about a person.
	HoldsNothing Holding = "none"
	// Identifiers and no name: meaningless once the identity rows are gone.
	HoldsPseudonymous Holding = "pseudonymous"
	// A name, an address, an e-mail — a person without being joined to anything.
	HoldsIdentifying Holding = "identifying"
)
```

Three values, and a comment saying why there are not four. Each table then gets one entry, with what
it holds, whose data it is, what happens to it when a person asks to be erased, and why:

```go
	{
		Name: "accounts", Holds: HoldsIdentifying, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the e-mail and the name. It is the row that makes every account_id in the database " +
			"mean a person, so deleting it is what the whole erase path is for",
	},
```

**And a test compares the list with the live schema.** `TestEveryTableInTheDatabaseIsClassified`
reads every table from `information_schema.tables` and fails if one is missing from the registry, or
if the registry names a table that no longer exists. A migration that adds a table without an entry
cannot be merged — the same property as Ipê's `unclassified.sql`, enforced by the build instead of a
pipeline step.

## The step beyond Ipê's version

The platform's registry does one more thing, and it is the reason this design exists: **the export
and the erasure of a person's data are built from it.** Every entry says whether erasing a person
deletes the rows (`EraseDelete`), leaves them pointing at nobody (`EraseOrphan`) or keeps them on
purpose (`EraseKeep`) — and the code that answers a data subject's request walks the registry rather
than a list somebody keeps by hand. Adding a table means deciding, in the same change, what a
person's request does to it.

Lesson 7 builds the beginning of that for Ipê — an export of everything about one customer — and
the classification table from the last section is what tells it where to look.

*The two excerpts are quoted from the platform's source as this course was written; the file
changes as the platform does.*
