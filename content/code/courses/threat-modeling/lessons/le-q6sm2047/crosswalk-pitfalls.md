---
title: Where crosswalks go wrong
version: 1
---

A crosswalk is a mapping between frameworks: this ISO control is that CSF outcome is that SOC 2
criterion. They are useful and they are everywhere, and each one is somebody's opinion written as a
table. Five ways they mislead, all of which Vereda's file is built to avoid.

### 1. Mapped is not implemented

The commonest failure. A spreadsheet with a reference in every row looks finished, and a reader takes
"8.7 → C6" to mean that Vereda protects against malware in exam files. It does not: C6 was not
bought. **The `plan` column is in `mapping.csv` for exactly this reason**, and `crosswalk.py` prints
"(not bought)" beside C6 wherever it appears. A mapping that cannot show status will be read as a
claim that everything is in place.

### 2. Many to many, flattened

C1 answers 8.5 and PR.AA-03. C7 answers 5.17, 8.5 and PR.AA-03. 8.5 is answered by C1 and C7.
Real mappings are many to many, and a crosswalk printed as one column against another forces one
reference per row. Then somebody reads that 8.5 is "C1", decides it is covered, and never asks about
C7's phase 2.

### 3. One framework's control is bigger than yours

8.5, secure authentication, is about the whole of how a system authenticates: methods, protection of
credentials, responses to failure, session limits. C1 is one part of that. Saying that C1 "maps to"
8.5 is true; saying that 8.5 is "done" because C1 exists is not. **A mapping says where a control is
filed, not that the file is complete.** The statement of applicability, with its "partly", is where
completeness is argued.

### 4. The edition moved

ISO 27001 was revised in 2022, and every reference changed:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l13-drift\" aria-label=\"Four controls renumbered between the 2013 and 2022 editions of ISO 27001 Annex A. A.9.4.2, secure log-on procedures, became 8.5, secure authentication. A.9.2.3, management of privileged access rights, became 8.2. A.13.1.3, segregation in networks, became 8.22. A.18.1.4, privacy and protection of PII, became 5.34.\"><defs><marker id=\"l13-drift-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"185.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">ISO 27001:2013</text><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ISO 27001:2022</text><rect x=\"20.0\" y=\"40.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.9.4.2</text><text x=\"108.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">secure log-on procedures</text><rect x=\"390.0\" y=\"40.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8.5</text><text x=\"450.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">secure authentication</text><path d=\"M350.0 58.0 L390.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"88.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.9.2.3</text><text x=\"108.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">management of privileged access rights</text><rect x=\"390.0\" y=\"88.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8.2</text><text x=\"450.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">privileged access rights</text><path d=\"M350.0 106.0 L390.0 106.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"136.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.13.1.3</text><text x=\"108.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segregation in networks</text><rect x=\"390.0\" y=\"136.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8.22</text><text x=\"450.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">segregation of networks</text><path d=\"M350.0 154.0 L390.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"184.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.18.1.4</text><text x=\"108.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">privacy and protection of PII</text><rect x=\"390.0\" y=\"184.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5.34</text><text x=\"450.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">privacy and protection of PII</text><path d=\"M350.0 202.0 L390.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a mapping kept as numbers ages with the edition it was written against</text></svg>", "caption": "The control is the same and its number is not. A mapping that names the edition it used can be translated; one that does not is silently wrong."}
```

A mapping written in 2020 against the 2013 edition is not wrong about the controls; it is wrong about
their numbers, and a reader with the 2022 edition finds A.9.4.2 nowhere. Mappings that do not name
their edition fail like this silently. Official crosswalks exist for some pairs, and NIST publishes
its framework's references to other documents through its OLIR programme, but **an official
crosswalk is also an opinion**, written for general use, and each one names the edition it used.

### 5. The framework becomes the model

The last and most expensive. A team handed a questionnaire with 60 questions starts answering them,
and after a while the 60 questions are the threat model. Threats nobody numbered are not looked
for: no framework knew that Vereda's reminder worker logged in as the database owner, and T13 was
found by drawing the DFD, not by reading Annex A.

**The direction of a mapping is the protection.** Vereda's file maps outward, from threats to
controls to references. A team that maps inward, from references to whatever controls can be found
for them, has a perfect crosswalk and no idea what could go wrong in its own system.
