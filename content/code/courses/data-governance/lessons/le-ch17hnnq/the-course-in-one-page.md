---
title: The course, in one page
version: 1
---

Eleven lessons built one company's governance from nothing. It is worth seeing it in one place,
because each piece leans on the others:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l11-map\" aria-label=\"The course as layers. At the bottom, access: who may connect and who may read what, lessons 1 and 2. Above it, protection: encryption, keys and pseudonyms, lessons 3 to 5. Above that, knowledge: what is held and how sensitive it is, lesson 6. Then the law, lessons 7 and 8. Then governance: owners, quality, lineage, retention and audit, lessons 9 and 10. At the top, contracts with others, lesson 11. Every layer keeps its decisions as data and checks them.\"><rect x=\"110.0\" y=\"18.0\" width=\"340.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">contracts with others</text><text x=\"560.0\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lesson 11</text><rect x=\"94.0\" y=\"62.0\" width=\"372.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">owners, quality, lineage, retention, audit</text><text x=\"560.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lessons 9 and 10</text><rect x=\"78.0\" y=\"106.0\" width=\"404.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the law: LGPD, GDPR, AI Act</text><text x=\"560.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lessons 7 and 8</text><rect x=\"62.0\" y=\"150.0\" width=\"436.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what we hold, and how sensitive</text><text x=\"560.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lesson 6</text><rect x=\"46.0\" y=\"194.0\" width=\"468.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">encryption, keys, pseudonyms</text><text x=\"560.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lessons 3 to 5</text><rect x=\"30.0\" y=\"238.0\" width=\"500.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">who may connect, who may read</text><text x=\"560.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lessons 1 and 2</text></svg>", "caption": "Each layer leans on the ones below it."}
```

| lesson | what Ipê now has | the question it answers |
|---|---|---|
| 1 | roles per person, `pg_hba.conf` read top to bottom, nobody by default | who may connect, and as whom? |
| 2 | job roles, row and column security | who may read what? |
| 3 | TLS checked, encryption at rest, its limits | who could read it on the way, or from the disk? |
| 4 | keys in OpenBao, envelope encryption, an audit device | who holds the keys, and who used them? |
| 5 | tokens, masks, a keyed hash, k-anonymity | what can be used without the identity? |
| 6 | `gov.column_class`, minimisation, synthetic test data | what do we hold, and how sensitive is it? |
| 7 | consent events, the request log, the export, the RIPD | what does the law ask, and can we prove it? |
| 8 | two breach clocks, an AI inventory | what changes across a border, and with AI? |
| 9 | owners, quality rules that run, a dictionary, lineage | who answers for it, and is it any good? |
| 10 | a retention schedule, a purge, holds, an append-only trail | how long, and who did what? |
| 11 | a contract, checked | what did we promise to whom? |

## What the pieces have in common

Every one of them is **a decision kept where a machine can read it**: a role, a policy, a row in a
governance table, a constraint, a trigger, a contract in a repository. And nearly every one comes with
**a check that fails** when reality and the decision disagree: the unclassified columns, the unowned
tables, the quality rules, the overdue rows, the contract.

That is the whole method. Laws change — lesson 8's dates will — and so do tools, companies and
people. A team that keeps its decisions as data, and checks them on every change, can answer a new law
with a query and a migration. A team that keeps them in people's heads answers it with a project.
