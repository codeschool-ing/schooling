---
title: Documents, everything about one thing together
version: 1
---

A **document store** keeps each record as a document, usually JSON or a binary form of it, under a
key. Unlike a key-value store it looks inside: it can index a field, filter on it and return part of
a document. Unlike a relational table, documents in one collection need not share a shape, and a
document holds nested lists and objects rather than pointing at other tables for them.

The second access pattern of section 03, the page of a show, is the case it was made for. In the
box office's tables that page is a join across shows, venues, artists and prices. As a document it
is one read:

```json
{
  "_id": "show-1",
  "name": "Sabiá Festival, Sunday",
  "starts_at": "2026-11-15T18:00:00-03:00",
  "venue": { "name": "Arena Sul", "city": "São Paulo", "capacity": 12000 },
  "artists": ["Banda Ipê", "Marta Lins"],
  "prices": [
    { "section": "floor", "cents": 18000 },
    { "section": "upper", "cents": 9000 }
  ]
}
```

The venue is **embedded**: its name and city are copied into every show at that venue, so the page
needs nothing else. That is the document family's central decision, made per relation.

## Embed or reference

| embed the related data when | keep a reference, an id, when |
|---|---|
| it is read with the parent almost every time | it is read on its own, or by many parents |
| it is small and bounded: a few prices, a few artists | it grows without limit: every ticket of the show |
| it changes rarely, or a stale copy is acceptable | it changes often and every copy must follow |

The tickets of a show fail all three tests for embedding: there can be twelve thousand of them, they
are read one at a time, and they change constantly. Embedded, every sale would rewrite a document
that grows by a ticket each time. So tickets are documents of their own, each carrying the show's
id, which is a **reference**: the same thing as a foreign key, without a database that checks it.

**The cost of embedding is the update.** When Arena Sul changes its name, every show document at
that venue holds the old one, and the program has to find and rewrite them all. A relational
database had that fact in one row. This is the trade of denormalisation in its plainest form:
**cheaper reads, paid for with harder writes**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two show documents both embed a copy of the venue Arena Sul. When the venue is renamed, both copies have to be found and rewritten. Beside them, ticket documents are kept apart, each holding only a reference to its show's id.\"><rect x=\"20\" y=\"20\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1</text><rect x=\"36\" y=\"56\" width=\"188\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">venue: Arena Sul</text><text x=\"130\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a copy</text><rect x=\"20\" y=\"130\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-7</text><rect x=\"36\" y=\"166\" width=\"188\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">venue: Arena Sul</text><text x=\"130\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a copy</text><text x=\"130\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">rename the venue: rewrite both</text><rect x=\"440\" y=\"40\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket-101</text><text x=\"520\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">show: &quot;show-1&quot;</text><path d=\"M440 62 L240 65\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"440\" y=\"100\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket-102</text><text x=\"520\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">show: &quot;show-1&quot;</text><path d=\"M440 122 L240 65\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"440\" y=\"160\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket-103</text><text x=\"520\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">show: &quot;show-1&quot;</text><path d=\"M440 182 L240 65\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"520\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tickets: references, kept apart</text></svg>", "caption": "Embedded: read in one go, updated everywhere. Referenced: kept once, joined by the program."}
```

## What a document store gives and withholds

- **Atomic writes to one document**, including its nested parts. Changing a show's prices and its
  date together is one write.
- **Indexes on fields**, nested ones included, so "every show in São Paulo next week" is a query
  and not a scan.
- **Weaker or costlier multi-document transactions.** MongoDB has offered them since version 4.0,
  and they cost more than single-document writes; a design that needs them on every request has
  usually chosen the wrong documents.
- **No joins in the usual sense.** Assembling data from several collections is either a pipeline
  stage, slower than a relational join, or two queries in the program.

MongoDB is the family's best-known member, and lesson 5 runs it. PostgreSQL's `jsonb` columns give
a relational database much of the same model inside a table, which is often enough.
