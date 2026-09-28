---
title: A pattern for the line
version: 1
---

Most good project lines have the same three parts, and it helps to write them separately first:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"One CV line in three parts. Did: built and deployed a loan register for a school IT room. Which: so a second loan of the same item is refused by the database. Shown by: a test that fails when the rule is removed, and a service that survives a crash. Below, in smaller type, the technologies: Python, SQLite, Podman, Caddy.\"><defs><marker id=\"bu04-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">did</text><text x=\"130\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Built and deployed a loan register for a school IT room</text><rect x=\"20\" y=\"70\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">which</text><text x=\"130\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">so a second loan of the same item is refused by the database</text><rect x=\"20\" y=\"120\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">shown by</text><text x=\"130\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a test that fails when the rule is removed; survives a crash</text><text x=\"130\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Python · SQLite · Podman · Caddy</text></svg>", "caption": "What was done, what it achieves, and how anybody can check. The technology is the smallest line, because it is the one every other CV has too."}
```

1. **Did**: a past-tense verb and the thing, with whom it was for. *Built and deployed a loan register for a
   school IT room.* *Documented and rebuilt a small-office network in a lab.*
2. **Which**: what is true now that was not. *So a second loan is refused.* *So a colleague can rebuild it
   from the runbook alone.*
3. **Shown by**: the evidence anybody can check. *A test that fails when the rule is removed.* *A restore
   that was tested.* *Deployed at an address.*

Then join them into one or two lines and cut every word that does not carry one of the three.

The same pattern works for experience outside IT. *Served customers at a phone shop* becomes *Handled about
thirty customer problems a day at a phone shop, most of them solved on the first call*, **if that is true**,
which is the next section.

Three verbs to avoid at the start of a line: *helped*, *participated* and *was responsible for*. They
hide what you did. If you did part of something, say which part.
