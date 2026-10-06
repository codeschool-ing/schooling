---
title: Three schools of warehouse design
version: 1
---

Where to normalise and where not to also divides the field into schools, and you will meet all three
in job descriptions and design reviews.

**Inmon: normalise the warehouse, denormalise the marts.** Bill Inmon's warehouse, the *corporate
information factory*, is one integrated, normalised database, close to third normal form, holding the
whole enterprise's history. Departments do not query it directly; they get **data marts** built from it,
and the marts are dimensional. The normalised core is the single source of truth, and it is designed to
survive any change in what the business asks.

**Kimball: dimensional all the way, held together by conformed dimensions.** Ralph Kimball's warehouse
is the collection of stars, one per business process, sharing conformed dimensions through the bus
matrix. There is no normalised layer in between that reports cannot read. What lessons 2 to 5 built is
Kimball's design.

**Data Vault: normalise further, for history and auditing.** Dan Linstedt's Data Vault splits
everything into three kinds of table, keeps every version of everything with the load that brought it,
and leaves the shaping for reports to a later layer, which is usually Kimball stars. The next section
builds a fragment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three columns, one per school, each drawn as layers from the sources at the bottom to what people query at the top. Inmon: sources, then a normalised enterprise warehouse, then dimensional marts. Kimball: sources, then stars sharing conformed dimensions, which people query directly. Data Vault: sources, then hubs, links and satellites, then dimensional marts built from the vault. All three end in dimensional tables.\"><defs><marker id=\"ah-three-schools\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"125\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Inmon</text><rect x=\"20\" y=\"45\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dimensional marts</text><line x1=\"125\" y1=\"118\" x2=\"125\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"20\" y=\"120\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">normalised warehouse (3NF)</text><line x1=\"125\" y1=\"193\" x2=\"125\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"20\" y=\"195\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">source systems</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Kimball</text><rect x=\"255\" y=\"45\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stars, read directly</text><line x1=\"360\" y1=\"118\" x2=\"360\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"255\" y=\"120\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conformed dimensions</text><line x1=\"360\" y1=\"193\" x2=\"360\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"255\" y=\"195\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">source systems</text><text x=\"595\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Data Vault</text><rect x=\"490\" y=\"45\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dimensional marts</text><line x1=\"595\" y1=\"118\" x2=\"595\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"490\" y=\"120\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hubs, links, satellites</text><line x1=\"595\" y1=\"193\" x2=\"595\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"490\" y=\"195\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">source systems</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">people query the top layer; the schools differ in what sits under it</text></svg>", "caption": "Inmon, Kimball and Data Vault: where the normalised layer sits, and what people read."}
```

They disagree about **where the normalised layer sits and who reads it**, and they agree about more than
the arguments suggest. All three end in dimensional tables for people to query. All three keep history.
The differences are about what sits underneath:

| | Inmon | Kimball | Data Vault |
|---|---|---|---|
| the integrated core | normalised, close to 3NF | conformed stars | hubs, links and satellites |
| what people query | dimensional marts built from the core | the stars directly | marts built from the vault |
| strongest when | many sources, a stable enterprise model wanted first | delivering useful answers quickly, process by process | sources change often; full audit trail required |
| main cost | a large model to build before the first report | conforming dimensions takes discipline across teams | many more tables, and a second layer to build |

**For Ana, at Ponto Final, Kimball is the obvious fit**: one source system, a few business processes,
and a manager who wants answers this quarter. A bank with forty source systems and auditors asking which
load wrote which number might sensibly choose differently.
