---
title: Sensitivity labels and lineage
version: 1
---

**This section is taught from Microsoft's documentation and was not run.**

## A label says how to treat the data, not what it is

**A classification describes content; a sensitivity label states a policy.** "This column holds CPF
numbers" is a classification. "Confidential: personal data" is a label, and it means something to
people and to other tools: who may see it, whether it may leave the company, how it is shown. The
labels are defined once for the whole organisation, in the Microsoft 365 side of Purview of the first
section, where they already mark documents and e-mails.

**The Data Map can apply those same labels to the assets it scanned, from their classifications**:
a rule says that a column classified as a CPF gets "Confidential: personal data", and every table with
such a column carries the label in the catalogue. The documentation makes this an option the
organisation has to turn on, and it depends on the organisation's Microsoft 365 licences, which is the
point where the two families of the first section meet and where a data team usually finds it needs
somebody from the Microsoft 365 side to agree. The label in the catalogue is information for whoever
searches it; whether a query of that column is then refused or masked is decided by the store itself,
by its permissions and its masking features, not by the label.

## Lineage: who copied what into where

**Lineage is the record of where an asset's data came from**: this Delta table was written by that
notebook from those Avro files, which Capture wrote from that event hub. It answers the second half of
the question this lesson opened with, "who copied it there", and it answers the question an engineer
asks before changing anything, "what breaks downstream if I drop this column".

**Purview does not discover lineage by reading the data. The tools that move the data report it.**
Data Factory and Synapse pipelines, once the factory or workspace is connected to the Purview account,
report what each copy activity and data flow read and wrote, as Microsoft documents; so does Power BI
for its datasets and reports. A scan contributes what it can see from a source's own definitions, such
as a database view built on tables. Each report adds edges to the map, and the picture is a graph from
sources to reports.

**A program of your own reports nothing.** The course's `classify.py`, a Python script on a virtual
machine, a notebook that writes a file: their outputs appear in the map as assets with no parent, and
the lineage graph has a gap exactly where a hand-written step sits. Quitanda's pipeline has several such
steps in this course, the programs of lessons 20, 23 and 24 among them, and each one is a place where "where did this come from" has to be answered
from memory. The practical rule is that **lineage is only as complete as the share of data movement
that goes through tools that report it**, and a team that cares about lineage moves data through those
tools, or adds the missing edges itself through Purview's programming interface.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A lineage graph. The event hub clicks leads to Capture&#x27;s Avro files, an edge reported by Capture; the Avro files lead to a Delta table of clicks, an edge reported by a Data Factory copy activity; the Delta table leads to a Power BI report, an edge reported by Power BI. Below, customers.csv, written by a script, stands alone with no incoming edge, because nothing reported where it came from.\" data-fig=\"l25-lineage\"><rect x=\"20\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">event hub clicks</text><rect x=\"200\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Capture's Avro files</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Delta table of clicks</text><rect x=\"560\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Power BI report</text><line x1=\"162\" y1=\"70\" x2=\"192.0\" y2=\"70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"198,70 192.0,73.0 192.0,67.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">Capture</text><line x1=\"342\" y1=\"70\" x2=\"372.0\" y2=\"70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"378,70 372.0,73.0 372.0,67.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"360.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">Data Factory copy</text><line x1=\"522\" y1=\"70\" x2=\"552.0\" y2=\"70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"558,70 552.0,73.0 552.0,67.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"540.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">Power BI</text><rect x=\"380\" y=\"140\" width=\"140\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customers.csv</text><text x=\"450\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">written by a script</text><text x=\"368\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no parent: nothing reported it</text></svg>", "caption": "Lineage is the edges the tools report; a step written by hand leaves an asset with no parent."}
```
